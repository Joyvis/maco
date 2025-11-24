//
//  Transaction.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: String?
    var amount: String
    var type: String
    var dueDate: Date
    var transactionDescription: String
    var categoryId: String?
    var recurringScheduleId: String?
    var createdAt: Date
    
    init(
        id: String? = nil,
        amount: String,
        type: TransactionType,
        dueDate: Date,
        transactionDescription: String,
        categoryId: String? = nil,
        recurringScheduleId: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type.rawValue
        self.dueDate = dueDate
        self.transactionDescription = transactionDescription
        self.categoryId = categoryId
        self.recurringScheduleId = recurringScheduleId
        self.createdAt = Date()
    }
    
    var transactionType: TransactionType {
        get {
            TransactionType(rawValue: type) ?? .expense
        }
        set {
            type = newValue.rawValue
        }
    }
}

// MARK: - API Models

struct TransactionRequest: Codable {
    let transaction: TransactionAttributes
    
    struct TransactionAttributes: Codable {
        let amount: String
        let type: String
        let dueDate: String
        let description: String
        let categoryId: String?
        
        enum CodingKeys: String, CodingKey {
            case amount
            case type
            case dueDate = "due_date"
            case description
            case categoryId = "category_id"
        }
    }
}

struct TransactionResponse: Codable {
    let id: String
    let amount: String
    let type: String
    let dueDate: String
    let description: String
    let categoryId: String?
    let recurringScheduleId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case type
        case dueDate = "due_date"
        case description
        case categoryId = "category_id"
        case recurringScheduleId = "recurring_schedule_id"
    }
}

