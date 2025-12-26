//
//  PaymentMethodService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation

class PaymentMethodService {
    static let shared = PaymentMethodService()
    
    private init() {}
    
    func fetchPaymentMethods() async throws -> [PaymentMethodResponse] {
        return try await APIService.shared.get(
            endpoint: "/payment_methods",
            responseType: [PaymentMethodResponse].self
        )
    }
}

