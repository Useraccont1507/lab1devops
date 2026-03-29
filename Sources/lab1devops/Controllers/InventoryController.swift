//
//  InventoryController.swift
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
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><title>Inventory API</title></head>
        <body>
            <h1>MyWebApp - Simple Inventory</h1>
            <ul>
                <li><a href="/items">GET /items</a> - List all items</li>
                <li>POST /items - Create new item (use curl or Postman)</li>
                <li>GET /items/&lt;id&gt; - Get item details</li>
                <li><a href="/health/alive">GET /health/alive</a> - Liveness</li>
                <li><a href="/health/ready">GET /health/ready</a> - Readiness</li>
            </ul>
        </body>
        </html>
        """
        return try await htmlToResponse(html, for: req)
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
        
        if req.headers.accept.contains(where: { $0.mediaType == .html }) &&
           !req.headers.accept.contains(where: { $0.mediaType == .json }) {
            let tableRows = dto.items.map { "<tr><td>\($0.id)</td><td><a href='/items/\($0.id)'>\($0.name)</a></td></tr>" }.joined()
            let html = """
            <!DOCTYPE html>
            <html>
            <body>
                <h1>Items List</h1>
                <table border='1'>
                    <tr><th>ID</th><th>Name</th></tr>
                    \(tableRows)
                </table>
                <br><a href="/">Back to Home</a>
            </body>
            </html>
            """
            return try await htmlToResponse(html, for: req)
        }  else {
            return try await dto.encodeResponse(for: req)
        }
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
        
        if req.headers.accept.contains(where: { $0.mediaType == .html }) &&
           !req.headers.accept.contains(where: { $0.mediaType == .json }) {
            let html = """
                <!DOCTYPE html>
                <html>
                <body>
                    <h1>Item Details</h1>
                    <p><b>Name:</b> \(dto.name)</p>
                    <a href="/items">Back</a>
                </body>
                </html>
                """
            return try await htmlToResponse(html, for: req)
        } else {
            return try await dto.encodeResponse(for: req)
        }
    }
    func createItem(req: Request) async throws -> Response {
        try CreateInventoryItemDTO.validate(content: req)
        let input = try req.content.decode(CreateInventoryItemDTO.self)
        
        let item = InventoryItem(name: input.name, quantity: input.quantity)
        
        try await item.save(on: req.db)
        
        return Response(status: .ok, body: .init(string: "OK"))
    }
    private func htmlToResponse(_ html: String, for req: Request) async throws -> Response {
        let res = Response(status: .ok, body: .init(string: html))
        res.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        return res
    }
}
