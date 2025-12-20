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
    var status: String?
    var categoryName: String?  // ADD THIS
    var recurringScheduleId: String?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.parentInvoice)
    var invoiceItems: [Transaction]?
    
    var parentInvoice: Transaction?
    
    init(
        id: String? = nil,
        amount: String,
        type: TransactionType,
        dueDate: Date,
        transactionDescription: String,
        categoryId: String? = nil,
        status: String? = nil,
        categoryName: String? = nil,  // ADD THIS
        recurringScheduleId: String? = nil,
        invoiceItems: [Transaction]? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type.rawValue
        self.dueDate = dueDate
        self.transactionDescription = transactionDescription
        self.categoryId = categoryId
        self.status = status
        self.categoryName = categoryName  // ADD THIS
        self.recurringScheduleId = recurringScheduleId
        self.invoiceItems = invoiceItems
        self.createdAt = Date()
    }

    var transactionType: TransactionType {
        get {
            // Normalize to lowercase to handle case variations
            TransactionType(rawValue: type.lowercased()) ?? .expense
        }
        set {
            type = newValue.rawValue
        }
    }
}

// MARK: - API Models

struct TransactionsListResponse: Codable {
    let total: String
    let transactions: [TransactionResponse]
}

struct TransactionRequest: Codable {
    let transaction: TransactionAttributes
    
    struct TransactionAttributes: Codable {
        let amount: String
        let type: String
        let dueDate: String
        let description: String
        let categoryId: String?
        let status: String?
        
        enum CodingKeys: String, CodingKey {
            case amount
            case type
            case dueDate = "due_date"
            case description
            case categoryId = "category_id"
            case status
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
    let status: String?
    let categoryName: String?  // ADD THIS - replaces nested category object
    let recurringScheduleId: String?
    let invoiceItems: [TransactionResponse]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case type
        case dueDate = "due_date"
        case description
        case categoryId = "category_id"
        case status
        case categoryName = "category_name"  // ADD THIS
        case recurringScheduleId = "recurring_schedule_id"
        case invoiceItems = "invoice_items"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        amount = try container.decode(String.self, forKey: .amount)
        // Handle missing type field - default to "expense" if not present
        // Normalize to lowercase to handle API returning "Income"/"Expense" vs enum expecting "income"/"expense"
        let rawType = (try? container.decode(String.self, forKey: .type)) ?? "expense"
        type = rawType.lowercased()
        dueDate = try container.decode(String.self, forKey: .dueDate)
        description = try container.decode(String.self, forKey: .description)
        // REMOVE nested category decoding (lines 140-148)
        // REPLACE with:
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        recurringScheduleId = try container.decodeIfPresent(String.self, forKey: .recurringScheduleId)
        invoiceItems = try container.decodeIfPresent([TransactionResponse].self, forKey: .invoiceItems)
    }
}

