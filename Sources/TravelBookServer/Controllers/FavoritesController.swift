//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 09.01.2026.
//

import Vapor
import Fluent

struct FavoritesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let favorites = routes.grouped("favorites")
            .grouped(UserAuthMiddleware())

        favorites.post(":cellID", use: addFavorite)
        favorites.delete(":cellID", use: removeFavorite)
        favorites.get(use: getFavorites)
    }

    func addFavorite(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let cellID = req.parameters.get("cellID", as: UUID.self) else { throw Abort(.badRequest) }
        guard let _ = try await Cell.find(cellID, on: req.db) else { throw Abort(.notFound, reason: "Cell not found") }
        
        let existing = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$cell.$id == cellID)
            .first()
            
        if existing != nil { return .ok }

        let pivot = UserFavorite(userID: try user.requireID(), cellID: cellID)
        
        try await pivot.save(on: req.db)
        
        return .created
    }

    func removeFavorite(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let cellID = req.parameters.get("cellID", as: UUID.self) else { throw Abort(.badRequest) }

        try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$cell.$id == cellID)
            .delete()

        return .ok
    }

    func getFavorites(_ req: Request) async throws -> [CellDTO] {
        let user = try req.auth.require(User.self)

        let favorites = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$cell) { $0.with(\.$category) }
            .sort(\.$createdAt, .ascending)
            .all()
        
        return favorites.map { fav in
            let cell = fav.cell
            return CellDTO(
                id: cell.id,
                image: cell.image,
                theme: cell.category.theme,
                title: cell.title,
                subtitle: cell.subtitle,
                date: cell.date,
                readingTime: cell.readingTime,
                description: cell.description,
                images: cell.images,
                isPopular: cell.isPopular,
                isHeadCell: cell.isHeadCell)
        }
    }
}

struct UserAuthMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let tokenString = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Токен не найден")
        }

        guard let tokenModel = try await Token.query(on: req.db)
            .filter(\.$value == tokenString)
            .with(\.$user)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверный токен") }

        req.auth.login(tokenModel.user)

        return try await next.respond(to: req)
    }
}
