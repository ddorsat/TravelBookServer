//
//  File.swift
//  TravelBookServer
//
//  Created by ddorsat on 05.01.2026.
//

import Vapor
import Fluent

final class Cell: Model, Content, @unchecked Sendable  {
    static let schema = "cells"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "category_id")
    var category: Category
    
    @Field(key: "image")
    var image: String
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "subtitle")
    var subtitle: String
    
    @Field(key: "date")
    var date: Date
    
    @Field(key: "reading_time")
    var readingTime: Int
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "images")
    var images: [String]
    
    @Siblings(through: UserFavorite.self, from: \.$cell, to: \.$user)
    var favoritedBy: [User]
    
    @Field(key: "is_popular")
    var isPopular: Bool
    
    @Field(key: "is_head_cell")
    var isHeadCell: Bool
    
    init() {}
    
    init(id: UUID? = nil,
         categoryID: Category.IDValue,
         image: String,
         title: String,
         subtitle: String,
         date: Date,
         readingTime: Int,
         description: String,
         images: [String],
         isPopular: Bool = false,
         isHeadCell: Bool = false) {
        self.id = id
        self.$category.id = categoryID
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.readingTime = readingTime
        self.description = description
        self.images = images
        self.isPopular = isPopular
        self.isHeadCell = isHeadCell
    }
}

struct CellDTO: Content {
    let id: UUID?
    let image: String
    let theme: String
    let title: String
    let subtitle: String
    let date: Date
    let readingTime: Int
    let description: String
    let images: [String]
    let isPopular: Bool
    let isHeadCell: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, image, theme, title, subtitle, date, description, images
        case readingTime = "reading_time"
        case isPopular = "is_popular"
        case isHeadCell = "is_head_cell"
    }
}
