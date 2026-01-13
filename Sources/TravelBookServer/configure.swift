import Vapor
import Fluent
import FluentPostgresDriver
import NIOSSL
import SotoS3

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080
    app.routes.defaultMaxBodySize = "50mb"
    
    try app.configureDatabase()
    try app.configureS3()
    
    app.configureMigrations()
    
    try routes(app)
}

extension Application {
    func configureDatabase() throws {
        guard let hostname = Environment.get("hostname"),
              let username = Environment.get("username"),
              let password = Environment.get("password"),
              let database = Environment.get("db") else {
            throw Abort(.internalServerError, reason: "Invalid DB credentials")
        }
        
        let port = Int(Environment.get("port") ?? "6432") ?? 6432
        let certPath = self.directory.workingDirectory + "root.crt"
        
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.trustRoots = .file(certPath)
        tlsConfig.certificateVerification = .fullVerification
        let sslContext = try NIOSSLContext(configuration: tlsConfig)
        
        let dbConfig = SQLPostgresConfiguration(hostname: hostname,
                                                port: port,
                                                username: username,
                                                password: password,
                                                database: database,
                                                tls: .require(sslContext))
        
        self.databases.use(.postgres(configuration: dbConfig), as: .psql)
    }
    
    func configureS3() throws {
        guard let keyId = Environment.get("S3_KEY_ID"),
              let secret = Environment.get("S3_SECRET_KEY") else {
            throw Abort(.internalServerError, reason: "S3 not configured")
        }
        
        let awsClient = AWSClient(credentialProvider: .static(accessKeyId: keyId, secretAccessKey: secret),
                                  httpClientProvider: .createNew)
        
        let s3 = S3(client: awsClient, region: Region(rawValue: "ru-central1"), endpoint: "https://storage.yandexcloud.net")
        
        self.storage[S3Key.self] = s3
        self.lifecycle.use(AWSClientLifecycleHandler(client: awsClient))
    }
    
    func configureMigrations() {
        self.migrations.add(CreateCategories())
        self.migrations.add(CreateCells())
        self.migrations.add(CreateUsers())
        self.migrations.add(CreateTokens())
        self.migrations.add(CreateUserFavorites())
    }
}

struct S3Key: StorageKey {
    typealias Value = S3
}

struct AWSClientLifecycleHandler: LifecycleHandler {
    let client: AWSClient

    func shutdown(_ application: Application) {
        try? client.syncShutdown()
    }
}

