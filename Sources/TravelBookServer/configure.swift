import Vapor
import Fluent
import FluentPostgresDriver
import NIOSSL

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080
    
    let certPath = app.directory.workingDirectory + "root.crt"
    
    var tlsConfig = TLSConfiguration.makeClientConfiguration()
    tlsConfig.trustRoots = .file(certPath)
    tlsConfig.certificateVerification = .fullVerification
    
    let sslContext = try NIOSSLContext(configuration: tlsConfig)
    let dbConfig = SQLPostgresConfiguration(hostname: DB.hostname,
                                            port:     DB.port,
                                            username: DB.username,
                                            password: DB.password,
                                            database: DB.db,
                                            tls: .require(sslContext))
    
    app.databases.use(.postgres(configuration: dbConfig), as: .psql)
    
    app.migrations.add(CreateCategories())
    app.migrations.add(CreateCells())
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())
    app.migrations.add(CreateUserFavorites())
    
    try routes(app)
}
