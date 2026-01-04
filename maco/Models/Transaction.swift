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
    var paymentMethodId: String?
    var paymentMethodName: String?
    var recurringScheduleId: String?
    var createdAt: Date
    var paidAt: Date?
    
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
        paymentMethodId: String? = nil,
        paymentMethodName: String? = nil,
        recurringScheduleId: String? = nil,
        invoiceItems: [Transaction]? = nil,
        paidAt: Date? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type.rawValue
        self.dueDate = dueDate
        self.transactionDescription = transactionDescription
        self.categoryId = categoryId
        self.status = status
        self.categoryName = categoryName  // ADD THIS
        self.paymentMethodId = paymentMethodId
        self.paymentMethodName = paymentMethodName
        self.recurringScheduleId = recurringScheduleId
        self.invoiceItems = invoiceItems
        self.createdAt = Date()
        self.paidAt = paidAt
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
    let paidTotal: String
    let paidTransactions: [TransactionResponse]
    let notPaidTotal: String
    let notPaidTransactions: [TransactionResponse]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle paid_total as either number or string
        if let paidTotalString = try? container.decode(String.self, forKey: .paidTotal) {
            paidTotal = paidTotalString
        } else if let paidTotalNumber = try? container.decode(Double.self, forKey: .paidTotal) {
            // Format number to string with 2 decimal places
            paidTotal = String(format: "%.2f", paidTotalNumber)
        } else {
            paidTotal = "0.00"
        }
        
        paidTransactions = try container.decode([TransactionResponse].self, forKey: .paidTransactions)
        
        // Handle not_paid_total as either number or string
        if let notPaidTotalString = try? container.decode(String.self, forKey: .notPaidTotal) {
            notPaidTotal = notPaidTotalString
        } else if let notPaidTotalNumber = try? container.decode(Double.self, forKey: .notPaidTotal) {
            // Format number to string with 2 decimal places
            notPaidTotal = String(format: "%.2f", notPaidTotalNumber)
        } else {
            notPaidTotal = "0.00"
        }
        
        notPaidTransactions = try container.decode([TransactionResponse].self, forKey: .notPaidTransactions)
    }
    
    enum CodingKeys: String, CodingKey {
        case paidTotal = "paid_total"
        case paidTransactions = "paid_transactions"
        case notPaidTotal = "not_paid_total"
        case notPaidTransactions = "not_paid_transactions"
    }
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
        let paymentMethodId: String?
        let paidAt: String?
        
        enum CodingKeys: String, CodingKey {
            case amount
            case type
            case dueDate = "due_date"
            case description
            case categoryId = "category_id"
            case status
            case paymentMethodId = "payment_method_id"
            case paidAt = "paid_at"
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(amount, forKey: .amount)
            try container.encode(type, forKey: .type)
            try container.encode(dueDate, forKey: .dueDate)
            try container.encode(description, forKey: .description)
            try container.encodeIfPresent(categoryId, forKey: .categoryId)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encodeIfPresent(paymentMethodId, forKey: .paymentMethodId)
            // Always encode paid_at, even if nil (to send null explicitly)
            try container.encode(paidAt, forKey: .paidAt)
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
    let paymentMethodId: String?
    let paymentMethodName: String?
    let recurringScheduleId: String?
    let invoiceItems: [TransactionResponse]?
    let paidAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case type
        case dueDate = "due_date"
        case description
        case categoryId = "category_id"
        case status
        case categoryName = "category_name"  // ADD THIS
        case paymentMethodId = "payment_method_id"
        case paymentMethodName = "payment_method_name"
        case recurringScheduleId = "recurring_schedule_id"
        case invoiceItems = "invoice_items"
        case paidAt = "paid_at"
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
        paymentMethodId = try container.decodeIfPresent(String.self, forKey: .paymentMethodId)
        paymentMethodName = try container.decodeIfPresent(String.self, forKey: .paymentMethodName)
        recurringScheduleId = try container.decodeIfPresent(String.self, forKey: .recurringScheduleId)
        invoiceItems = try container.decodeIfPresent([TransactionResponse].self, forKey: .invoiceItems)
        paidAt = try container.decodeIfPresent(String.self, forKey: .paidAt)
    }
}

