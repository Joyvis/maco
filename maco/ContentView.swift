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
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: amount)) ?? "R$ 0,00"
    }
    
    var body: some View {
        NavigationStack {
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
                
                // Summary footer
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("PENDING:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(pendingTotal))
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        
                        HStack {
                            Text("TOTAL:")
                                .font(.headline)
                            Spacer()
                            Text(formatCurrency(totalAmount))
                                .font(.headline)
                                .foregroundColor(totalAmount >= 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
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
    let onTap: (Transaction) -> Void
    
    @State private var isExpanded: Bool = false
    
    private var isInvoice: Bool {
        transaction.transactionType == .invoice
    }
    
    private var hasInvoiceItems: Bool {
        guard let items = transaction.invoiceItems else { return false }
        return !items.isEmpty
    }
    
    private var categoryName: String {
        if transaction.transactionType == .income {
            return ""
        } else {
            return transaction.categoryName ?? "Uncategorized"
        }
    }

    private var status: String {
        return transaction.status ?? ""
    }

    private var statusColor: Color {
        switch transaction.status {
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
        VStack(alignment: .leading, spacing: 0) {
            // Main transaction row
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.transactionDescription)
                        .font(.headline)
                    Spacer()
                    
                    if isInvoice && hasInvoiceItems {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    
                    Text(formattedAmount)
                        .font(.headline)
                        .foregroundColor(transaction.transactionType == .income ? .green : .red)
                }

                HStack {
                    if transaction.transactionType != .income {
                        if !status.isEmpty {
                            Text(status.uppercased())
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor)
                                .cornerRadius(4)
                        }
                    }

                    if transaction.transactionType == .expense || transaction.transactionType == .invoice {
                        if !status.isEmpty && transaction.transactionType == .expense {
                            Text("•")
                                .foregroundColor(.secondary)
                        }

                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(transaction.dueDate, format: .dateTime.month().day().year())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if isInvoice && hasInvoiceItems {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } else {
                    onTap(transaction)
                }
            }
            
            // Invoice items (expanded)
            if isExpanded && isInvoice, let invoiceItems = transaction.invoiceItems, !invoiceItems.isEmpty {
                ForEach(invoiceItems) { item in
                    InvoiceItemRowView(
                        transaction: item,
                        onTap: { tappedItem in
                            onTap(tappedItem)
                        }
                    )
                    .padding(.leading, 16)
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

// MARK: - Invoice Item Row View

struct InvoiceItemRowView: View {
    let transaction: Transaction
    let onTap: (Transaction) -> Void
    
    private var categoryName: String {
        return transaction.categoryName ?? "Uncategorized"
    }
    
    private var status: String {
        return transaction.status ?? ""
    }
    
    private var statusColor: Color {
        switch transaction.status {
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
                    .font(.subheadline)
                Spacer()
                Text(formattedAmount)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            HStack {
                if !status.isEmpty {
                    Text(status.uppercased())
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .cornerRadius(4)
                }
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(categoryName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(transaction.dueDate, format: .dateTime.month().day().year())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(transaction)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
