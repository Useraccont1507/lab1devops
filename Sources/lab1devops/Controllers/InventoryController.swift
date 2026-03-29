//
//  File.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent
import Vapor

struct InventoryController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.get(use: getRoot)
        let health = routes.grouped("health")
        health.get("alive") { _ in "OK" }
        health.get("ready", use: getReady)
        
        let items = routes.grouped("items")
        items.get(use: getItems)
        items.post(use: createItem)
        items.get(":itemId", use: getItem)
    }
    func getRoot(req: Request) async throws -> Response {
        let html = """
            <h1>MyWebApp - Simple Inventory</h1>
            <ul>
                <li><a href="/items">GET /items</a> - List all items</li>
                <li>POST /items - Create new item</li>
                <li>GET /items/&lt;id&gt; - Get item details</li>
                <li><a href="/health/alive">GET /health/alive</a> - Liveness</li>
                <li><a href="/health/ready">GET /health/ready</a> - Readiness</li>
            </ul>
            """
        return try await html.encodeResponse(for: req)
    }
    func getReady(req: Request) async throws -> Response {
        do {
            _ = try await InventoryItem.query(on: req.db).first()
            return Response(status: .ok, body: .init(string: "OK"))
        } catch {
            return Response(status: .internalServerError, body: .init(string: "Database connection failed: \(error)"))
        }
    }
    func getItems(req: Request) async throws -> Response {
        let itemsModels = try await InventoryItem.query(on: req.db).all()
        let dto = GetInventoryItemsDTO(items: itemsModels.compactMap { model in
            guard let id = model.id else { return nil }
            return .init(id: id, name: model.name)
        })
        
        if req.headers.accept.contains(where: { $0.mediaType == .html }) {
            var tableRows = dto.items.map { "<tr><td>\($0.id)</td><td>\($0.name)</td></tr>" }.joined()
            let html = "<h1>Items</h1><table border='1'><tr><th>ID</th><th>Name</th></tr>\(tableRows)</table>"
            return try await html.encodeResponse(for: req)
        }
        return try await dto.encodeResponse(for: req)
    }
    func getItem(req: Request) async throws -> Response {
        guard let itemIdString = req.parameters.get("itemId"),
              let itemId = UUID(uuidString: itemIdString),
              let model = try await InventoryItem.find(itemId, on: req.db),
              let date = model.createdAt else {
            throw Abort(.notFound)
        }
        
        let dto = GetInventoryItemDTO(
            id: model.id!,
            name: model.name,
            quantity: model.quantity,
            created_at: TimestampConvertable.toTimestamp(date)
        )
        
        if req.headers.accept.contains(where: { $0.mediaType == .html }) {
            let html = """
                <h1>Item Details</h1>
                <p>ID: \(dto.id)</p>
                <p>Name: \(dto.name)</p>
                <p>Quantity: \(dto.quantity)</p>
                <p>Created At: \(dto.created_at)</p>
                <a href="/items">Back to list</a>
                """
            return try await html.encodeResponse(for: req)
        }
        return try await dto.encodeResponse(for: req)
    }
    func createItem(req: Request) async throws -> Response {
        try CreateInventoryItemDTO.validate(content: req)
        let input = try req.content.decode(CreateInventoryItemDTO.self)
        
        let item = InventoryItem(name: input.name, quantity: input.quantity)
        
        try await item.save(on: req.db)
        
        return Response(status: .ok)
    }
}
