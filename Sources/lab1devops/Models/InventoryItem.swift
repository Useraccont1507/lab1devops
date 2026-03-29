//
//  InventoryItem.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Foundation
import Fluent

final class InventoryItem: Model, @unchecked Sendable {
    static let schema = "InventoryItems"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "quantity")
    var quantity: Int
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(name: String, quantity: Int) {
        self.name = name
        self.quantity = quantity
    }
}
