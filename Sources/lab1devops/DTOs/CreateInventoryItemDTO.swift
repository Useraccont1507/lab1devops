//
//  CreateInventoryItemDTO.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent
import Vapor

struct CreateInventoryItemDTO: Content {
    let name: String
    let quantity: Int
}
