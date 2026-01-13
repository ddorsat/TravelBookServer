import Vapor
import Fluent
import FluentSQL

func routes(_ app: Application) throws {
    let storageController = StorageController()
    
    app.get("cells") { req async throws -> [CellDTO] in
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 6
        let rawSeed = req.query[String.self, at: "seed"] ?? ""
        let safeSeed = rawSeed.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        
        let offset = (page - 1) * limit
        
        
        let cells = try await Cell.query(on: req.db)
            .with(\.$category)
            .sort(.sql(unsafeRaw: "md5(id::text || '\(safeSeed)')"))
            .range(offset..<(offset + limit))
            .all()
        
        return cells.map { $0.toDTO() }
    }
    
    app.get("popular") { req async throws -> [CellDTO] in
        let popularCells = try await Cell.query(on: req.db)
            .with(\.$category)
            .filter(\.$isPopular == true)
            .all()
            
        return popularCells.map { $0.toDTO() }
    }
    
    app.get("categories") { req async throws -> [Category] in
        let categories = try await Category.query(on: req.db).all()
        
        return categories.map { category in
            Category(id: category.id,
                     title: category.title,
                     theme: category.theme,
                     image: category.image)
        }
    }
    
    app.get("users") { req async throws -> [UserDTO] in
        let users = try await User.query(on: req.db).all()
        
        return users.map { user in
            UserDTO(id: user.id,
                    email: user.email,
                    username: user.username)
        }
    }
    
    app.get("search") { req async throws -> [CellDTO] in
        let searchTerm = req.query[String.self, at: "search"]
        let categoryTerm = req.query[String.self, at: "category"]
        
        let query = Cell.query(on: req.db).with(\.$category)
        
        if let search = searchTerm, !search.isEmpty {
            query.group(.or) { group in
                group.filter(\.$title, .custom("ILIKE"), "%\(search)%")
                group.filter(\.$subtitle, .custom("ILIKE"), "%\(search)%")
            }
        } else if let category = categoryTerm, !category.isEmpty {
            query.join(Category.self, on: \Cell.$category.$id == \Category.$id)
                .filter(Category.self, \.$theme == category)
        }
        
        let cells = try await query.all()
        
        return cells.map { $0.toDTO() }
    }
    
    app.post("api", "upload") { req in
        return try await storageController.uploadBulkImages(req)
    }
    
    app.get("clear") { req async throws -> String in
        if let sql = req.db as? (any SQLDatabase) {
            try await sql.raw("DELETE FROM cells;").run()
        }
        
        if let sql = req.db as? (any SQLDatabase) {
            try await sql.raw("DELETE FROM categories;").run()
        }
        
        if let sql = req.db as? (any SQLDatabase) {
            try await sql.raw("DELETE FROM users;").run()
        }
        
        if let sql = req.db as? (any SQLDatabase) {
            try await sql.raw("DELETE FROM tokens;").run()
        }
        
        return "База данных очищена"
    }
    
    try app.register(collection: AuthController())
    try app.register(collection: FavoritesController())
}

extension Cell {
    func toDTO() -> CellDTO {
        return CellDTO(id: self.id,
                       image: self.image,
                       theme: self.category.theme,
                       title: self.title,
                       subtitle: self.subtitle,
                       date: self.date,
                       readingTime: self.readingTime,
                       description: self.description,
                       images: self.images,
                       isPopular: self.isPopular,
                       isHeadCell: self.isHeadCell)
    }
}
