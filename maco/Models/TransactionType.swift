//
//  TransactionType.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    case invoice = "invoice"
    
    var displayName: String {
        switch self {
        case .income:
            return "Income"
        case .expense:
            return "Expense"
        case .invoice:
            return "Invoice"
        }
    }
}

