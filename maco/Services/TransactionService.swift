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
        categoryId: String?,
        status: String?
    ) async throws -> TransactionResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = TransactionRequest(
            transaction: TransactionRequest.TransactionAttributes(
                amount: amount,
                type: type.rawValue,
                dueDate: dateFormatter.string(from: dueDate),
                description: description,
                categoryId: categoryId,
                status: status
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
        categoryId: String?,
        status: String?
    ) async throws -> TransactionResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = TransactionRequest(
            transaction: TransactionRequest.TransactionAttributes(
                amount: amount,
                type: type.rawValue,
                dueDate: dateFormatter.string(from: dueDate),
                description: description,
                categoryId: categoryId,
                status: status
            )
        )
        
        return try await APIService.shared.patch(
            endpoint: "/transactions/\(id)",
            body: request,
            responseType: TransactionResponse.self
        )
    }
    
    func fetchTransactions(month: Int? = nil, year: Int? = nil) async throws -> [TransactionResponse] {
        // Build query parameters if month/year are provided
        var queryParameters: [String: String]? = nil
        if let month = month, let year = year {
            queryParameters = [
                "month": String(month),
                "year": String(year)
            ]
        }
        
        // Try to decode as wrapper response first, fallback to array
        do {
            let wrapperResponse = try await APIService.shared.get(
                endpoint: "/transactions",
                queryParameters: queryParameters,
                responseType: TransactionsListResponse.self
            )
            return wrapperResponse.transactions
        } catch {
            // Fallback to direct array response if wrapper decoding fails
            return try await APIService.shared.get(
                endpoint: "/transactions",
                queryParameters: queryParameters,
                responseType: [TransactionResponse].self
            )
        }
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

    /// Converts a TransactionResponse to a Transaction, including invoice items
    private func createTransaction(from response: TransactionResponse, modelContext: ModelContext, existingTransactionsById: [String: Transaction]) -> Transaction {
        // Parse date with fallback to current date
        let dueDate = parseDate(response.dueDate) ?? Date()
        
        // Create invoice items if present
        var invoiceItems: [Transaction]? = nil
        if let items = response.invoiceItems, !items.isEmpty {
            invoiceItems = items.map { itemResponse in
                // Check if invoice item already exists
                if let existingItem = existingTransactionsById[itemResponse.id] {
                    // Update existing item
                    existingItem.amount = itemResponse.amount
                    existingItem.transactionType = TransactionType(rawValue: itemResponse.type.lowercased()) ?? .expense
                    existingItem.dueDate = parseDate(itemResponse.dueDate) ?? existingItem.dueDate
                    existingItem.transactionDescription = itemResponse.description
                    existingItem.categoryId = itemResponse.categoryId
                    existingItem.status = itemResponse.status
                    existingItem.categoryName = itemResponse.categoryName
                    existingItem.recurringScheduleId = itemResponse.recurringScheduleId
                    return existingItem
                } else {
                    // Create new invoice item
                    let itemDueDate = parseDate(itemResponse.dueDate) ?? Date()
                    let item = Transaction(
                        id: itemResponse.id,
                        amount: itemResponse.amount,
                        type: TransactionType(rawValue: itemResponse.type.lowercased()) ?? .expense,
                        dueDate: itemDueDate,
                        transactionDescription: itemResponse.description,
                        categoryId: itemResponse.categoryId,
                        status: itemResponse.status,
                        categoryName: itemResponse.categoryName,
                        recurringScheduleId: itemResponse.recurringScheduleId
                    )
                    modelContext.insert(item)
                    return item
                }
            }
        }
        
        // Create SwiftData Transaction from API response
        // Normalize type to lowercase to handle API returning "Income"/"Expense"/"Invoice"
        let transaction = Transaction(
            id: response.id,
            amount: response.amount,
            type: TransactionType(rawValue: response.type.lowercased()) ?? .expense,
            dueDate: dueDate,
            transactionDescription: response.description,
            categoryId: response.categoryId,
            status: response.status,
            categoryName: response.categoryName,
            recurringScheduleId: response.recurringScheduleId,
            invoiceItems: invoiceItems
        )
        
        // Set parent invoice for invoice items
        if let items = invoiceItems {
            for item in items {
                item.parentInvoice = transaction
            }
        }
        
        return transaction
    }
    
    /// Syncs transactions from API to SwiftData
    /// - Parameters:
    ///   - modelContext: SwiftData model context to insert/update transactions
    ///   - month: Optional month (1-12) to filter transactions
    ///   - year: Optional year to filter transactions
    func syncTransactions(modelContext: ModelContext, month: Int? = nil, year: Int? = nil) async throws {
        let responses = try await fetchTransactions(month: month, year: year)
        // Fetch existing transactions to check for duplicates and updates
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let existingTransactions = try modelContext.fetch(transactionDescriptor)
        // Use reduce to handle potential duplicate IDs gracefully (keep the first occurrence)
        let existingTransactionsById = existingTransactions.reduce(into: [String: Transaction]()) { dict, transaction in
            if let id = transaction.id {
                // Only add if key doesn't already exist to avoid duplicates
                if dict[id] == nil {
                    dict[id] = transaction
                }
            }
        }

        // Process each transaction response
        for response in responses {
            // Check if transaction already exists
            if let existingTransaction = existingTransactionsById[response.id] {
                // Update all fields from API response to keep local data in sync
                existingTransaction.amount = response.amount
                // Normalize type to lowercase to handle API returning "Income"/"Expense"/"Invoice"
                existingTransaction.transactionType = TransactionType(rawValue: response.type.lowercased()) ?? .expense
                existingTransaction.dueDate = parseDate(response.dueDate) ?? existingTransaction.dueDate
                existingTransaction.transactionDescription = response.description
                existingTransaction.categoryId = response.categoryId
                existingTransaction.status = response.status
                existingTransaction.categoryName = response.categoryName
                existingTransaction.recurringScheduleId = response.recurringScheduleId
                
                // Update invoice items if present
                if let items = response.invoiceItems, !items.isEmpty {
                    let invoiceItems = items.map { itemResponse in
                        // Check if invoice item already exists
                        if let existingItem = existingTransactionsById[itemResponse.id] {
                            // Update existing item
                            existingItem.amount = itemResponse.amount
                            existingItem.transactionType = TransactionType(rawValue: itemResponse.type.lowercased()) ?? .expense
                            existingItem.dueDate = parseDate(itemResponse.dueDate) ?? existingItem.dueDate
                            existingItem.transactionDescription = itemResponse.description
                            existingItem.categoryId = itemResponse.categoryId
                            existingItem.status = itemResponse.status
                            existingItem.categoryName = itemResponse.categoryName
                            existingItem.recurringScheduleId = itemResponse.recurringScheduleId
                            existingItem.parentInvoice = existingTransaction
                            return existingItem
                        } else {
                            // Create new invoice item
                            let itemDueDate = parseDate(itemResponse.dueDate) ?? Date()
                            let item = Transaction(
                                id: itemResponse.id,
                                amount: itemResponse.amount,
                                type: TransactionType(rawValue: itemResponse.type.lowercased()) ?? .expense,
                                dueDate: itemDueDate,
                                transactionDescription: itemResponse.description,
                                categoryId: itemResponse.categoryId,
                                status: itemResponse.status,
                                categoryName: itemResponse.categoryName,
                                recurringScheduleId: itemResponse.recurringScheduleId
                            )
                            item.parentInvoice = existingTransaction
                            modelContext.insert(item)
                            return item
                        }
                    }
                    existingTransaction.invoiceItems = invoiceItems
                } else {
                    // Clear invoice items if not present in response
                    existingTransaction.invoiceItems = nil
                }
                
                continue
            }
            
            // Create new transaction with invoice items
            let transaction = createTransaction(from: response, modelContext: modelContext, existingTransactionsById: existingTransactionsById)
            modelContext.insert(transaction)
        }
        
        // Save all changes (categories and transactions)
        try modelContext.save()
    }
}

