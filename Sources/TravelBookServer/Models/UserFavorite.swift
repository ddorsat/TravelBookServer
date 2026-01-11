//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 09.01.2026.
//

import Vapor
import Fluent

final class UserFavorite: Model, @unchecked Sendable {
    static let schema = "user_favorites"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "cell_id")
    var cell: Cell
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, userID: User.IDValue, cellID: Cell.IDValue) {
        self.id = id
        self.$user.id = userID
        self.$cell.id = cellID
    }
}
