import NIOSSL
import Fluent
import FluentMySQLDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let dbHost = Environment.get("DB_HOST") ?? "127.0.0.1"
    let dbUser = Environment.get("DB_USER") ?? "inventory_user"
    let dbPass = Environment.get("DB_PASSWORD") ?? "1111"
    let dbName = Environment.get("DB_NAME") ?? "inventory_db"
    
    app.databases.use(.mysql(
        hostname: dbHost,
        username: dbUser,
        password: dbPass,
        database: dbName,
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)
    
    app.migrations.add(CreateInventoryItem())
    
    app.views.use(.leaf)

    // register routes
    try routes(app)
    
    try await app.autoMigrate()
}
