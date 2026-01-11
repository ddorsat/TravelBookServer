import Vapor
import Fluent
import FluentSQL

func routes(_ app: Application) throws {
    app.get("cells") { req async throws -> [CellDTO] in
        let cells = try await Cell.query(on: req.db)
            .with(\.$category)
            .all()
        
        let shuffledCells = cells.shuffled()
        
        return shuffledCells.map { cell in
            CellDTO(id: cell.id,
                    image: cell.image,
                    theme: cell.category.theme,
                    title: cell.title,
                    subtitle: cell.subtitle,
                    date: cell.date,
                    readingTime: cell.readingTime,
                    description: cell.description,
                    images: cell.images)
        }
    }
    
    app.get("categories") { req async throws -> [Category] in
        let categories = try await Category.query(on: req.db)
            .all()
        
        return categories.map { category in
            Category(id: category.id,
                     title: category.title,
                     theme: category.theme,
                     image: category.image)
        }
    }
    
    app.get("users") { req async throws -> [UserDTO] in
        let users = try await User.query(on: req.db)
            .all()
        
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
        
        return cells.map { cell in
            CellDTO(id: cell.id,
                    image: cell.image,
                    theme: cell.category.theme,
                    title: cell.title,
                    subtitle: cell.subtitle,
                    date: cell.date,
                    readingTime: cell.readingTime,
                    description: cell.description,
                    images: cell.images)
        }
    }
    
    app.get("upload") { req async throws -> String in
        try await Cell.query(on: req.db).delete()
        try await Category.query(on: req.db).delete()
        
        let foodCategory = Category(title: "Еда", theme: "food", image: "food")
        let leisureCategory = Category(title: "Развлечения", theme: "leisure", image: "leisure")
        let fraudCategory = Category(title: "Безопасность", theme: "fraud", image: "fraud")
        let healthCategory = Category(title: "Здоровье", theme: "health", image: "health")
        let cultureCategory = Category(title: "Культура", theme: "culture", image: "culture")
        
        try await foodCategory.save(on: req.db)
        try await leisureCategory.save(on: req.db)
        try await fraudCategory.save(on: req.db)
        try await healthCategory.save(on: req.db)
        try await cultureCategory.save(on: req.db)
        
        let cellsData = [Cell(categoryID: foodCategory.id!,
                              image: "food",
                              title: "Уличная еда: риск или кайф?",
                              subtitle: "Гастрономический гид",
                              date: Date(),
                              readingTime: 6,
                              description: "Попробовать местную кухню...",
                              images: ["img1", "img2"]),
                         Cell(categoryID: leisureCategory.id!,
                              image: "leisure",
                              title: "Идеальные фото в Instagram",
                              subtitle: "Снимаем как профи",
                              date: Date(),
                              readingTime: 5,
                              description: "Вам не нужна дорогая камера...",
                              images: ["img1", "img2"]),
                         Cell(categoryID: fraudCategory.id!,
                              image: "fraud",
                              title: "Как не попасться мошенникам",
                              subtitle: "Правила безопасности",
                              date: Date(),
                              readingTime: 4,
                              description: "Туристические ловушки...",
                              images: ["img1", "img2"]),
                         Cell(categoryID: healthCategory.id!,
                              image: "health",
                              title: "Аптечка туриста",
                              subtitle: "Здоровье важнее всего",
                              date: Date(),
                              readingTime: 6,
                              description: "Список лекарств...",
                              images: ["img1", "img2"])]
        
        for cell in cellsData {
            try await cell.save(on: req.db)
        }
        
        return "База данных обновлена!"
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
        
        return "База данных очищена!"
    }
    
    try app.register(collection: AuthController())
    try app.register(collection: FavoritesController())
}


