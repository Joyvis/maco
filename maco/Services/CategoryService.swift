//
//  CategoryService.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation

class CategoryService {
    static let shared = CategoryService()
    
    private init() {}
    
    // Mocked categories for initial implementation
    // TODO: Replace with API call when endpoint is available
    private let mockedCategories = [
        "Food",
        "Transportation",
        "Housing",
        "Health",
        "Leisure",
        "Taxes",
        "Shopping",
        "Bills",
        "Education",
        "Income"
    ]
    
    func fetchCategories() async throws -> [CategoryResponse] {
        // TODO: Implement API call when endpoint is available
        // return try await APIService.shared.get(
        //     endpoint: "/transaction_categories",
        //     responseType: [CategoryResponse].self
        // )
        
        // Return mocked data for now
        return mockedCategories.map { name in
            CategoryResponse(
                id: UUID().uuidString,
                name: name,
                parentId: nil,
                isPredefined: true,
                userId: nil
            )
        }
    }
    
    func createCategory(name: String, parentId: String? = nil) async throws -> CategoryResponse {
        let request = CategoryRequest(
            transactionCategory: CategoryRequest.CategoryAttributes(
                name: name,
                parentId: parentId
            )
        )
        
        // TODO: Uncomment when API is ready
        // return try await APIService.shared.post(
        //     endpoint: "/transaction_categories",
        //     body: request,
        //     responseType: CategoryResponse.self
        // )
        
        // Mock response for now
        return CategoryResponse(
            id: UUID().uuidString,
            name: name,
            parentId: parentId,
            isPredefined: false,
            userId: nil
        )
    }
}

