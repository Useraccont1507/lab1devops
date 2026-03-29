//
//  CreateInventoryItemDTO.swift
//  lab1devops
//
//  Created by Illia Verezei on 29.03.2026.
//

import Fluent
import Vapor

struct CreateInventoryItemDTO: Content, Validatable {
    let name: String
    let quantity: Int
    
    static func validations(_ v: inout Validations) {
        v.add("name", as: String.self, is: .count(1...))
        v.add("quantity", as: Int.self, is: .in(1...))
    }
}
