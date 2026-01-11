//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 06.01.2026.
//

import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users").delete() 
    }
}
