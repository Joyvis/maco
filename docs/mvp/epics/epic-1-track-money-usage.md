# EPIC-1: Track Money Usage

## Overview
Enable users to record income and expenses, organize them by categories (with subcategories), set up recurring transaction schedules, and view spending reports with visualizations.

## User Stories

### US-1.1: Create Transaction (Income/Expense)
**As a** user  
**I want to** record income and expense transactions  
**So that** I can track my money flow

**Acceptance Criteria:**
- User can create a transaction with: amount, type (credit/income or debit/expense), due date, description
- User can assign a category to the transaction
- Transaction is saved and displayed in transaction list
- Data types:
  amount: currency (use a lib or plugin to manage it)
  type: enum (Income or Expense)
  due date: date
  description: text
  category: select box (we can start type and it autocompletes) (if the typed category does not exist, we should have a kind of shortcut to create a new one - URL: POST localhost:3000/api/v1/transaction_categories)
- Implementation details:
  it should be a form, after fill up the form and hit the button save, it should send a post request to the url localhost:3000/api/v1/transactions
- Extras:
  we should add a button to add new transactions in the home page and when we hit it, it opens the new form.

---

### US-1.2: Category Management
**As a** user  
**I want to** create and manage categories with subcategories  
**So that** I can organize my transactions hierarchically

**Acceptance Criteria:**
- User can create custom categories
- System provides predefined categories (taxes, health, leisure, etc.)
- User can create subcategories (child categories with parent)
- Categories support hierarchical structure (category inheritance)
- User can edit and delete custom categories

**Dependencies:** None (foundational)

---

### US-1.3: Create Recurring Schedule
**As a** user  
**I want to** create recurring transaction schedules  
**So that** I can track regular expenses and see cost projections

**Acceptance Criteria:**
- User can create a recurring schedule with: frequency (monthly, weekly, etc.), category, description
- Schedule does not store fixed amount (calculated from average of linked transactions)
- User can link a transaction to a recurring schedule when creating it
- User can view all recurring schedules

**Dependencies:** US-1.2 (Category Management)

---

### US-1.4: View Transaction List
**As a** user  
**I want to** see all my transactions  
**So that** I can review my income and expenses

**Acceptance Criteria:**
- Display all transactions (income and expenses) in a list
- Show: amount, type, date, description, category
- Transactions sorted by date (newest first)
- User can filter by type (income/expense) and category

**Dependencies:** US-1.1, US-1.2

---

### US-1.5: Spending Report (All-time)
**As a** user  
**I want to** view a report showing total earnings and spending  
**So that** I can understand my overall financial situation

**Acceptance Criteria:**
- Report page displays:
  - Total earnings (sum of all income transactions)
  - Total spending (sum of all expense transactions)
  - Net amount (earnings - spending)
- Data is calculated from all transactions (all-time view)
- Report updates when new transactions are added

**Dependencies:** US-1.1

---

### US-1.6: Category Breakdown Visualization
**As a** user  
**I want to** see how my spending is distributed across categories  
**So that** I can identify where I spend most of my money

**Acceptance Criteria:**
- Pie chart visualization showing spending distribution by category
- Each slice shows category name and percentage
- Percentages calculated from total spending
- Subcategories are grouped under parent categories in the visualization
- Chart updates when transactions are added/modified

**Dependencies:** US-1.1, US-1.2, US-1.5

---

### US-1.7: Cost Projections (Recurring Schedules)
**As a** user  
**I want to** see projected future costs based on recurring schedules  
**So that** I can plan my finances

**Acceptance Criteria:**
- Display projected costs for upcoming periods based on recurring schedules
- Projection amount = average of previous transactions linked to the schedule
- If no previous transactions exist, use the first transaction amount
- Show projected date, amount, category, and description
- Projections are calculated dynamically (not stored as transactions)

**Dependencies:** US-1.3, US-1.1

---

## Data Model

### Transaction
- `id` (unique identifier)
- `amount` (decimal)
- `type` (enum: credit/income, debit/expense)
- `date` (date)
- `description` (string)
- `category_id` (foreign key to Category)
- `recurring_schedule_id` (optional, foreign key to RecurringSchedule)

### Category
- `id` (unique identifier)
- `name` (string)
- `parent_id` (optional, foreign key to Category for subcategories)
- `is_predefined` (boolean)
- `user_id` (for custom categories, null for predefined)

### RecurringSchedule
- `id` (unique identifier)
- `frequency` (enum: monthly, weekly, etc.)
- `category_id` (foreign key to Category)
- `description` (string)
- `user_id` (for future multi-user support)

## Technical Notes

- Categories support hierarchical structure (parent-child relationships)
- Recurring schedules calculate projections from average of linked transactions
- First transaction linked to a schedule becomes the initial projection value
- All-time reporting initially; time period filters to be added later

