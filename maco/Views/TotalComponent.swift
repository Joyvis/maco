//
//  TotalComponent.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct TotalComponent: View {
    let pendingTotal: Double
    let totalAmount: Double
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: amount)) ?? "R$ 0,00"
    }
    
    var body: some View {
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

#Preview {
    List {
        TotalComponent(pendingTotal: -100.0, totalAmount: 500.0)
    }
}

