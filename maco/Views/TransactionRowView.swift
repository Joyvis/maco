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
                        if !transaction.displayStatus.isEmpty {
                            Text(transaction.displayStatus.uppercased())
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(transaction.statusColor)
                                .cornerRadius(4)
                        }
                    }

                    if transaction.transactionType == .expense || transaction.transactionType == .invoice {
                        if !transaction.displayStatus.isEmpty && transaction.transactionType == .expense {
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

