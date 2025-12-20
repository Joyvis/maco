//
//  TransactionsPageView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct TransactionsPageView: View {
    @Binding var isMenuOpen: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.createdAt, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]

    @State private var showTransactionForm: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var transactionToDelete: Transaction? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    
    // Month picker state
    private let calendar = Calendar.current
    @State private var selectedMonth: Int = {
        let now = Date()
        return Calendar.current.component(.month, from: now)
    }()
    @State private var selectedYear: Int = {
        let now = Date()
        return Calendar.current.component(.year, from: now)
    }()

    // Filter out invoice items (they're children of Invoice transactions)
    private var topLevelTransactions: [Transaction] {
        transactions.filter { $0.parentInvoice == nil }
    }
    
    private var pendingTotal: Double {
        topLevelTransactions
            .filter { ($0.status ?? "").lowercased() == "pending" }
            .compactMap { transaction -> (Double, TransactionType)? in
                guard let amount = Double(transaction.amount) else { return nil }
                return (amount, transaction.transactionType)
            }
            .reduce(0) { result, item in
                switch item.1 {
                case .income:
                    return result + item.0
                case .expense, .invoice:
                    return result - item.0
                }
            }
    }
    
    private var totalAmount: Double {
        topLevelTransactions
            .compactMap { transaction -> (Double, TransactionType)? in
                guard let amount = Double(transaction.amount) else { return nil }
                return (amount, transaction.transactionType)
            }
            .reduce(0) { result, item in
                switch item.1 {
                case .income:
                    return result + item.0
                case .expense, .invoice:
                    return result - item.0
                }
            }
    }
    
    var body: some View {
        PageLayout(
            title: "Transactions",
            isMenuOpen: $isMenuOpen,
            content: {
                List {
                    ForEach(topLevelTransactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            categories: categories,
                            onTap: { tappedTransaction in
                                transactionToEdit = tappedTransaction
                                showTransactionForm = true
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                transactionToDelete = transaction
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Total component as footer section
                    Section {
                        TotalComponent(
                            pendingTotal: pendingTotal,
                            totalAmount: totalAmount
                        )
                    }
                }
                .refreshable {
                    await syncTransactions()
                }
            },
            addButton: AnyView(
                Button(action: {
                    transactionToEdit = nil
                    showTransactionForm = true
                }) {
                    Label("Add Transaction", systemImage: "plus")
                }
            ),
            monthPicker: AnyView(
                MonthPickerView(
                    initialMonth: selectedMonth,
                    initialYear: selectedYear,
                    onMonthSelected: { month, year in
                        selectedMonth = month
                        selectedYear = year
                        Task {
                            await syncTransactions()
                        }
                    }
                )
            )
        )
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(transaction: transactionToEdit)
        }
        .onChange(of: showTransactionForm) { oldValue, newValue in
            if !newValue {
                transactionToEdit = nil
            }
        }
        .alert("Delete Transaction", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                transactionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    performDeleteTransaction(transaction)
                }
                transactionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .task {
            await syncTransactions()
        }
    }

    private func performDeleteTransaction(_ transaction: Transaction) {
        Task {
            // Delete from API if transaction has an ID
            if let transactionId = transaction.id {
                do {
                    try await TransactionService.shared.deleteTransaction(id: transactionId)
                } catch {
                    errorMessage = "Failed to delete transaction: \(error.localizedDescription)"
                    return
                }
            }
            
            // Delete from SwiftData
            withAnimation {
                modelContext.delete(transaction)
            }
        }
    }
    
    private func syncTransactions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await TransactionService.shared.syncTransactions(
                modelContext: modelContext,
                month: selectedMonth,
                year: selectedYear
            )
        } catch {
            errorMessage = "Failed to sync transactions: \(error.localizedDescription)"
        }
    }
}

