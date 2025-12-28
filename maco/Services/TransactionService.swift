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
        status: String?,
        paymentMethodId: String?
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
                status: status,
                paymentMethodId: paymentMethodId,
                paidAt: nil
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
        status: String?,
        paymentMethodId: String?,
        paidAt: Date?
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
                status: status,
                paymentMethodId: paymentMethodId,
                paidAt: paidAt != nil ? dateFormatter.string(from: paidAt!) : nil
            )
        )
        
        return try await APIService.shared.patch(
            endpoint: "/transactions/\(id)",
            body: request,
            responseType: TransactionResponse.self
        )
    }
    
    func fetchTransactions(filters: FilterSet? = nil) async throws -> [TransactionResponse] {
        // Try to decode as wrapper response first, fallback to array
        do {
            let wrapperResponse = try await APIService.shared.get(
                endpoint: "/transactions",
                filters: filters,
                responseType: TransactionsListResponse.self
            )
            return wrapperResponse.transactions
        } catch {
            // Fallback to direct array response if wrapper decoding fails
            return try await APIService.shared.get(
                endpoint: "/transactions",
                filters: filters,
                responseType: [TransactionResponse].self
            )
        }
    }
    
    func deleteTransaction(id: String) async throws {
        try await APIService.shared.delete(endpoint: "/transactions/\(id)")
    }
    
    // MARK: - Monthly Summary
    
    /// Summary data returned from monthly_summary endpoint
    struct MonthlySummary {
        let transactions: [TransactionResponse]
        let total: String
        let pending: String
    }
    
    /// Fetches monthly summary from the API
    /// - Parameter filters: Optional FilterSet to filter transactions (e.g., month/year, category, payment method)
    /// - Returns: MonthlySummary containing transactions, total, and pending
    func fetchMonthlySummary(filters: FilterSet? = nil) async throws -> MonthlySummary {
        let response = try await APIService.shared.get(
            endpoint: "/transactions/monthly_summary",
            filters: filters,
            responseType: TransactionsListResponse.self
        )
        return MonthlySummary(
            transactions: response.transactions,
            total: response.total,
            pending: response.pending
        )
    }
    
    // MARK: - Sync Methods
    
    /// Parses ISO8601 date string to Date
    /// Handles both date-only format (YYYY-MM-DD) and full datetime format
    private func parseDate(_ dateString: String) -> Date? {
        // First try parsing as date-only format (YYYY-MM-DD)
        // Use local timezone so "2025-12-25" means Dec 25 in user's timezone
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone.current
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }
        
        // Fall back to ISO8601 datetime format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: dateString)
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
                    existingItem.paymentMethodId = itemResponse.paymentMethodId
                    existingItem.paymentMethodName = itemResponse.paymentMethodName
                    existingItem.recurringScheduleId = itemResponse.recurringScheduleId
                    existingItem.paidAt = parseDate(itemResponse.paidAt ?? "")
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
                        paymentMethodId: itemResponse.paymentMethodId,
                        paymentMethodName: itemResponse.paymentMethodName,
                        recurringScheduleId: itemResponse.recurringScheduleId,
                        paidAt: parseDate(itemResponse.paidAt ?? "")
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
            paymentMethodId: response.paymentMethodId,
            paymentMethodName: response.paymentMethodName,
            recurringScheduleId: response.recurringScheduleId,
            invoiceItems: invoiceItems,
            paidAt: parseDate(response.paidAt ?? "")
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
    ///   - filters: Optional FilterSet to filter transactions (e.g., month/year, category, payment method)
    /// - Returns: MonthlySummary containing total and pending values from the API
    func syncTransactions(modelContext: ModelContext, filters: FilterSet? = nil) async throws -> MonthlySummary {
        let summary = try await fetchMonthlySummary(filters: filters)
        let responses = summary.transactions
        
        // Collect all transaction IDs from API response (including invoice items)
        var apiTransactionIds = Set<String>()
        for response in responses {
            apiTransactionIds.insert(response.id)
            if let invoiceItems = response.invoiceItems {
                for item in invoiceItems {
                    apiTransactionIds.insert(item.id)
                }
            }
        }
        
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
        
        // Clean up: Delete local transactions that have IDs but are not in the API response
        // Note: When filters are applied, only transactions matching the filter scope are cleaned up.
        // To clean up ALL stale data, sync without filters.
        let calendar = Calendar.current
        var transactionsToDelete: [Transaction] = []
        
        for transaction in existingTransactions {
            // Only delete transactions that have IDs (skip local-only transactions)
            guard let transactionId = transaction.id else { continue }
            
            // Skip if transaction is in the API response
            if apiTransactionIds.contains(transactionId) { continue }
            
            // If filters are applied, only delete transactions that match the filter scope
            if let monthYearFilter = filters?.monthYearFilter {
                let isPaid = transaction.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "paid"
                let transactionDate = isPaid && transaction.paidAt != nil ? transaction.paidAt! : transaction.dueDate
                let transactionMonth = calendar.component(.month, from: transactionDate)
                let transactionYear = calendar.component(.year, from: transactionDate)
                
                // Only delete if transaction matches the filter
                if transactionMonth == monthYearFilter.month && transactionYear == monthYearFilter.year {
                    transactionsToDelete.append(transaction)
                }
            } else {
                // No filter: delete all transactions not in API response
                transactionsToDelete.append(transaction)
            }
        }
        
        // Delete transactions (cascade delete will handle invoice items automatically)
        for transaction in transactionsToDelete {
            modelContext.delete(transaction)
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
                existingTransaction.paymentMethodId = response.paymentMethodId
                existingTransaction.paymentMethodName = response.paymentMethodName
                existingTransaction.recurringScheduleId = response.recurringScheduleId
                existingTransaction.paidAt = parseDate(response.paidAt ?? "")
                
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
                            existingItem.paymentMethodId = itemResponse.paymentMethodId
                            existingItem.paymentMethodName = itemResponse.paymentMethodName
                            existingItem.recurringScheduleId = itemResponse.recurringScheduleId
                            existingItem.paidAt = parseDate(itemResponse.paidAt ?? "")
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
                                paymentMethodId: itemResponse.paymentMethodId,
                                paymentMethodName: itemResponse.paymentMethodName,
                                recurringScheduleId: itemResponse.recurringScheduleId,
                                paidAt: parseDate(itemResponse.paidAt ?? "")
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
        
        return summary
    }
}

