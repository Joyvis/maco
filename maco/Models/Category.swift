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
    let isPredefined: Bool?
    let userId: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case parentId = "parent_id"
        case isPredefined = "is_predefined"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        name = try container.decode(String.self, forKey: .name)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        isPredefined = try container.decodeIfPresent(Bool.self, forKey: .isPredefined)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

