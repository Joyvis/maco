//
//  PaymentMethodRowView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct PaymentMethodRowView: View {
    let paymentMethod: PaymentMethod
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(paymentMethod.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrency(paymentMethod.initialBalance))
                    .font(.headline)
            }
            
            HStack {
                Text(paymentMethod.paymentMethodType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        PaymentMethodRowView(
            paymentMethod: PaymentMethod(
                name: "Checking Account",
                type: .debitAccount,
                initialBalance: 1250.50
            )
        )
        PaymentMethodRowView(
            paymentMethod: PaymentMethod(
                name: "Credit Card",
                type: .creditAccount,
                initialBalance: -500.00
            )
        )
    }
}
