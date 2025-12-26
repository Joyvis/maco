//
//  PaymentMethod.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import SwiftData

enum PaymentMethodType: String, Codable {
    case creditAccount = "CreditAccount"
    case debitAccount = "DebitAccount"
    
    var displayName: String {
        switch self {
        case .creditAccount:
            return "Credit Account"
        case .debitAccount:
            return "Debit Account"
        }
    }
}

@Model
final class PaymentMethod {
    var id: String?
    var name: String
    var type: String
    var initialBalance: Double
    
    init(id: String? = nil, name: String, type: PaymentMethodType, initialBalance: Double = 0.0) {
        self.id = id
        self.name = name
        self.type = type.rawValue
        self.initialBalance = initialBalance
    }
    
    var paymentMethodType: PaymentMethodType {
        get {
            PaymentMethodType(rawValue: type) ?? .debitAccount
        }
        set {
            type = newValue.rawValue
        }
    }
}

// MARK: - API Models

struct PaymentMethodRequest: Codable {
    let paymentMethod: PaymentMethodAttributes
    
    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
    }
    
    struct PaymentMethodAttributes: Codable {
        let name: String
        let type: String
        let initialBalance: Double
        
        enum CodingKeys: String, CodingKey {
            case name
            case type
            case initialBalance = "initial_balance"
        }
    }
}

struct PaymentMethodResponse: Codable {
    let id: String
    let name: String
    let type: String?
    let initialBalance: Double?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case initialBalance = "initial_balance"
        case balance
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // Handle both "initial_balance" and "balance" fields
        if let initialBalanceValue = try? container.decodeIfPresent(Double.self, forKey: .initialBalance) {
            initialBalance = initialBalanceValue
        } else if let balanceValue = try? container.decodeIfPresent(Double.self, forKey: .balance) {
            initialBalance = balanceValue
        } else {
            initialBalance = nil
        }
        
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(initialBalance, forKey: .initialBalance)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

