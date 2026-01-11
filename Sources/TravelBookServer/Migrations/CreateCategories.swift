//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 06.01.2026.
//

import Fluent

struct CreateCategories: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("categories")
            .id()
            .field("title", .string, .required)
            .field("theme", .string, .required)
            .field("image", .string, .required)
            .unique(on: "theme")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("categories").delete()
    }
}
