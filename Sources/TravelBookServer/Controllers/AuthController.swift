//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 07.01.2026.
//

import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.post("register", use: register)
        auth.post("login", use: login)
    }
    
    func register(_ req: Request) async throws -> UserDTO {
        try RegisterRequest.validate(content: req)
        
        let data = try req.content.decode(RegisterRequest.self)
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == data.email)
            .first()
        
        if existingUser != nil { throw Abort(.conflict, reason: "Пользователь уже существует") }
        
        let digest = try Bcrypt.hash(data.password)
        let user = User(email: data.email, username: data.username, passwordHash: digest)
        
        try await user.save(on: req.db)
        
        return user.toDTO()
    }
    
    func login(_ req: Request) async throws -> TokenDTO {
        let loginData = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\User.$email == loginData.email)
            .first()
        else { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }
        
        let isPasswordCorrect = try Bcrypt.verify(loginData.password, created: user.passwordHash)
        
        if !isPasswordCorrect { throw Abort(.unauthorized, reason: "Неверная почта или пароль") }
        
        let tokenValue = [UInt8].random(count: 16).base64
        let token = Token(value: tokenValue, userID: try user.requireID())
        try await token.save(on: req.db)
        
        return TokenDTO(token: tokenValue, user: user.toDTO())
    }
}

struct RegisterRequest: Content, Validatable {
    let email: String
    let username: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct TokenDTO: Content {
    let token: String
    let user: UserDTO
}

struct UserDTO: Content {
    let id: UUID?
    let email: String
    let username: String
}
