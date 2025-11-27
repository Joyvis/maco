//
//  TransactionService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation

class TransactionService {
    static let shared = TransactionService()
    
    private init() {}
    
    func createTransaction(
        amount: String,
        type: TransactionType,
        dueDate: Date,
        description: String,
        categoryId: String?
    ) async throws -> TransactionResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = TransactionRequest(
            transaction: TransactionRequest.TransactionAttributes(
                amount: amount,
                type: type.rawValue,
                dueDate: dateFormatter.string(from: dueDate),
                description: description,
                categoryId: categoryId
            )
        )
        
        // TODO: Uncomment when API is ready
         return try await APIService.shared.post(
             endpoint: "/transactions",
             body: request,
             responseType: TransactionResponse.self
         )
        
        // Mock response for now
//        return TransactionResponse(
//            id: UUID().uuidString,
//            amount: amount,
//            type: type.rawValue,
//            dueDate: dateFormatter.string(from: dueDate),
//            description: description,
//            categoryId: categoryId,
//            recurringScheduleId: nil
//        )
    }
    
    func fetchTransactions() async throws -> [TransactionResponse] {
        // TODO: Implement API call when endpoint is available
        // return try await APIService.shared.get(
        //     endpoint: "/transactions",
        //     responseType: [TransactionResponse].self
        // )
        
        // Return empty array for now
        return []
    }
}

