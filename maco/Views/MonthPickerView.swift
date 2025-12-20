//
//  MonthPickerView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct MonthPickerView: View {
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    let onMonthSelected: (Int, Int) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM/yy"
        return formatter
    }()
    
    private var availableMonths: [(month: Int, year: Int, displayText: String)] {
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        var months: [(month: Int, year: Int, displayText: String)] = []
        
        // Generate 12 months: current month + 11 previous months
        for i in 0..<12 {
            var dateComponents = DateComponents()
            dateComponents.month = -i
            if let date = calendar.date(byAdding: dateComponents, to: now) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                let displayText = dateFormatter.string(from: date)
                months.append((month: month, year: year, displayText: displayText))
            }
        }
        
        // Reverse so oldest month is on the left, current month is on the right
        return months.reversed()
    }
    
    init(initialMonth: Int? = nil, initialYear: Int? = nil, onMonthSelected: @escaping (Int, Int) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let defaultMonth = calendar.component(.month, from: now)
        let defaultYear = calendar.component(.year, from: now)
        
        _selectedMonth = State(initialValue: initialMonth ?? defaultMonth)
        _selectedYear = State(initialValue: initialYear ?? defaultYear)
        self.onMonthSelected = onMonthSelected
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableMonths, id: \.displayText) { monthData in
                        MonthButton(
                            displayText: monthData.displayText,
                            isSelected: selectedMonth == monthData.month && selectedYear == monthData.year,
                            action: {
                                selectedMonth = monthData.month
                                selectedYear = monthData.year
                                onMonthSelected(monthData.month, monthData.year)
                                // Scroll to selected month
                                withAnimation {
                                    proxy.scrollTo(monthData.displayText, anchor: .center)
                                }
                            }
                        )
                        .id(monthData.displayText)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .onAppear {
                // Find the currently selected month and scroll to it
                let selectedMonthData = availableMonths.first { 
                    $0.month == selectedMonth && $0.year == selectedYear 
                }
                if let selected = selectedMonthData {
                    // Use a small delay to ensure the view is fully laid out
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(selected.displayText, anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: selectedMonth) { _, _ in
                // Scroll when selection changes externally
                let selectedMonthData = availableMonths.first { 
                    $0.month == selectedMonth && $0.year == selectedYear 
                }
                if let selected = selectedMonthData {
                    withAnimation {
                        proxy.scrollTo(selected.displayText, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedYear) { _, _ in
                // Scroll when selection changes externally
                let selectedMonthData = availableMonths.first { 
                    $0.month == selectedMonth && $0.year == selectedYear 
                }
                if let selected = selectedMonthData {
                    withAnimation {
                        proxy.scrollTo(selected.displayText, anchor: .center)
                    }
                }
            }
        }
    }
}

struct MonthButton: View {
    let displayText: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MonthPickerView { month, year in
        print("Selected month: \(month), year: \(year)")
    }
}

