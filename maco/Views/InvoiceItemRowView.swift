//
//  InvoiceItemRowView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct InvoiceItemRowView: View {
    let transaction: Transaction
    let onTap: (Transaction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.transactionDescription)
                    .font(.subheadline)
                Spacer()
                Text(transaction.formattedAmount)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            HStack {
                if !transaction.displayStatus.isEmpty {
                    Text(transaction.displayStatus.uppercased())
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(transaction.statusColor)
                        .cornerRadius(4)
                }
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(transaction.displayCategoryName)
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

