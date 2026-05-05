import XCTest
import XCTVapor
import Fluent
@testable import App

// MARK: - Helpers

private struct ItemInput: Content {
    let name: String
    let quantity: Int
}

// MARK: - Test Suite

final class AppTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await makeTestApp()
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    // MARK: Health endpoints

    func testHealthAlive() async throws {
        try await app.test(.GET, "/health/alive") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "OK")
        }
    }

    func testHealthReady() async throws {
        try await app.test(.GET, "/health/ready") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "OK")
        }
    }

    // MARK: Root

    func testGetRootReturnsHTML() async throws {
        try await app.test(.GET, "/") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.headers.contentType?.description.contains("text/html") ?? false)
            XCTAssertTrue(res.body.string.contains("Inventory"))
            XCTAssertTrue(res.body.string.contains("/items"))
            XCTAssertTrue(res.body.string.contains("/health/alive"))
        }
    }

    // MARK: GET /items

    func testGetItemsEmptyReturnsJSON() async throws {
        try await app.test(.GET, "/items", headers: ["Accept": "application/json"]) { res async in
            XCTAssertEqual(res.status, .ok)
            let dto = try? res.content.decode(GetInventoryItemsDTO.self)
            XCTAssertNotNil(dto)
            XCTAssertEqual(dto?.items.count, 0)
        }
    }

    func testGetItemsReturnsHTMLWhenAcceptIsHTML() async throws {
        try await app.test(.GET, "/items", headers: ["Accept": "text/html"]) { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.headers.contentType?.description.contains("text/html") ?? false)
            XCTAssertTrue(res.body.string.contains("Items List"))
        }
    }

    // MARK: POST /items

    func testCreateItemReturns200() async throws {
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Widget", quantity: 10))
            },
            afterResponse: { res async in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.body.string, "OK")
            }
        )
    }

    func testCreateItemWithZeroQuantity() async throws {
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Free Item", quantity: 0))
            },
            afterResponse: { res async in
                XCTAssertEqual(res.status, .ok)
            }
        )
    }

    func testCreateItemEmptyNameFailsValidation() async throws {
        // Vapor's ValidationsError is thrown as 400 Bad Request
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "", quantity: 5))
            },
            afterResponse: { res async in
                XCTAssertEqual(res.status, .badRequest)
            }
        )
    }

    func testCreateItemNegativeQuantityFailsValidation() async throws {
        // Vapor's ValidationsError is thrown as 400 Bad Request
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Bad Item", quantity: -1))
            },
            afterResponse: { res async in
                XCTAssertEqual(res.status, .badRequest)
            }
        )
    }

    func testCreateItemMissingBodyFailsValidation() async throws {
        try await app.test(.POST, "/items") { res async in
            XCTAssertEqual(res.status, .unprocessableEntity)
        }
    }

    // MARK: GET /items after creation

    func testGetItemsAfterCreateReturnsOneItem() async throws {
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Gadget", quantity: 3))
            },
            afterResponse: { _ async in }
        )

        try await app.test(.GET, "/items", headers: ["Accept": "application/json"]) { res async in
            XCTAssertEqual(res.status, .ok)
            let dto = try? res.content.decode(GetInventoryItemsDTO.self)
            XCTAssertEqual(dto?.items.count, 1)
            XCTAssertEqual(dto?.items.first?.name, "Gadget")
        }
    }

    // MARK: GET /items/:id

    func testGetItemByIdReturnsJSONDetails() async throws {
        // Create item
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Sprocket", quantity: 7))
            },
            afterResponse: { _ async in }
        )

        // Fetch list to get the ID
        var itemId: UUID?
        try await app.test(.GET, "/items", headers: ["Accept": "application/json"]) { res async in
            let dto = try? res.content.decode(GetInventoryItemsDTO.self)
            itemId = dto?.items.first?.id
        }

        guard let id = itemId else {
            XCTFail("Expected item in list after creation")
            return
        }

        // Fetch by ID with JSON
        try await app.test(
            .GET, "/items/\(id)",
            headers: ["Accept": "application/json"]
        ) { res async in
            XCTAssertEqual(res.status, .ok)
            let dto = try? res.content.decode(GetInventoryItemDTO.self)
            XCTAssertNotNil(dto)
            XCTAssertEqual(dto?.name, "Sprocket")
            XCTAssertEqual(dto?.quantity, 7)
            XCTAssertEqual(dto?.id, id)
            XCTAssertGreaterThan(dto?.created_at ?? 0, 0)
        }
    }

    func testGetItemByIdReturnsHTMLWhenAcceptIsHTML() async throws {
        try await app.test(
            .POST, "/items",
            beforeRequest: { req in
                try req.content.encode(ItemInput(name: "Bolt", quantity: 100))
            },
            afterResponse: { _ async in }
        )

        var itemId: UUID?
        try await app.test(.GET, "/items", headers: ["Accept": "application/json"]) { res async in
            let dto = try? res.content.decode(GetInventoryItemsDTO.self)
            itemId = dto?.items.first?.id
        }

        guard let id = itemId else {
            XCTFail("Expected item in list after creation")
            return
        }

        try await app.test(.GET, "/items/\(id)", headers: ["Accept": "text/html"]) { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.headers.contentType?.description.contains("text/html") ?? false)
            XCTAssertTrue(res.body.string.contains("Item Details"))
            XCTAssertTrue(res.body.string.contains("Bolt"))
        }
    }

    func testGetItemByIdNotFound() async throws {
        let randomId = UUID()
        try await app.test(.GET, "/items/\(randomId)", headers: ["Accept": "application/json"]) { res async in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    func testGetItemByInvalidUUIDNotFound() async throws {
        try await app.test(.GET, "/items/not-a-uuid", headers: ["Accept": "application/json"]) { res async in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    // MARK: TimestampConvertable unit tests

    func testTimestampToDateRoundtrip() {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let ts = TimestampConvertable.toTimestamp(original)
        let recovered = TimestampConvertable.toDate(ts)
        XCTAssertEqual(Int(original.timeIntervalSince1970), Int(recovered.timeIntervalSince1970))
    }

    func testTimestampConvertableZeroEpoch() {
        let date = TimestampConvertable.toDate(0)
        XCTAssertEqual(date.timeIntervalSince1970, 0)
    }

    func testToTimestampIsPositiveForRecentDate() {
        let ts = TimestampConvertable.toTimestamp(Date())
        XCTAssertGreaterThan(ts, 0)
    }
}
