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
        return try await APIService.shared.get(
            endpoint: "/transaction_categories",
            responseType: [CategoryResponse].self
        )
    }
    
    func fetchCategories(filterByName: String?) async throws -> [CategoryResponse] {
        var queryParameters: [String: String]? = nil
        
        // Only add name filter if provided and has at least 3 characters
        if let filterName = filterByName, filterName.count >= 3 {
            queryParameters = ["name": filterName]
        }
        
        return try await APIService.shared.get(
            endpoint: "/transaction_categories",
            queryParameters: queryParameters,
            responseType: [CategoryResponse].self
        )
    }
    
    func createCategory(name: String, parentId: String? = nil) async throws -> CategoryResponse {
        let request = CategoryRequest(
            transactionCategory: CategoryRequest.CategoryAttributes(
                name: name,
                parentId: parentId
            )
        )
        
        return try await APIService.shared.post(
            endpoint: "/transaction_categories",
            body: request,
            responseType: CategoryResponse.self
        )
    }
}

