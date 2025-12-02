//
//  TransactionService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import SwiftData

class TransactionService {
    static let shared = TransactionService()
    
    private init() {}
    
    func createTransaction(
        amount: String,
        type: TransactionType,
        dueDate: Date,
        description: String,
        categoryId: String?
    ) async throws -> TransactionResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = TransactionRequest(
            transaction: TransactionRequest.TransactionAttributes(
                amount: amount,
                type: type.rawValue,
                dueDate: dateFormatter.string(from: dueDate),
                description: description,
                categoryId: categoryId
            )
        )
        
        return try await APIService.shared.post(
            endpoint: "/transactions",
            body: request,
            responseType: TransactionResponse.self
        )
    }
    
    func updateTransaction(
        id: String,
        amount: String,
        type: TransactionType,
        dueDate: Date,
        description: String,
        categoryId: String?
    ) async throws -> TransactionResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = TransactionRequest(
            transaction: TransactionRequest.TransactionAttributes(
                amount: amount,
                type: type.rawValue,
                dueDate: dateFormatter.string(from: dueDate),
                description: description,
                categoryId: categoryId
            )
        )
        
        return try await APIService.shared.patch(
            endpoint: "/transactions/\(id)",
            body: request,
            responseType: TransactionResponse.self
        )
    }
    
    func fetchTransactions() async throws -> [TransactionResponse] {
        return try await APIService.shared.get(
            endpoint: "/transactions",
            responseType: [TransactionResponse].self
        )
    }
    
    func deleteTransaction(id: String) async throws {
        try await APIService.shared.delete(endpoint: "/transactions/\(id)")
    }
    
    // MARK: - Sync Methods
    
    /// Parses ISO8601 date string to Date
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    /// Syncs transactions from API to SwiftData
    /// - Parameter modelContext: SwiftData model context to insert/update transactions
    func syncTransactions(modelContext: ModelContext) async throws {
        let responses = try await fetchTransactions()
        
        // Fetch existing transactions to check for duplicates and updates
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let existingTransactions = try modelContext.fetch(transactionDescriptor)
        let existingTransactionsById = Dictionary(uniqueKeysWithValues: existingTransactions.compactMap { transaction -> (String, Transaction)? in
            guard let id = transaction.id else { return nil }
            return (id, transaction)
        })
        
        // Update the transaction creation around line 154-162:
        for response in responses {
            // Check if transaction already exists
            if let existingTransaction = existingTransactionsById[response.id] {
                // Update all fields from API response to keep local data in sync
                existingTransaction.amount = response.amount
                // Normalize type to lowercase to handle API returning "Income"/"Expense"
                existingTransaction.transactionType = TransactionType(rawValue: response.type.lowercased()) ?? .expense
                existingTransaction.dueDate = parseDate(response.dueDate) ?? existingTransaction.dueDate
                existingTransaction.transactionDescription = response.description
                existingTransaction.categoryId = response.categoryId
                existingTransaction.categoryName = response.categoryName
                existingTransaction.recurringScheduleId = response.recurringScheduleId
                continue
            }
            
            // Parse date with fallback to current date
            let dueDate = parseDate(response.dueDate) ?? Date()
            
            // Create SwiftData Transaction from API response
            // Normalize type to lowercase to handle API returning "Income"/"Expense"
            let transaction = Transaction(
                id: response.id,
                amount: response.amount,
                type: TransactionType(rawValue: response.type.lowercased()) ?? .expense,
                dueDate: dueDate,
                transactionDescription: response.description,
                categoryId: response.categoryId,
                categoryName: response.categoryName,
                recurringScheduleId: response.recurringScheduleId
            )
            
            modelContext.insert(transaction)
        }
        
        // Save all changes (categories and transactions)
        try modelContext.save()
    }
}

