//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 06.01.2026.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Siblings(through: UserFavorite.self, from: \.$user, to: \.$cell)
    var favorites: [Cell]
    
    init() {}
    
    init(id: UUID? = nil, email: String, username: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.username = username
        self.passwordHash = passwordHash
    }
    
    func toDTO() -> UserDTO {
        .init(id: self.id, email: self.email, username: self.username)
    }
}
