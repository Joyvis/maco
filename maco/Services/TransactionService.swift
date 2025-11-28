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
        
        // Fetch existing transactions to check for duplicates
        let descriptor = FetchDescriptor<Transaction>()
        let existingTransactions = try modelContext.fetch(descriptor)
        let existingIds = Set(existingTransactions.compactMap { $0.id })
        
        for response in responses {
            // Skip if transaction already exists
            if existingIds.contains(response.id) {
                continue
            }
            
            // Parse date with fallback to current date
            let dueDate = parseDate(response.dueDate) ?? Date()
            
            // Create SwiftData Transaction from API response
            let transaction = Transaction(
                id: response.id,
                amount: response.amount,
                type: TransactionType(rawValue: response.type) ?? .expense,
                dueDate: dueDate,
                transactionDescription: response.description,
                categoryId: response.categoryId,
                recurringScheduleId: response.recurringScheduleId
            )
            
            modelContext.insert(transaction)
        }
        
        // Save changes
        try modelContext.save()
    }
}

