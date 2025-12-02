//
//  ContentView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.createdAt, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var showTransactionForm: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var transactionToDelete: Transaction? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var transactionToEdit: Transaction? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        categories: categories,
                        onTap: {
                            transactionToEdit = transaction
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
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        transactionToEdit = nil
                        showTransactionForm = true
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
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
            .refreshable {
                await syncTransactions()
            }
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
            try await TransactionService.shared.syncTransactions(modelContext: modelContext)
        } catch {
            errorMessage = "Failed to sync transactions: \(error.localizedDescription)"
        }
    }
}

// MARK: - Transaction Row View

struct TransactionRowView: View {
    let transaction: Transaction
    let categories: [Category]
    let onTap: () -> Void
    
    private var categoryName: String {
        transaction.categoryName ?? "Uncategorized"
    }
    
    private var formattedAmount: String {
        if let amount = Double(transaction.amount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "BRL"
            return formatter.string(from: NSNumber(value: amount)) ?? transaction.amount
        }
        return transaction.amount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.transactionDescription)
                    .font(.headline)
                Spacer()
                Text(formattedAmount)
                    .font(.headline)
                    .foregroundColor(transaction.transactionType == .income ? .green : .red)
            }
            
            HStack {
                Label(transaction.transactionType.displayName, systemImage: transaction.transactionType == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(transaction.dueDate, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
