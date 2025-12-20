//
//  PageLayout.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct PageLayout<Content: View>: View {
    let title: String
    let content: Content
    let addButton: AnyView?
    let monthPicker: AnyView?
    let totalComponent: AnyView?
    
    @Binding var isMenuOpen: Bool
    
    init(
        title: String,
        isMenuOpen: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        addButton: AnyView? = nil,
        monthPicker: AnyView? = nil,
        totalComponent: AnyView? = nil
    ) {
        self.title = title
        self._isMenuOpen = isMenuOpen
        self.content = content()
        self.addButton = addButton
        self.monthPicker = monthPicker
        self.totalComponent = totalComponent
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Optional month picker
                if let monthPicker = monthPicker {
                    monthPicker
                }
                
                // Main content
                content
                
                // Optional total component
                if let totalComponent = totalComponent {
                    totalComponent
                }
            }
            .navigationTitle(title)
            .toolbar {
                // Hamburger menu button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isMenuOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                    }
                }
                
                // Optional add button
                if let addButton = addButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        addButton
                    }
                }
            }
        }
    }
}

