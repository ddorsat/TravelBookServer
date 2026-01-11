//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 09.01.2026.
//

import Fluent

struct CreateUserFavorites: AsyncMigration {
    func prepare(on database: any FluentKit.Database) async throws {
        try await database.schema("user_favorites")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("cell_id", .uuid, .required, .references("cells", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "cell_id")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("user_favorites").delete()
    }
}
