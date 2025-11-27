# Backend API Contract

## Base Configuration

```
Base URL: http://localhost:3000/api/v1
Content-Type: application/json
Authentication: Bearer Token (to be implemented)
```

---

## Authentication

### Headers (Future Implementation)
```
Authorization: Bearer <token>
Content-Type: application/json
```

---

## Endpoints

### 1. Transactions

#### 1.1 Create Transaction
**POST** `/transactions`

**Request Body:**
```json
{
  "transaction": {
    "amount": "100.00",
    "type": "income",
    "due_date": "2025-12-15T10:30:00.000Z",
    "description": "Salary payment",
    "category_id": "cat-123"
  }
}
```

**Request Fields:**
- `amount` (string, required): Currency amount as string with 2 decimal places (e.g., "100.00")
- `type` (string, required): Either `"income"` or `"expense"`
- `due_date` (string, required): ISO 8601 formatted date with timezone (e.g., "2025-12-15T10:30:00.000Z")
- `description` (string, required): Transaction description
- `category_id` (string, optional): ID of the category

**Response (201 Created):**
```json
{
  "id": "txn-456",
  "amount": "100.00",
  "type": "income",
  "due_date": "2025-12-15T10:30:00.000Z",
  "description": "Salary payment",
  "category_id": "cat-123",
  "recurring_schedule_id": null
}
```

**Response Fields:**
- `id` (string): Unique transaction identifier
- `amount` (string): Currency amount
- `type` (string): "income" or "expense"
- `due_date` (string): ISO 8601 formatted date
- `description` (string): Transaction description
- `category_id` (string, nullable): Category ID if assigned
- `recurring_schedule_id` (string, nullable): Recurring schedule ID if linked

**Error Responses:**
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication token
- `422 Unprocessable Entity`: Validation errors

---

#### 1.2 List Transactions
**GET** `/transactions`

**Query Parameters (Optional):**
- `type` (string): Filter by type - `"income"` or `"expense"`
- `category_id` (string): Filter by category ID
- `sort` (string): Sort order - `"date_desc"` (default) or `"date_asc"`

**Response (200 OK):**
```json
[
  {
    "id": "txn-456",
    "amount": "100.00",
    "type": "income",
    "due_date": "2025-12-15T10:30:00.000Z",
    "description": "Salary payment",
    "category_id": "cat-123",
    "recurring_schedule_id": null
  },
  {
    "id": "txn-789",
    "amount": "50.00",
    "type": "expense",
    "due_date": "2025-12-10T14:20:00.000Z",
    "description": "Grocery shopping",
    "category_id": "cat-456",
    "recurring_schedule_id": null
  }
]
```

**Response Fields:**
- Array of transaction objects (same structure as Create Transaction response)

**Error Responses:**
- `401 Unauthorized`: Missing or invalid authentication token

---

### 2. Transaction Categories

#### 2.1 Create Category
**POST** `/transaction_categories`

**Request Body:**
```json
{
  "transaction_category": {
    "name": "Food & Dining",
    "parent_id": null
  }
}
```

**Request Fields:**
- `name` (string, required): Category name
- `parent_id` (string, optional): ID of parent category for subcategories

**Response (201 Created):**
```json
{
  "id": "cat-789",
  "name": "Food & Dining",
  "parent_id": null,
  "is_predefined": false,
  "user_id": "user-123"
}
```

**Response Fields:**
- `id` (string): Unique category identifier
- `name` (string): Category name
- `parent_id` (string, nullable): Parent category ID for subcategories
- `is_predefined` (boolean): Whether category is system-defined
- `user_id` (string, nullable): User ID for custom categories (null for predefined)

**Error Responses:**
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication token
- `422 Unprocessable Entity`: Validation errors (e.g., duplicate name)

---

#### 2.2 List Categories
**GET** `/transaction_categories`

**Query Parameters (Optional):**
- `include_predefined` (boolean): Include predefined categories (default: `true`)
- `parent_id` (string): Filter by parent category ID

**Response (200 OK):**
```json
[
  {
    "id": "cat-123",
    "name": "Food",
    "parent_id": null,
    "is_predefined": true,
    "user_id": null
  },
  {
    "id": "cat-456",
    "name": "Transportation",
    "parent_id": null,
    "is_predefined": true,
    "user_id": null
  },
  {
    "id": "cat-789",
    "name": "Restaurants",
    "parent_id": "cat-123",
    "is_predefined": false,
    "user_id": "user-123"
  }
]
```

**Response Fields:**
- Array of category objects (same structure as Create Category response)

**Error Responses:**
- `401 Unauthorized`: Missing or invalid authentication token

---

#### 2.3 Update Category
**PATCH** `/transaction_categories/:id`

**Request Body:**
```json
{
  "transaction_category": {
    "name": "Updated Category Name",
    "parent_id": "cat-123"
  }
}
```

**Response (200 OK):**
```json
{
  "id": "cat-789",
  "name": "Updated Category Name",
  "parent_id": "cat-123",
  "is_predefined": false,
  "user_id": "user-123"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication token
- `404 Not Found`: Category not found
- `422 Unprocessable Entity`: Validation errors

---

#### 2.4 Delete Category
**DELETE** `/transaction_categories/:id`

**Response (204 No Content)**

**Error Responses:**
- `401 Unauthorized`: Missing or invalid authentication token
- `404 Not Found`: Category not found
- `422 Unprocessable Entity`: Cannot delete category (e.g., has transactions or subcategories)

---

## Data Types

### Transaction Type Enum
```typescript
type TransactionType = "income" | "expense"
```

### Date Format
- **Format**: ISO 8601 with timezone
- **Example**: `"2025-12-15T10:30:00.000Z"`
- **Timezone**: UTC (Z suffix)

### Currency Format
- **Format**: String with 2 decimal places
- **Example**: `"100.00"`, `"1,234.56"`
- **Precision**: Always 2 decimal places

### ID Format
- **Format**: String (UUID or custom format)
- **Example**: `"txn-456"`, `"cat-123"`

---

## Error Response Format

### Standard Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "amount",
        "message": "Amount must be a positive number"
      }
    ]
  }
}
```

### Common Error Codes
- `VALIDATION_ERROR`: Request data validation failed
- `UNAUTHORIZED`: Missing or invalid authentication
- `NOT_FOUND`: Resource not found
- `UNPROCESSABLE_ENTITY`: Business logic validation failed

---

## Request/Response Examples

### Example 1: Create Income Transaction
```bash
POST /api/v1/transactions
Content-Type: application/json
Authorization: Bearer <token>

{
  "transaction": {
    "amount": "2500.00",
    "type": "income",
    "due_date": "2025-12-01T00:00:00.000Z",
    "description": "Monthly salary",
    "category_id": "cat-income-001"
  }
}
```

### Example 2: Create Expense Transaction
```bash
POST /api/v1/transactions
Content-Type: application/json
Authorization: Bearer <token>

{
  "transaction": {
    "amount": "75.50",
    "type": "expense",
    "due_date": "2025-12-15T00:00:00.000Z",
    "description": "Grocery shopping at Whole Foods",
    "category_id": "cat-food-001"
  }
}
```

### Example 3: Create Category
```bash
POST /api/v1/transaction_categories
Content-Type: application/json
Authorization: Bearer <token>

{
  "transaction_category": {
    "name": "Entertainment",
    "parent_id": null
  }
}
```

### Example 4: Create Subcategory
```bash
POST /api/v1/transaction_categories
Content-Type: application/json
Authorization: Bearer <token>

{
  "transaction_category": {
    "name": "Movies",
    "parent_id": "cat-entertainment-001"
  }
}
```

### Example 5: List Transactions with Filters
```bash
GET /api/v1/transactions?type=expense&category_id=cat-food-001&sort=date_desc
Authorization: Bearer <token>
```

---

## Implementation Notes

### Current Implementation Status
- ✅ Transaction creation endpoint structure defined
- ✅ Category creation endpoint structure defined
- ⏳ Transaction listing endpoint (structure ready, needs implementation)
- ⏳ Category listing endpoint (structure ready, needs implementation)
- ⏳ Category update/delete endpoints (for future US-1.2)
- ⏳ Authentication (Bearer token structure ready)

### Future Endpoints (Based on Epic)
- **Recurring Schedules**: `/recurring_schedules` (for US-1.3)
- **Reports**: `/reports/spending` (for US-1.5)
- **Category Breakdown**: `/reports/category_breakdown` (for US-1.6)
- **Projections**: `/projections` (for US-1.7)

---

## Testing Recommendations

### Test Scenarios
1. **Create Transaction**
   - Valid income transaction
   - Valid expense transaction
   - Transaction without category
   - Invalid amount format
   - Missing required fields

2. **List Transactions**
   - Empty list
   - Filtered by type
   - Filtered by category
   - Sorted by date

3. **Create Category**
   - Top-level category
   - Subcategory with parent
   - Duplicate name handling
   - Invalid parent_id

4. **List Categories**
   - Include predefined categories
   - Filter by parent
   - Hierarchical structure

---

## Version History

- **v1.0** (Current): Initial API contract for US-1.1 (Create Transaction)
  - Transaction creation
  - Category creation
  - Basic transaction listing
  - Basic category listing

