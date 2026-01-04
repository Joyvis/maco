//
//  TransactionsPageView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct TransactionsPageView: View {
    @Binding var isMenuOpen: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.createdAt, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]

    @State private var showTransactionForm: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var transactionToDelete: Transaction? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var apiTotal: String = "0.00"
    @State private var apiPending: String = "0.00"
    @State private var showMarkAsPaidView: Bool = false
    @State private var transactionToMarkAsPaid: Transaction? = nil
    @State private var paidTransactionIds: [String] = []
    @State private var notPaidTransactionIds: [String] = []
    
    // Filter state - using StateObject to observe @Published properties
    @StateObject private var filters: FilterSet = {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return FilterSet(monthYearFilter: MonthYearFilter(month: month, year: year))
    }()

    // Get not_paid transactions from SwiftData based on API response IDs
    private var unpaidTransactions: [Transaction] {
        let unpaid = transactions.filter { transaction in
            // Filter out invoice items
            guard transaction.parentInvoice == nil else { return false }
            // Only include transactions that are in the not_paid list from API
            guard let id = transaction.id else { return false }
            return notPaidTransactionIds.contains(id)
        }
        return unpaid.sorted { $0.dueDate < $1.dueDate }
    }
    
    // Get paid transactions from SwiftData based on API response IDs, grouped by paidAt date
    private var paidTransactionsByDate: [Date: [Transaction]] {
        let calendar = Calendar.current
        let paid = transactions.filter { transaction in
            // Filter out invoice items
            guard transaction.parentInvoice == nil else { return false }
            // Only include transactions that are in the paid list from API
            guard let id = transaction.id else { return false }
            return paidTransactionIds.contains(id) && transaction.paidAt != nil
        }
        return Dictionary(grouping: paid) { transaction in
            calendar.startOfDay(for: transaction.paidAt!)
        }
    }
    
    // Sorted date keys for paid transactions (most recent first - today to past)
    private var sortedPaidDateKeys: [Date] {
        paidTransactionsByDate.keys.sorted(by: >)
    }
    
    // Convert API string values to Double for TotalComponent
    private var pendingTotal: Double {
        Double(apiPending) ?? 0.0
    }
    
    private var totalAmount: Double {
        Double(apiTotal) ?? 0.0
    }
    
    var body: some View {
        PageLayout(
            title: "Transactions",
            isMenuOpen: $isMenuOpen,
            content: {
                List {
                    // Pending Transactions section (unpaid transactions)
                    if !unpaidTransactions.isEmpty {
                        Section {
                            ForEach(unpaidTransactions) { transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    categories: categories,
                                    onTap: { tappedTransaction in
                                        transactionToEdit = tappedTransaction
                                        showTransactionForm = true
                                    }
                                )
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    // Only show mark as paid for expense and invoice transactions
                                    if transaction.transactionType == .expense || transaction.transactionType == .invoice {
                                        Button {
                                            transactionToMarkAsPaid = transaction
                                            showMarkAsPaidView = true
                                        } label: {
                                            Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("Pending Transactions")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGroupedBackground))
                        }
                    }
                    
                    // Paid transactions grouped by paidAt date
                    ForEach(sortedPaidDateKeys, id: \.self) { date in
                        Section {
                            ForEach(paidTransactionsByDate[date] ?? []) { transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    categories: categories,
                                    onTap: { tappedTransaction in
                                        transactionToEdit = tappedTransaction
                                        showTransactionForm = true
                                    }
                                )
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    // Only show mark as unpaid for expense and invoice transactions
                                    if transaction.transactionType == .expense || transaction.transactionType == .invoice {
                                        Button {
                                            transactionToMarkAsPaid = transaction
                                            showMarkAsPaidView = true
                                        } label: {
                                            Label("Mark as Unpaid", systemImage: "xmark.circle.fill")
                                        }
                                        .tint(.orange)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            DateSectionHeader(date: date)
                        }
                    }
                    
                    // Total component as footer section
                    Section {
                        TotalComponent(
                            pendingTotal: pendingTotal,
                            totalAmount: totalAmount
                        )
                    }
                }
                .id("\(filters.monthYearFilter?.month ?? 0)-\(filters.monthYearFilter?.year ?? 0)")
                .refreshable {
                    await syncTransactions()
                }
            },
            addButton: AnyView(
                Button(action: {
                    transactionToEdit = nil
                    showTransactionForm = true
                }) {
                    Label("Add Transaction", systemImage: "plus")
                }
            ),
            monthPicker: AnyView(
                MonthPickerView(
                    initialFilter: filters.monthYearFilter,
                    onMonthSelected: { monthYearFilter in
                        filters.monthYearFilter = monthYearFilter
                    }
                )
            )
        )
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(transaction: transactionToEdit)
        }
        .onChange(of: showTransactionForm) { oldValue, newValue in
            if !newValue {
                transactionToEdit = nil
            }
        }
        .sheet(isPresented: $showMarkAsPaidView) {
            if let transaction = transactionToMarkAsPaid {
                MarkAsPaidView(
                    transaction: transaction,
                    onMarkAsPaid: { paidAt in
                        Task {
                            await performMarkAsPaid(transaction: transaction, paidAt: paidAt)
                        }
                    }
                )
            }
        }
        .onChange(of: showMarkAsPaidView) { oldValue, newValue in
            if !newValue {
                transactionToMarkAsPaid = nil
            }
        }
        .alert("Delete Transaction", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                transactionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    performDeleteTransaction(transaction)
                }
                transactionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .task {
            await syncTransactions()
        }
        .onReceive(filters.$monthYearFilter) { _ in
            Task {
                await syncTransactions()
            }
        }
    }

    private func performDeleteTransaction(_ transaction: Transaction) {
        Task {
            // Delete from API if transaction has an ID
            if let transactionId = transaction.id {
                do {
                    try await TransactionService.shared.deleteTransaction(id: transactionId)
                } catch {
                    errorMessage = "Failed to delete transaction: \(error.localizedDescription)"
                    return
                }
            }
            
            // Delete from SwiftData
            withAnimation {
                modelContext.delete(transaction)
            }
        }
    }
    
    private func performMarkAsPaid(transaction: Transaction, paidAt: Date?) async {
        guard let transactionId = transaction.id else {
            errorMessage = "Cannot update transaction: missing ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Update status based on paidAt: "paid" if paidAt is set, otherwise keep current status or set to nil
            let newStatus = paidAt != nil ? "paid" : (transaction.status == "paid" ? nil : transaction.status)
            
            // Update transaction via API
            let response = try await TransactionService.shared.updateTransaction(
                id: transactionId,
                amount: transaction.amount,
                type: transaction.transactionType,
                dueDate: transaction.dueDate,
                description: transaction.transactionDescription,
                categoryId: transaction.categoryId,
                status: newStatus,
                paymentMethodId: transaction.paymentMethodId,
                paidAt: paidAt
            )
            
            // Update local SwiftData transaction
            transaction.amount = response.amount
            transaction.transactionType = TransactionType(rawValue: response.type.lowercased()) ?? .expense
            transaction.dueDate = parseDate(response.dueDate) ?? transaction.dueDate
            transaction.transactionDescription = response.description
            transaction.categoryId = response.categoryId
            transaction.status = response.status
            transaction.categoryName = response.categoryName
            transaction.paymentMethodId = response.paymentMethodId
            transaction.paymentMethodName = response.paymentMethodName
            transaction.recurringScheduleId = response.recurringScheduleId
            transaction.paidAt = parseDate(response.paidAt ?? "")
            
            try modelContext.save()
            
            // Sync transactions to refresh UI and get updated totals
            await syncTransactions()
        } catch {
            errorMessage = "Failed to update transaction: \(error.localizedDescription)"
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // First try parsing as date-only format (YYYY-MM-DD)
        // Use local timezone so "2025-12-25" means Dec 25 in user's timezone
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone.current
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }
        
        // Fall back to ISO8601 datetime format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: dateString)
    }
    
    private func syncTransactions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Only pass filters if they have at least one filter set
            let activeFilters = filters.hasFilters() ? filters : nil
            let summary = try await TransactionService.shared.syncTransactions(
                modelContext: modelContext,
                filters: activeFilters
            )
            // Update state with API-provided totals
            apiTotal = summary.paidTotal
            apiPending = summary.notPaidTotal
            // Store transaction IDs for filtering display
            paidTransactionIds = summary.paidTransactions.map { $0.id }
            notPaidTransactionIds = summary.notPaidTransactions.map { $0.id }
        } catch {
            errorMessage = "Failed to sync transactions: \(error.localizedDescription)"
        }
    }
}

