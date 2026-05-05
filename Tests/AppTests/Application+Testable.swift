import XCTVapor
import Fluent
import FluentSQLiteDriver
@testable import App

/// Builds an Application configured for testing.
/// Uses SQLite in-memory so no MySQL instance is required.
func makeTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateInventoryItem())
    try routes(app)
    try await app.autoMigrate()
    return app
}
