//
//  QueryFilter.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import Foundation
import Combine

// MARK: - QueryFilter Protocol

protocol QueryFilter {
    func toQueryParameters() -> [String: String]
}

// MARK: - MonthYearFilter

struct MonthYearFilter: QueryFilter {
    let month: Int
    let year: Int
    
    func toQueryParameters() -> [String: String] {
        return [
            "month": String(month),
            "year": String(year)
        ]
    }
}

// MARK: - CategoryFilter

struct CategoryFilter: QueryFilter {
    let categoryId: String
    
    func toQueryParameters() -> [String: String] {
        return [
            "category_id": categoryId
        ]
    }
}

// MARK: - PaymentMethodFilter

struct PaymentMethodFilter: QueryFilter {
    let paymentMethodId: String
    
    func toQueryParameters() -> [String: String] {
        return [
            "payment_method_id": paymentMethodId
        ]
    }
}

// MARK: - FilterSet

class FilterSet: ObservableObject {
    @Published var monthYearFilter: MonthYearFilter?
    @Published var categoryFilter: CategoryFilter?
    @Published var paymentMethodFilter: PaymentMethodFilter?
    
    init(
        monthYearFilter: MonthYearFilter? = nil,
        categoryFilter: CategoryFilter? = nil,
        paymentMethodFilter: PaymentMethodFilter? = nil
    ) {
        self.monthYearFilter = monthYearFilter
        self.categoryFilter = categoryFilter
        self.paymentMethodFilter = paymentMethodFilter
    }
    
    func toQueryParameters() -> [String: String] {
        var queryParams: [String: String] = [:]
        
        if let monthYear = monthYearFilter {
            queryParams.merge(monthYear.toQueryParameters()) { (_, new) in new }
        }
        
        if let category = categoryFilter {
            queryParams.merge(category.toQueryParameters()) { (_, new) in new }
        }
        
        if let paymentMethod = paymentMethodFilter {
            queryParams.merge(paymentMethod.toQueryParameters()) { (_, new) in new }
        }
        
        return queryParams.isEmpty ? [:] : queryParams
    }
    
    func clear() {
        monthYearFilter = nil
        categoryFilter = nil
        paymentMethodFilter = nil
    }
    
    func hasFilters() -> Bool {
        return monthYearFilter != nil || categoryFilter != nil || paymentMethodFilter != nil
    }
}

