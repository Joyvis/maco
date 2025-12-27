//
//  DateSectionHeader.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI

struct DateSectionHeader: View {
    let date: Date
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    VStack(spacing: 0) {
        DateSectionHeader(date: Date())
        DateSectionHeader(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        DateSectionHeader(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
    }
}

