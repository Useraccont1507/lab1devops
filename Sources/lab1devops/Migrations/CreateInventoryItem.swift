//
//  CreateInventoryItem.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent

struct CreateInventoryItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(InventoryItem.schema)
            .id()
            .field("name", .string, .required)
            .field("quantity", .int, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(InventoryItem.schema).delete()
    }
}
