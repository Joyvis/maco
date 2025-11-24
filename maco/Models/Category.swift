//
//  Category.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: String?
    var name: String
    var parentId: String?
    var isPredefined: Bool
    var userId: String?
    
    init(id: String? = nil, name: String, parentId: String? = nil, isPredefined: Bool = false, userId: String? = nil) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.isPredefined = isPredefined
        self.userId = userId
    }
}

// MARK: - API Models

struct CategoryRequest: Codable {
    let transactionCategory: CategoryAttributes
    
    enum CodingKeys: String, CodingKey {
        case transactionCategory = "transaction_category"
    }
    
    struct CategoryAttributes: Codable {
        let name: String
        let parentId: String?
        
        enum CodingKeys: String, CodingKey {
            case name
            case parentId = "parent_id"
        }
    }
}

struct CategoryResponse: Codable {
    let id: String
    let name: String
    let parentId: String?
    let isPredefined: Bool
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case parentId = "parent_id"
        case isPredefined = "is_predefined"
        case userId = "user_id"
    }
}

