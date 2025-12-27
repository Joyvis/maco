//
//  TransactionRowView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

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
            return transaction.displayCategoryName
        }
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

                    Text(transaction.formattedAmount)
                        .font(.headline)
                        .foregroundColor(transaction.transactionType == .income ? .green : .red)
                }

                HStack {
                    if transaction.transactionType != .income {
                        // Status badge with smart text
                        Text(transaction.badgeText)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(transaction.badgeColor)
                            .cornerRadius(4)
                        
                        // Only show separator if there's a category to display
                        if (transaction.transactionType == .expense || transaction.transactionType == .invoice) && !categoryName.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                        }
                    }

                    if transaction.transactionType == .expense || transaction.transactionType == .invoice {
                        if !categoryName.isEmpty {
                            Text(categoryName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Due date label (always shown for expenses, received date for income)
                    if transaction.transactionType == .income {
                        Text("Received: \(transaction.formattedDueDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Due: \(transaction.formattedDueDate)")
                            .font(.caption)
                            .foregroundColor(transaction.isOverdue ? .red : .secondary)
                    }
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

