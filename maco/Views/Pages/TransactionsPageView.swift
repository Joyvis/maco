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
    
    // Filter state - using StateObject to observe @Published properties
    @StateObject private var filters: FilterSet = {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return FilterSet(monthYearFilter: MonthYearFilter(month: month, year: year))
    }()

    // Filter out invoice items and filter by selected month/year
    private var topLevelTransactions: [Transaction] {
        let calendar = Calendar.current
        let filtered = transactions.filter { transaction in
            // Filter out invoice items
            guard transaction.parentInvoice == nil else { return false }
            
            // If month/year filter is set, filter by dueDate
            if let monthYearFilter = filters.monthYearFilter {
                let transactionMonth = calendar.component(.month, from: transaction.dueDate)
                let transactionYear = calendar.component(.year, from: transaction.dueDate)
                return transactionMonth == monthYearFilter.month && transactionYear == monthYearFilter.year
            }
            
            // If no filter, show all
            return true
        }
        return filtered
    }
    
    // Group transactions by created_at date (calendar day)
    private var groupedTransactions: [Date: [Transaction]] {
        let calendar = Calendar.current
        return Dictionary(grouping: topLevelTransactions) { transaction in
            calendar.startOfDay(for: transaction.createdAt)
        }
    }
    
    // Sorted date keys (most recent first)
    private var sortedDateKeys: [Date] {
        groupedTransactions.keys.sorted(by: >)
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
                    ForEach(sortedDateKeys, id: \.self) { date in
                        Section {
                            ForEach(groupedTransactions[date] ?? []) { transaction in
                                TransactionRowView(
                                    transaction: transaction,
                                    categories: categories,
                                    onTap: { tappedTransaction in
                                        transactionToEdit = tappedTransaction
                                        showTransactionForm = true
                                    }
                                )
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
            apiTotal = summary.total
            apiPending = summary.pending
        } catch {
            errorMessage = "Failed to sync transactions: \(error.localizedDescription)"
        }
    }
}

