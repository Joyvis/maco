//
//  MarkAsPaidView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct MarkAsPaidView: View {
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    let onMarkAsPaid: (Date?) -> Void
    
    @State private var selectedDate: Date = Date()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    private var isPaid: Bool {
        transaction.isPaid
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(
                        "Paid Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Select the date when this transaction was paid")
                } footer: {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if isPaid {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await handleUnmarkAsPaid()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Unmark as Paid")
                                Spacer()
                            }
                        }
                        .disabled(isLoading)
                    } footer: {
                        Text("This will remove the paid status from the transaction")
                    }
                }
            }
            .navigationTitle(isPaid ? "Update Paid Date" : "Mark as Paid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await handleMarkAsPaid()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                // Set default date to today or existing paidAt date if already paid
                if isPaid, let paidAt = transaction.paidAt {
                    selectedDate = paidAt
                } else {
                    selectedDate = Date()
                }
            }
        }
    }
    
    private func handleMarkAsPaid() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        onMarkAsPaid(selectedDate)
        dismiss()
    }
    
    private func handleUnmarkAsPaid() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        onMarkAsPaid(nil)
        dismiss()
    }
}

#Preview {
    MarkAsPaidView(
        transaction: Transaction(
            amount: "100.00",
            type: .expense,
            dueDate: Date(),
            transactionDescription: "Test Transaction"
        ),
        onMarkAsPaid: { _ in }
    )
}

