//
//  PaymentMethodFormView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct PaymentMethodFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let paymentMethod: PaymentMethod?
    
    @State private var name: String = ""
    @State private var selectedType: PaymentMethodType = .debitAccount
    @State private var initialBalance: String = "0.00"
    @State private var dueDay: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    private var isEditMode: Bool {
        paymentMethod != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Method Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach([PaymentMethodType.debitAccount, PaymentMethodType.creditAccount], id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    if selectedType == .creditAccount {
                        HStack {
                            Text("Due Day")
                            Spacer()
                            TextField("1-28", text: $dueDay)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                    
                    if !isEditMode {
                        HStack {
                            Text("Initial Balance")
                            Spacer()
                            TextField("0.00", text: $initialBalance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Payment Method" : "New Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await savePaymentMethod()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .task {
                if let paymentMethod = paymentMethod {
                    prefillForm(with: paymentMethod)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let nameValid = !name.isEmpty && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if selectedType == .creditAccount {
            guard let dueDayInt = Int(dueDay.trimmingCharacters(in: .whitespacesAndNewlines)),
                  dueDayInt >= 1 && dueDayInt <= 28 else {
                return false
            }
            return nameValid
        }
        
        return nameValid
    }
    
    private func prefillForm(with paymentMethod: PaymentMethod) {
        name = paymentMethod.name
        selectedType = paymentMethod.paymentMethodType
        if let dueDayValue = paymentMethod.dueDay {
            dueDay = String(dueDayValue)
        } else {
            dueDay = ""
        }
        // initialBalance is not prefilled for edit mode (not shown in form)
    }
    
    private func savePaymentMethod() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response: PaymentMethodResponse
            
            if let existingPaymentMethod = paymentMethod, let paymentMethodId = existingPaymentMethod.id {
                // Update existing payment method
                let dueDayValue: Int? = selectedType == .creditAccount ? Int(dueDay.trimmingCharacters(in: .whitespacesAndNewlines)) : nil
                response = try await PaymentMethodService.shared.updatePaymentMethod(
                    id: paymentMethodId,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: selectedType,
                    dueDay: dueDayValue
                )
                
                // Update SwiftData model
                existingPaymentMethod.name = response.name
                if let typeString = response.type, let type = PaymentMethodType(rawValue: typeString) {
                    existingPaymentMethod.paymentMethodType = type
                }
                existingPaymentMethod.dueDay = response.dueDay
                // initialBalance is not updated in edit mode
                
                try modelContext.save()
            } else {
                // Create new payment method
                let initialBalanceValue = Double(initialBalance) ?? 0.0
                let dueDayValue: Int? = selectedType == .creditAccount ? Int(dueDay.trimmingCharacters(in: .whitespacesAndNewlines)) : nil
                response = try await PaymentMethodService.shared.createPaymentMethod(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: selectedType,
                    initialBalance: initialBalanceValue,
                    dueDay: dueDayValue
                )
                
                // Save to SwiftData
                let type = PaymentMethodType(rawValue: response.type ?? PaymentMethodType.debitAccount.rawValue) ?? .debitAccount
                let initialBalance = response.initialBalance ?? 0.0
                let newPaymentMethod = PaymentMethod(
                    id: response.id,
                    name: response.name,
                    type: type,
                    initialBalance: initialBalance,
                    dueDay: response.dueDay
                )
                modelContext.insert(newPaymentMethod)
                try modelContext.save()
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to save payment method: \(error.localizedDescription)"
        }
    }
}

#Preview {
    PaymentMethodFormView(paymentMethod: nil)
        .modelContainer(for: [PaymentMethod.self], inMemory: true)
}
