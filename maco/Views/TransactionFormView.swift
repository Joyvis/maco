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
    
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var dueDate: Date = Date()
    @State private var description: String = ""
    @State private var categoryName: String = ""
    @State private var selectedCategoryId: String? = nil
    
    @State private var availableCategories: [CategoryResponse] = []
    @State private var filteredCategories: [CategoryResponse] = []
    @State private var showCategorySuggestions: Bool = false
    @State private var isCreatingCategory: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
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
                
                Section("Category") {
                    CategoryAutocompleteView(
                        categoryName: $categoryName,
                        selectedCategoryId: $selectedCategoryId,
                        availableCategories: availableCategories,
                        filteredCategories: $filteredCategories,
                        showSuggestions: $showCategorySuggestions,
                        isCreatingCategory: $isCreatingCategory,
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
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Transaction")
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
                await loadCategories()
            }
            .onChange(of: categoryName) { oldValue, newValue in
                filterCategories(query: newValue)
            }
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty &&
        !description.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }
    
    private func filterCategories(query: String) {
        if query.isEmpty {
            filteredCategories = availableCategories
            showCategorySuggestions = false
        } else {
            filteredCategories = availableCategories.filter { category in
                category.name.localizedCaseInsensitiveContains(query)
            }
            showCategorySuggestions = !filteredCategories.isEmpty || !query.isEmpty
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
            selectedCategoryId = newCategory.id
            
            // Save to SwiftData
            let category = Category(
                id: newCategory.id,
                name: newCategory.name,
                parentId: newCategory.parentId,
                isPredefined: newCategory.isPredefined,
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
        
        do {
            // Create transaction via API
            let response = try await TransactionService.shared.createTransaction(
                amount: formattedAmount,
                type: selectedType,
                dueDate: dueDate,
                description: description,
                categoryId: selectedCategoryId
            )
            
            // Save to SwiftData
            let transaction = Transaction(
                id: response.id,
                amount: response.amount,
                type: TransactionType(rawValue: response.type) ?? .expense,
                dueDate: parseDate(response.dueDate) ?? dueDate,
                transactionDescription: response.description,
                categoryId: response.categoryId,
                recurringScheduleId: response.recurringScheduleId
            )
            modelContext.insert(transaction)
            
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

// MARK: - Category Autocomplete Component

struct CategoryAutocompleteView: View {
    @Binding var categoryName: String
    @Binding var selectedCategoryId: String?
    let availableCategories: [CategoryResponse]
    @Binding var filteredCategories: [CategoryResponse]
    @Binding var showSuggestions: Bool
    @Binding var isCreatingCategory: Bool
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
                    
                    // Show option to create new category if no exact match
                    if !filteredCategories.contains(where: { $0.name.lowercased() == categoryName.lowercased() }) {
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
    TransactionFormView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

