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

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    TransactionRowView(transaction: transaction, categories: categories)
                }
                .onDelete(perform: deleteTransactions)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        showTransactionForm = true
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showTransactionForm) {
                TransactionFormView()
            }
        }
    }

    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(transactions[index])
            }
        }
    }
}

// MARK: - Transaction Row View

struct TransactionRowView: View {
    let transaction: Transaction
    let categories: [Category]
    
    private var categoryName: String {
        guard let categoryId = transaction.categoryId else {
            return "Uncategorized"
        }
        return categories.first(where: { $0.id == categoryId })?.name ?? "Unknown"
    }
    
    private var formattedAmount: String {
        if let amount = Double(transaction.amount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
