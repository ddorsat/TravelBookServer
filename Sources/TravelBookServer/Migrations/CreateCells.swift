//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 05.01.2026.
//

import Vapor
import Fluent
import FluentSQL

struct CreateCells: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("cells")
            .id()
            .field("category_id", .uuid, .required, .references("categories", "id"))
            .field("image", .string, .required)
            .field("title", .string, .required)
            .field("subtitle", .string, .required)
            .field("date", .datetime, .required)
            .field("reading_time", .int, .required)
            .field("description", .string, .required)
            .field("images", .array(of: .string), .required)
            .field("is_popular", .bool, .required, .sql(.default(false)))
            .field("is_head_cell", .bool, .required, .sql(.default(false)))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("cells").delete()
    }
}
