//
//  GetInventoryItemsDTO.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent
import Vapor

struct GetInventoryItemsDTO: Content {
    let items: [Item]
    struct Item: Content {
        let id: UUID
        let name: String
    }
}
