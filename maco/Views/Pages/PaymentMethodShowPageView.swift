//
//  PaymentMethodShowPageView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct PaymentMethodShowPageView: View {
    let paymentMethod: PaymentMethod
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Transaction.dueDate, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var showPaymentMethodForm: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var transactionToEdit: Transaction? = nil
    @State private var showTransactionForm: Bool = false
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
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    // Filter transactions by payment method ID and month/year
    private var topLevelTransactions: [Transaction] {
        guard let paymentMethodId = paymentMethod.id else { return [] }
        
        let calendar = Calendar.current
        let filtered = transactions.filter { transaction in
            // Filter out invoice items
            guard transaction.parentInvoice == nil else { return false }
            
            // Filter by payment method ID
            guard let transactionPaymentMethodId = transaction.paymentMethodId,
                  transactionPaymentMethodId == paymentMethodId else { return false }
            
            // If month/year filter is set, filter by dueDate for unpaid, paidAt for paid
            if let monthYearFilter = filters.monthYearFilter {
                if transaction.isPaid, let paidAt = transaction.paidAt {
                    let transactionMonth = calendar.component(.month, from: paidAt)
                    let transactionYear = calendar.component(.year, from: paidAt)
                    return transactionMonth == monthYearFilter.month && transactionYear == monthYearFilter.year
                } else {
                    let transactionMonth = calendar.component(.month, from: transaction.dueDate)
                    let transactionYear = calendar.component(.year, from: transaction.dueDate)
                    return transactionMonth == monthYearFilter.month && transactionYear == monthYearFilter.year
                }
            }
            
            // If no filter, show all
            return true
        }
        return filtered
    }
    
    // Unpaid transactions (pending or overdue) - sorted by dueDate ascending
    private var unpaidTransactions: [Transaction] {
        let unpaid = topLevelTransactions.filter { transaction in
            !transaction.isPaid
        }
        return unpaid.sorted { $0.dueDate < $1.dueDate }
    }
    
    // Paid transactions grouped by paidAt date
    private var paidTransactionsByDate: [Date: [Transaction]] {
        let calendar = Calendar.current
        let paid = topLevelTransactions.filter { transaction in
            transaction.isPaid && transaction.paidAt != nil
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
        VStack(spacing: 0) {
            // Month picker
            MonthPickerView(
                initialFilter: filters.monthYearFilter,
                onMonthSelected: { monthYearFilter in
                    filters.monthYearFilter = monthYearFilter
                }
            )
            
            // Main content
            List {
                // Payment Method Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Type")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(paymentMethod.paymentMethodType.displayName)
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Text("Initial Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(paymentMethod.initialBalance))
                                .font(.subheadline)
                        }
                        
                        if paymentMethod.paymentMethodType == .creditAccount, let dueDay = paymentMethod.dueDay {
                            HStack {
                                Text("Due Day")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(dueDay)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
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
                if !sortedPaidDateKeys.isEmpty {
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
                            }
                        } header: {
                            DateSectionHeader(date: date)
                        }
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
            .id("\(paymentMethod.id ?? "")-\(filters.monthYearFilter?.month ?? 0)-\(filters.monthYearFilter?.year ?? 0)")
            .refreshable {
                await syncTransactions()
            }
        }
        .navigationTitle(paymentMethod.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showPaymentMethodForm = true
                }
            }
        }
        .sheet(isPresented: $showPaymentMethodForm) {
            PaymentMethodFormView(paymentMethod: paymentMethod)
        }
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(transaction: transactionToEdit)
        }
        .onChange(of: showTransactionForm) { oldValue, newValue in
            if !newValue {
                transactionToEdit = nil
            }
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
    
    private func syncTransactions() async {
        guard let paymentMethodId = paymentMethod.id else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Create filter set with payment method filter and month/year filter
            var filterSet = FilterSet(paymentMethodFilter: PaymentMethodFilter(paymentMethodId: paymentMethodId))
            if let monthYearFilter = filters.monthYearFilter {
                filterSet.monthYearFilter = monthYearFilter
            }
            
            let summary = try await TransactionService.shared.syncTransactions(
                modelContext: modelContext,
                filters: filterSet
            )
            // Update state with API-provided totals
            apiTotal = summary.paidTotal
            apiPending = summary.notPaidTotal
        } catch {
            errorMessage = "Failed to sync transactions: \(error.localizedDescription)"
        }
    }
}

#Preview {
    PaymentMethodShowPageView(
        paymentMethod: PaymentMethod(
            name: "Checking Account",
            type: .debitAccount,
            initialBalance: 1250.50
        )
    )
    .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self], inMemory: true)
}
