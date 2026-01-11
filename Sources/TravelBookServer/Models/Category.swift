//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 06.01.2026.
//

import Vapor
import Fluent

final class Category: Model, Content, @unchecked Sendable {
    static let schema = "categories"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "theme")
    var theme: String
    
    @Field(key: "image")
    var image: String
    
    @Children(for: \.$category)
    var cells: [Cell]
    
    init() {}
    
    init(id: UUID? = nil, title: String, theme: String, image: String) {
        self.id = id
        self.title = title
        self.theme = theme
        self.image = image
    }
}
