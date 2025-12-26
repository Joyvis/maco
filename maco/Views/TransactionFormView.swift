//
//  TransactionFormView.swift
//  maco
//
//  Created by Joyvis Santana on 24/11/25.
//

import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction?
    
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var dueDate: Date = Date()
    @State private var description: String = ""
    @State private var categoryName: String = ""
    @State private var selectedCategoryId: String? = nil
    @State private var selectedPaymentMethodId: String? = nil
    @State private var status: String? = nil
    
    @State private var availableCategories: [CategoryResponse] = []
    @State private var filteredCategories: [CategoryResponse] = []
    @State private var showCategorySuggestions: Bool = false
    @State private var isCreatingCategory: Bool = false
    @State private var availablePaymentMethods: [PaymentMethodResponse] = []
    @State private var isLoading: Bool = false
    @State private var isLoadingCategories: Bool = false
    @State private var isLoadingPaymentMethods: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    
    private var isEditMode: Bool {
        transaction != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Details") {
                    // Amount field with currency formatting
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    // Type picker
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    // Due date picker
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    // Description field
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if selectedType == .expense {
                    Section("Category") {
                        CategoryAutocompleteView(
                            categoryName: $categoryName,
                            selectedCategoryId: $selectedCategoryId,
                            availableCategories: availableCategories,
                            filteredCategories: $filteredCategories,
                            showSuggestions: $showCategorySuggestions,
                            isCreatingCategory: $isCreatingCategory,
                            isLoadingCategories: isLoadingCategories,
                            onCategorySelected: { category in
                                selectedCategoryId = category.id
                                categoryName = category.name
                                showCategorySuggestions = false
                            },
                            onCreateCategory: {
                                Task {
                                    await createNewCategory()
                                }
                            }
                        )
                    }
                }
                
                Section("Payment Method") {
                    PaymentMethodPickerView(
                        selectedPaymentMethodId: $selectedPaymentMethodId,
                        availablePaymentMethods: availablePaymentMethods,
                        isLoadingPaymentMethods: isLoadingPaymentMethods
                    )
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveTransaction()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .task {
                await loadPaymentMethods()
                if selectedType == .expense {
                    await loadCategories()
                }
                // If we have a transaction, prefill after data is loaded
                if let transaction = transaction {
                    prefillForm(with: transaction)
                }
            }
            .onChange(of: selectedType) { oldValue, newValue in
                if newValue == .income {
                    // Clear category selection when switching to Income
                    selectedCategoryId = nil
                    categoryName = ""
                    showCategorySuggestions = false
                } else if newValue == .expense && oldValue == .income {
                    // Load categories when switching to Expense
                    Task {
                        await loadCategories()
                    }
                }
            }
            .onChange(of: categoryName) { oldValue, newValue in
                if selectedType == .expense {
                    filterCategories(query: newValue)
                }
            }
            .onDisappear {
                // Cancel any pending search when view disappears
                searchTask?.cancel()
            }
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty &&
        !description.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0 &&
        selectedPaymentMethodId != nil
    }
    
    private func filterCategories(query: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Clear suggestions if query is empty or less than 3 characters
        if query.isEmpty || query.count < 3 {
            filteredCategories = []
            showCategorySuggestions = false
            return
        }
        
        // Show suggestions UI
        showCategorySuggestions = true
        
        // Create new search task with debouncing
        searchTask = Task {
            // Wait 500ms before making API call (debouncing)
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            // Make API call
            await performCategorySearch(query: query)
        }
    }
    
    private func performCategorySearch(query: String) async {
        isLoadingCategories = true
        defer { isLoadingCategories = false }
        
        do {
            let categories = try await CategoryService.shared.fetchCategories(filterByName: query)
            
            // Check if task was cancelled before updating state
            guard !Task.isCancelled else { return }
            
            filteredCategories = categories
        } catch {
            // Check if task was cancelled before showing error
            guard !Task.isCancelled else { return }
            
            // Only show error if it's not a cancellation
            if !(error is CancellationError) {
                errorMessage = "Failed to search categories: \(error.localizedDescription)"
            }
            filteredCategories = []
        }
    }
    
    private func loadCategories() async {
        do {
            availableCategories = try await CategoryService.shared.fetchCategories()
            filteredCategories = availableCategories
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
        }
    }
    
    private func loadPaymentMethods() async {
        isLoadingPaymentMethods = true
        defer { isLoadingPaymentMethods = false }
        
        do {
            availablePaymentMethods = try await PaymentMethodService.shared.fetchPaymentMethods()
        } catch {
            errorMessage = "Failed to load payment methods: \(error.localizedDescription)"
        }
    }
    
    private func prefillForm(with transaction: Transaction) {
        // Extract numeric value from amount string (remove currency formatting)
        if let amountValue = Double(transaction.amount) {
            amount = String(format: "%.2f", amountValue)
        } else {
            amount = transaction.amount
        }
        
        selectedType = transaction.transactionType
        dueDate = transaction.dueDate
        description = transaction.transactionDescription
        
        // Only set category for Expense transactions
        if transaction.transactionType == .expense {
            // Look up category name from available categories
            if let categoryId = transaction.categoryId,
               let category = availableCategories.first(where: { $0.id == categoryId }) {
                selectedCategoryId = category.id
                categoryName = category.name
            } else {
                selectedCategoryId = transaction.categoryId
                categoryName = ""
            }
        } else {
            // Clear category for Income transactions
            selectedCategoryId = nil
            categoryName = ""
        }
        
        // Set payment method
        selectedPaymentMethodId = transaction.paymentMethodId
    }
    
    private func createNewCategory() async {
        guard !categoryName.isEmpty else { return }
        
        isCreatingCategory = true
        defer { isCreatingCategory = false }
        
        do {
            let newCategory = try await CategoryService.shared.createCategory(
                name: categoryName,
                parentId: nil
            )
            
            // Add to local list
            availableCategories.append(newCategory)
            filteredCategories.append(newCategory)
            selectedCategoryId = newCategory.id
            
            // Save to SwiftData
            let category = Category(
                id: newCategory.id,
                name: newCategory.name,
                parentId: newCategory.parentId,
                isPredefined: newCategory.isPredefined ?? false,
                userId: newCategory.userId
            )
            modelContext.insert(category)
            
            showCategorySuggestions = false
        } catch {
            errorMessage = "Failed to create category: \(error.localizedDescription)"
        }
    }
    
    private func saveTransaction() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Format amount as currency string
        let formattedAmount = formatCurrency(amount)
        
        // Only pass categoryId for Expense transactions
        let categoryIdToSend = selectedType == .expense ? selectedCategoryId : nil
        
        do {
            let response: TransactionResponse
            
            if let existingTransaction = transaction, let transactionId = existingTransaction.id {
                // Update existing transaction
                response = try await TransactionService.shared.updateTransaction(
                    id: transactionId,
                    amount: formattedAmount,
                    type: selectedType,
                    dueDate: dueDate,
                    description: description,
                    categoryId: categoryIdToSend,
                    status: status,
                    paymentMethodId: selectedPaymentMethodId
                )
                
                // Update SwiftData model
                existingTransaction.amount = response.amount
                // Normalize type to lowercase to handle API returning "Income"/"Expense"
                existingTransaction.transactionType = TransactionType(rawValue: response.type.lowercased()) ?? .expense
                existingTransaction.dueDate = parseDate(response.dueDate) ?? dueDate
                existingTransaction.transactionDescription = response.description
                existingTransaction.categoryId = response.categoryId
                existingTransaction.status = response.status
                existingTransaction.categoryName = response.categoryName
                existingTransaction.paymentMethodId = response.paymentMethodId
                existingTransaction.recurringScheduleId = response.recurringScheduleId
                
                try modelContext.save()
            } else {
                // Create new transaction
                response = try await TransactionService.shared.createTransaction(
                    amount: formattedAmount,
                    type: selectedType,
                    dueDate: dueDate,
                    description: description,
                    categoryId: categoryIdToSend,
                    status: status,
                    paymentMethodId: selectedPaymentMethodId
                )
                
                // Save to SwiftData
                // Normalize type to lowercase to handle API returning "Income"/"Expense"
                let newTransaction = Transaction(
                    id: response.id,
                    amount: response.amount,
                    type: TransactionType(rawValue: response.type.lowercased()) ?? .expense,
                    dueDate: parseDate(response.dueDate) ?? dueDate,
                    transactionDescription: response.description,
                    categoryId: response.categoryId,
                    status: response.status,
                    categoryName: response.categoryName,
                    paymentMethodId: response.paymentMethodId,
                    recurringScheduleId: response.recurringScheduleId
                )
                modelContext.insert(newTransaction)
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to save transaction: \(error.localizedDescription)"
        }
    }
    
    private func formatCurrency(_ value: String) -> String {
        guard let doubleValue = Double(value) else {
            return value
        }
        return String(format: "%.2f", doubleValue)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}

// MARK: - Payment Method Picker Component

struct PaymentMethodPickerView: View {
    @Binding var selectedPaymentMethodId: String?
    let availablePaymentMethods: [PaymentMethodResponse]
    let isLoadingPaymentMethods: Bool
    
    var body: some View {
        if isLoadingPaymentMethods {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading payment methods...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else if availablePaymentMethods.isEmpty {
            Text("No payment methods available")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Picker("Select Payment Method", selection: $selectedPaymentMethodId) {
                ForEach(availablePaymentMethods, id: \.id) { paymentMethod in
                    Text(paymentMethod.name).tag(paymentMethod.id as String?)
                }
            }
        }
    }
}

// MARK: - Category Autocomplete Component

struct CategoryAutocompleteView: View {
    @Binding var categoryName: String
    @Binding var selectedCategoryId: String?
    let availableCategories: [CategoryResponse]
    @Binding var filteredCategories: [CategoryResponse]
    @Binding var showSuggestions: Bool
    @Binding var isCreatingCategory: Bool
    let isLoadingCategories: Bool
    let onCategorySelected: (CategoryResponse) -> Void
    let onCreateCategory: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Type category name", text: $categoryName)
                .onTapGesture {
                    showSuggestions = true
                }
            
            if showSuggestions && !categoryName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if isLoadingCategories {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    } else if filteredCategories.isEmpty {
                        Text("No categories found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    } else {
                        // Show filtered suggestions
                        ForEach(filteredCategories, id: \.id) { category in
                            Button(action: {
                                onCategorySelected(category)
                            }) {
                                HStack {
                                    Text(category.name)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Show option to create new category if no exact match
                    if !isLoadingCategories && !filteredCategories.contains(where: { $0.name.lowercased() == categoryName.lowercased() }) {
                        Divider()
                        Button(action: {
                            onCreateCategory()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create \"\(categoryName)\"")
                                Spacer()
                                if isCreatingCategory {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreatingCategory)
                    }
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
            }
        }
    }
}

#Preview {
    TransactionFormView(transaction: nil)
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self], inMemory: true)
}

