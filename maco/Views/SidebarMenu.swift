//
//  SidebarMenu.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

enum AppPage: String, CaseIterable {
    case transactions = "Transactions"
    case categories = "Categories"
    case paymentMethods = "Payment Methods"
    
    var icon: String {
        switch self {
        case .transactions:
            return "list.bullet"
        case .categories:
            return "folder"
        case .paymentMethods:
            return "creditcard"
        }
    }
}

struct SidebarMenu: View {
    @Binding var isOpen: Bool
    @Binding var selectedPage: AppPage
    let onPageSelected: (AppPage) -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            if isOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isOpen = false
                        }
                    }
            }
            
            // Sidebar
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Menu")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isOpen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .padding()
                        }
                    }
                    
                    Divider()
                    
                    // Menu items
                    ForEach(AppPage.allCases, id: \.self) { page in
                        Button(action: {
                            selectedPage = page
                            onPageSelected(page)
                            withAnimation {
                                isOpen = false
                            }
                        }) {
                            HStack {
                                Image(systemName: page.icon)
                                    .frame(width: 24)
                                Text(page.rawValue)
                                    .font(.body)
                                Spacer()
                            }
                            .foregroundColor(selectedPage == page ? .accentColor : .primary)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(selectedPage == page ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    
                    Spacer()
                }
                .frame(width: 280)
                .background(Color(.systemBackground))
                .shadow(radius: 5)
                
                Spacer()
            }
            .offset(x: isOpen ? 0 : -280)
            .animation(.easeInOut(duration: 0.3), value: isOpen)
        }
    }
}

#Preview {
    @Previewable @State var isOpen = true
    @Previewable @State var selectedPage = AppPage.transactions
    
    SidebarMenu(
        isOpen: $isOpen,
        selectedPage: $selectedPage,
        onPageSelected: { _ in }
    )
}

