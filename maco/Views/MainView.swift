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

// MARK: - Payment Methods Page View

struct PaymentMethodsPageView: View {
    @Binding var isMenuOpen: Bool
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PaymentMethod.name) private var paymentMethods: [PaymentMethod]
    
    @State private var showPaymentMethodForm: Bool = false
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        PageLayout(
            title: "Payment Methods",
            isMenuOpen: $isMenuOpen,
            content: {
                List {
                    if paymentMethods.isEmpty {
                        Text("No payment methods")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(paymentMethods) { paymentMethod in
                            NavigationLink(destination: PaymentMethodShowPageView(paymentMethod: paymentMethod)) {
                                PaymentMethodRowView(paymentMethod: paymentMethod)
                            }
                        }
                    }
                }
                .refreshable {
                    await syncPaymentMethods()
                }
            },
            addButton: AnyView(
                Button(action: {
                    showPaymentMethodForm = true
                }) {
                    Label("Add Payment Method", systemImage: "plus")
                }
            )
        )
        .sheet(isPresented: $showPaymentMethodForm) {
            PaymentMethodFormView(paymentMethod: nil)
        }
        .task {
            await syncPaymentMethods()
        }
    }
    
    private func syncPaymentMethods() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await PaymentMethodService.shared.syncPaymentMethods(modelContext: modelContext)
        } catch {
            errorMessage = "Failed to sync payment methods: \(error.localizedDescription)"
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self], inMemory: true)
}

