//
//  Transaction+RowHelpers.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

extension Transaction {
    /// Returns the formatted currency string for the transaction amount
    var formattedAmount: String {
        if let amount = Double(self.amount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "BRL"
            return formatter.string(from: NSNumber(value: amount)) ?? self.amount
        }
        return self.amount
    }
    
    /// Returns the color associated with the transaction status
    var statusColor: Color {
        switch self.status {
        case "approved", "paid", "pago":
            return .green
        case "overdue":
            return .red
        case "pending":
            return .orange
        default:
            return .secondary
        }
    }
    
    /// Returns the status string, or empty string if nil
    var displayStatus: String {
        return self.status ?? ""
    }
    
    /// Returns the category name, or "Uncategorized" if nil
    var displayCategoryName: String {
        return self.categoryName ?? "Uncategorized"
    }
}

