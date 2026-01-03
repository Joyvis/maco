//
//  PaymentMethodService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import SwiftData

class PaymentMethodService {
    static let shared = PaymentMethodService()
    
    private init() {}
    
    func fetchPaymentMethods() async throws -> [PaymentMethodResponse] {
        return try await APIService.shared.get(
            endpoint: "/payment_methods",
            responseType: [PaymentMethodResponse].self
        )
    }
    
    func createPaymentMethod(name: String, type: PaymentMethodType, initialBalance: Double, dueDay: Int? = nil) async throws -> PaymentMethodResponse {
        let request = PaymentMethodRequest(
            paymentMethod: PaymentMethodRequest.PaymentMethodAttributes(
                name: name,
                type: type.rawValue,
                initialBalance: initialBalance,
                dueDay: dueDay
            )
        )
        
        return try await APIService.shared.post(
            endpoint: "/payment_methods",
            body: request,
            responseType: PaymentMethodResponse.self
        )
    }
    
    func updatePaymentMethod(id: String, name: String, type: PaymentMethodType, dueDay: Int? = nil) async throws -> PaymentMethodResponse {
        let request = PaymentMethodUpdateRequest(
            paymentMethod: PaymentMethodUpdateRequest.PaymentMethodUpdateAttributes(
                name: name,
                type: type.rawValue,
                dueDay: dueDay
            )
        )
        
        return try await APIService.shared.patch(
            endpoint: "/payment_methods/\(id)",
            body: request,
            responseType: PaymentMethodResponse.self
        )
    }
    
    /// Syncs payment methods from API to SwiftData
    /// - Parameter modelContext: SwiftData model context to insert/update payment methods
    func syncPaymentMethods(modelContext: ModelContext) async throws {
        let responses = try await fetchPaymentMethods()
        
        // Collect all payment method IDs from API response
        let apiPaymentMethodIds = Set(responses.map { $0.id })
        
        // Fetch existing payment methods
        let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>()
        let existingPaymentMethods = try modelContext.fetch(paymentMethodDescriptor)
        
        // Create dictionary of existing payment methods by ID
        let existingPaymentMethodsById = existingPaymentMethods.reduce(into: [String: PaymentMethod]()) { dict, paymentMethod in
            if let id = paymentMethod.id {
                if dict[id] == nil {
                    dict[id] = paymentMethod
                }
            }
        }
        
        // Delete local payment methods that are not in the API response
        var paymentMethodsToDelete: [PaymentMethod] = []
        for paymentMethod in existingPaymentMethods {
            guard let paymentMethodId = paymentMethod.id else { continue }
            if !apiPaymentMethodIds.contains(paymentMethodId) {
                paymentMethodsToDelete.append(paymentMethod)
            }
        }
        
        for paymentMethod in paymentMethodsToDelete {
            modelContext.delete(paymentMethod)
        }
        
        // Process each payment method response
        for response in responses {
            if let existingPaymentMethod = existingPaymentMethodsById[response.id] {
                // Update existing payment method
                existingPaymentMethod.name = response.name
                if let typeString = response.type, let type = PaymentMethodType(rawValue: typeString) {
                    existingPaymentMethod.paymentMethodType = type
                }
                if let initialBalance = response.initialBalance {
                    existingPaymentMethod.initialBalance = initialBalance
                }
                existingPaymentMethod.dueDay = response.dueDay
            } else {
                // Create new payment method
                let type = PaymentMethodType(rawValue: response.type ?? PaymentMethodType.debitAccount.rawValue) ?? .debitAccount
                let initialBalance = response.initialBalance ?? 0.0
                let paymentMethod = PaymentMethod(
                    id: response.id,
                    name: response.name,
                    type: type,
                    initialBalance: initialBalance,
                    dueDay: response.dueDay
                )
                modelContext.insert(paymentMethod)
            }
        }
        
        // Save all changes
        try modelContext.save()
    }
}

