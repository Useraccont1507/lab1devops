import NIOSSL
import Fluent
import FluentMySQLDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.http.server.configuration.port = 8000
    app.http.server.configuration.hostname = "127.0.0.1"
    

    app.databases.use(.mysql(
        hostname: "127.0.0.1",
        username: "inventory_user",
        password: "1111",
        database: "inventory_db"
    ), as: .mysql)
    
    app.migrations.add(CreateInventoryItem())

    app.views.use(.leaf)

    // register routes
    try routes(app)
    
    try await app.autoMigrate()
}
