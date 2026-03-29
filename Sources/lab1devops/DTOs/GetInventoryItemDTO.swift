//
//  GetInventoryItemDTO.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent
import Vapor

struct GetInventoryItemDTO: Content {
    let id: UUID
    let name: String
    let quantity: Int
    let created_at: Int
}

