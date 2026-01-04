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
        // Format month as two-digit zero-padded string (e.g., "01" instead of "1")
        let monthString = String(format: "%02d", month)
        return [
            "q[paid_at_month_eq]": monthString,
            "q[paid_at_year_eq]": String(year)
        ]
    }
}

// MARK: - CategoryFilter

struct CategoryFilter: QueryFilter {
    let categoryId: String
    
    func toQueryParameters() -> [String: String] {
        return [
            "q[category_id_eq]": categoryId
        ]
    }
}

// MARK: - PaymentMethodFilter

struct PaymentMethodFilter: QueryFilter {
    let paymentMethodId: String
    
    func toQueryParameters() -> [String: String] {
        return [
            "q[payment_method_id_eq]": paymentMethodId
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

