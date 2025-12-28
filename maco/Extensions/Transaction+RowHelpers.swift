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
        case "paid":
            return .green
        case "overdue":
            return .red
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
        return self.categoryName ?? ""
    }
    
    /// Checks if transaction is paid (handles whitespace and case)
    var isPaid: Bool {
        guard let status = self.status else { return false }
        return status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "paid"
    }
    
    /// Returns formatted date for section headers ("Today", "Yesterday", or "Dec 18, 2025")
    var formattedCreatedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self.createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(self.createdAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: self.createdAt)
        }
    }
    
    /// Returns formatted due date for transaction row labels ("Dec 18" format)
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self.dueDate)
    }
    
    /// Returns formatted paid date for badge text ("Dec 20" format)
    var formattedPaidDate: String {
        guard let paidAt = self.paidAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: paidAt)
    }
    
    /// Checks if transaction is overdue (due_date < today and status != "paid")
    var isOverdue: Bool {
        guard !isPaid else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: self.dueDate)
        return dueDate < today
    }
    
    /// Returns badge text based on transaction status (only for non-paid transactions)
    var badgeText: String? {
        if isPaid {
            return nil
        } else if isOverdue {
            return "OVERDUE"
        } else {
            return "PENDING"
        }
    }
    
    /// Returns badge color based on transaction status (only for non-paid transactions)
    var badgeColor: Color? {
        if isPaid {
            return nil
        } else if isOverdue {
            return .red
        } else {
            return .blue
        }
    }
    
    /// Returns whether a badge should be displayed for this transaction
    var shouldShowBadge: Bool {
        return badgeText != nil
    }
}

