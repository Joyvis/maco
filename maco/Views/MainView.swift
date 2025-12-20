//
//  MainView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedPage: AppPage = .transactions
    @State private var isMenuOpen: Bool = false
    
    var body: some View {
        ZStack {
            // Current page content
            Group {
                switch selectedPage {
                case .transactions:
                    TransactionsPageView(isMenuOpen: $isMenuOpen)
                case .categories:
                    CategoriesPageView(isMenuOpen: $isMenuOpen)
                case .paymentMethods:
                    PaymentMethodsPageView(isMenuOpen: $isMenuOpen)
                }
            }
            
            // Sidebar menu overlay
            SidebarMenu(
                isOpen: $isMenuOpen,
                selectedPage: $selectedPage,
                onPageSelected: { page in
                    selectedPage = page
                }
            )
        }
    }
}

// MARK: - Categories Page View (Placeholder)

struct CategoriesPageView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        PageLayout(
            title: "Categories",
            isMenuOpen: $isMenuOpen,
            content: {
                List {
                    Text("Categories page - Coming soon")
                        .foregroundColor(.secondary)
                }
            }
        )
    }
}

// MARK: - Payment Methods Page View (Placeholder)

struct PaymentMethodsPageView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        PageLayout(
            title: "Payment Methods",
            isMenuOpen: $isMenuOpen,
            content: {
                List {
                    Text("Payment Methods page - Coming soon")
                        .foregroundColor(.secondary)
                }
            }
        )
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

