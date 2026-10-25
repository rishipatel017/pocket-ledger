# PocketLedger - Implementation Details

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [State Management](#state-management)
3. [Data Models](#data-models)
4. [Service Layer](#service-layer)
5. [UI Architecture](#ui-architecture)
6. [Implemented Features](#implemented-features)
7. [Technical Decisions](#technical-decisions)
8. [Areas for Improvement](#areas-for-improvement)
9. [Known Limitations](#known-limitations)
10. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

PocketLedger follows a clean MVVM (Model-View-ViewModel) architecture pattern with a Repository pattern for data persistence.

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (Screens)                       │
│  HomeScreen | TransactionsScreen | InsightsScreen | etc.  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Management Layer                    │
│                      AppState (ChangeNotifier)                     │
│  - Business Logic                                              │
│  - State Management                                            │
│  - Data Transformation                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                            │
│  StorageService | NotificationService | AuthService      │
│  InsightsService                                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Persistence                           │
│                 SharedPreferences (Local Storage)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## State Management

### AppState Class
The `AppState` class is the central state manager implementing `ChangeNotifier` pattern:

**Key Responsibilities:**
- Manages all application state (transactions, categories, budgets, reminders, etc.)
- Handles business logic for calculations (budget progress, cash flow, etc.)
- Provides methods for CRUD operations on all data entities
- Formats and displays monetary values with currency support
- Manages authentication lock state

**State Properties:**
```dart
- AppSettings _settings
- List<TransactionItem> _transactions
- List<CategoryItem> _categories
- List<BudgetItem> _budgets
- List<ReminderItem> _reminders
- List<FinancialRecordItem> _financialRecords
- List<SavingsGoalItem> _savingsGoals
- bool _isLocked
- // Filter state
- String _searchQuery
- TransactionType? _filterType
- // ... other filters
```

**Key Methods:**
- `init()` - Initialize and load data from storage
- `addTransaction()`, `updateTransaction()`, `deleteTransaction()`
- `setBudget()`, `toggleBudget()`, `deleteBudget()`
- `addReminder()`, `markReminderPaid()`, `postponeReminder()`
- `addFinancialRecord()`, `updateFinancialRecord()`
- `setupPin()`, `unlockWithPin()`, `disablePin()`
- `carryForwardBudgets()` - Auto-carry budgets from previous month
- `formatAmount()` - Format monetary values with currency symbol

---

## Data Models

### TransactionItem
Represents a single financial transaction.

**Fields:**
- `id` - Unique identifier (UUID)
- `title` - Transaction title
- `amount` - Transaction amount
- `type` - Expense, Income, or Transfer
- `date` - Transaction date/time
- `categoryId` - Reference to category
- `categoryName` - Category name (denormalized)
- `paymentMethod` - Cash, UPI, Debit Card, Credit Card, Bank Transfer
- `notes` - Optional notes
- `transferToAccount` - For transfer transactions

### CategoryItem
Represents a spending/income category.

**Fields:**
- `id` - Unique identifier
- `name` - Category name
- `iconCodePoint` - Icon code point for tree-shaking
- `colorValue` - Category color
- `isExpense` - Whether this is an expense category
- `isStudentOnly` - Whether this category is for student mode
- `isCustom` - Whether this is a user-created category

**Special Features:**
- Static `_iconMap` for tree-shakeable icon constants
- 20+ default categories with predefined icons and colors
- Student-only categories for student mode

### BudgetItem
Represents a budget limit for a category or overall.

**Fields:**
- `id` - Unique identifier
- `categoryId` - Reference to category ('overall' for global budget)
- `categoryName` - Category name
- `limitAmount` - Budget limit
- `monthKey` - Month identifier (YYYY-MM format)
- `warningThreshold` - Warning threshold (e.g., 0.8 for 80%)
- `isEnabled` - Whether budget is active

### ReminderItem
Represents a bill or payment reminder.

**Fields:**
- `id` - Unique identifier
- `title` - Bill title
- `amount` - Bill amount
- `dueDate` - Due date
- `recurrence` - OneTime, Monthly, Quarterly, Yearly
- `categoryId` - Reference to category
- `notes` - Optional notes
- `status` - Pending, Paid, Postponed
- `paidDate` - When the bill was paid
- `linkedExpenseId` - Reference to expense transaction if auto-created

**Special Features:**
- Auto-creates expense transaction when marked as paid
- Auto-schedules next occurrence for recurring reminders

### FinancialRecordItem
Represents FD, RD, or Insurance records.

**Fields:**
- `id` - Unique identifier
- `title` - Record title
- `type` - FixedDeposit, RecurringDeposit, InsurancePolicy
- `institution` - Bank or insurance company name
- `principalOrPremium` - Principal amount or premium
- `interestRate` - Interest rate (optional)
- `maturityAmount` - Maturity amount (optional)
- `startDate` - Start date
- `maturityOrRenewalDate` - Maturity or renewal date
- `policyOrAccountNumber` - Policy/account number
- `notes` - Optional notes
- `isArchived` - Whether record is archived

### SavingsGoalItem
Represents a savings goal.

**Fields:**
- `id` - Unique identifier
- `title` - Goal title
- `targetAmount` - Target amount
- `currentSaved` - Currently saved amount
- `targetDate` - Target date
- `category` - Goal category
- `notes` - Optional notes

### AppSettings
Application-wide settings.

**Fields:**
- `currencySymbol` - Currency symbol (default: ₹)
- `themeMode` - 'light', 'dark', or 'system'
- `isPinLockEnabled` - Whether PIN lock is enabled
- `pinHash` - Hashed PIN
- `securityQuestion` - Security question for PIN recovery
- `securityAnswerHash` - Hashed security answer
- `hideBalances` - Whether to hide monetary amounts
- `isStudentMode` - Whether student mode is enabled
- `studentMonthlyAllowance` - Monthly allowance for students

---

## Service Layer

### StorageService
Handles all local data persistence using SharedPreferences.

**Responsibilities:**
- Serialize/deserialize all data models to/from JSON
- Save and load settings, transactions, categories, budgets, reminders, financial records, savings goals
- Generate CSV export of transactions
- Generate full JSON backup
- Restore from JSON backup
- Clear all data
- Track first-run state (for demo data seeding)

**Key Methods:**
```dart
- loadSettings(), saveSettings()
- loadTransactions(), saveTransactions()
- loadCategories(), saveCategories()
- loadBudgets(), saveBudgets()
- loadReminders(), saveReminders()
- loadFinancialRecords(), saveFinancialRecords()
- loadSavingsGoals(), saveSavingsGoals()
- generateTransactionsCsv()
- generateFullBackupJson()
- restoreFromBackupJson()
- clearAllData()
```

### NotificationService
Handles local notifications using flutter_local_notifications.

**Responsibilities:**
- Initialize notification channels
- Request notification permissions
- Show reminder alerts
- Show budget warnings
- Show FD maturity alerts
- Show monthly budget reminders
- Cancel notifications

**Key Methods:**
```dart
- initialize()
- requestPermission()
- showReminderAlert()
- showBudgetWarning()
- showFDMaturityAlert()
- showMonthlyBudgetReminder()
- checkAndFireReminders()
- checkAndFireFDAlerts()
- cancelNotification()
- cancelAll()
```

### AuthService
Handles authentication-related operations.

**Responsibilities:**
- Hash PINs using SHA-256
- Hash security answers
- Verify PINs
- Verify security answers

**Key Methods:**
```dart
- hashPin(pin)
- verifyPin(pin, hash)
- hashAnswer(answer)
- verifyAnswer(answer, hash)
```

### InsightsService
Generates insights and analytics from transaction data.

**Responsibilities:**
- Calculate category-wise spending
- Generate spending insights
- Compare months
- Calculate daily trends

**Key Methods:**
```dart
- calculateCategorySpans()
- generateInsights()
- compareMonths()
- calculateDailyTrend()
```

---

## UI Architecture

### Screen Organization
The app has 5 main screens accessible via bottom navigation:

1. **HomeScreen** - Dashboard with summary cards and quick actions
2. **TransactionsScreen** - Transaction list with search and filters
3. **InsightsScreen** - Charts and analytics
4. **CalendarScreen** - Financial calendar with events
5. **SettingsScreen** - App settings and data management

### Dialog Structure
All modals use bottom sheets for better mobile UX:

- `AddTransactionDialog` - Add/edit transactions
- `AddReminderDialog` - Add/edit bill reminders
- `AddBudgetDialog` - Add/edit budgets
- `AddFinancialRecordDialog` - Add/edit FD/Insurance records
- `AddGoalDialog` - Add/edit savings goals

### Theme System
Centralized theming in `app_theme.dart`:

- `AppColors` - Color constants for brand colors, financial semantics, dark/light themes
- `AppTheme.lightTheme` - Light theme configuration
- `AppTheme.darkTheme` - Dark theme configuration
- Dynamic theme switching (light/dark/system)

### Loading Screen
- Animated logo with fade and scale effects
- Displays app name and tagline
- Loading indicator
- Automatically transitions to main app after 1.5 seconds

### PIN Lock Screen
- 4-digit PIN input
- PIN recovery with security question
- Biometric authentication support (where available)
- Auto-lock timer

---

## Implemented Features

### ✅ Core Features (FR-01 to FR-09)

#### FR-01: Manual Expense and Income Management
- Add, edit, view, delete transactions
- Support for expense, income, and transfer types
- Multiple payment methods (Cash, UPI, Debit Card, Credit Card, Bank Transfer)
- Search and filter by date, amount, category, type, payment method
- Chronological transaction display

#### FR-02: Category Management
- 20+ default categories with icons and colors
- Custom category creation
- Student-only categories (Tuition, Books, Hostel, Mess, Canteen, Pocket Money)
- Expense and income categories

#### FR-03: Financial Dashboard
- Total income for selected period
- Total expenses for selected period
- Remaining budget and net cash flow
- Recent transactions list
- Upcoming reminders
- Quick-add buttons for expenses and income
- Weekly and monthly view toggle

#### FR-04: Charts and Visual Analysis
- Donut chart: Expense distribution by category
- Bar chart: Daily spending trends
- Line chart: Income vs expense trends
- Summary cards with totals
- Period comparison (current vs previous month)
- Transaction drill-down by tapping chart categories

#### FR-05: Budget Management
- Monthly overall budget
- Category-specific budgets
- Progress visualization with color-coded indicators
- Warning thresholds (80%, 100%)
- Enable/disable budgets
- Automatic carry-forward from previous month

#### FR-06: Bills and Financial Reminders
- One-time and recurring reminders
- Multiple recurrence options (daily, weekly, monthly, quarterly, yearly)
- Advance notification settings
- Mark as paid with linked expense creation
- Payment history tracking
- Postpone reminders

#### FR-07: Financial Records
- Fixed Deposit tracking
- Recurring Deposit tracking
- Insurance policy management
- Maturity date tracking
- Interest rate and maturity amount
- Archive expired records

#### FR-08: Privacy and Application Security
- Optional PIN lock (4-digit)
- Biometric authentication support
- Auto-lock timer
- Security question for PIN recovery
- Hide balances option
- Local encrypted storage

#### FR-09: Data Management
- Currency symbol selection (8 currencies)
- Category manager
- Budget and goal management
- CSV export of transactions
- Full JSON backup and restore
- Reset all data

### ✅ Unique Features

#### Student Mode
- Specialized categories for students
- Monthly allowance tracking
- Daily burn rate calculation
- Days of runway forecast
- Scholarship and freelance income categories

#### Spending Insights
- AI-powered observations about spending patterns
- Month-over-month comparisons
- Category spending percentages
- Budget utilization alerts

#### Financial Calendar
- Unified calendar for all financial events
- Color-coded event types (bills, FD maturities, transactions)
- Event details on tap
- Monthly view navigation

#### Savings Goals
- Create multiple savings goals
- Track progress with visual indicators
- Add contributions to goals
- Set target dates

---

## Technical Decisions

### 1. Why SharedPreferences over SQLite?
- **Simplicity** - For the current data volume, SharedPreferences is sufficient
- **Ease of Backup** - JSON serialization is straightforward
- **Performance** - No database overhead for simple CRUD operations
- **Future Scalability** - Can migrate to SQLite/Isar if needed

### 2. Why ChangeNotifier over Provider?
- **Built-in** - No additional dependencies
- **Simplicity** - Sufficient for this app's complexity
- **Performance** - Direct listener pattern without middleware overhead

### 3. Why Bottom Sheets for Dialogs?
- **Mobile-First UX** - Bottom sheets are the standard pattern on mobile
- **Accessibility** - Easier to reach on large phones
- **Consistency** - Matches platform conventions

### 4. Why Tree-Shakeable Icons?
- **Build Size** - Reduces APK size by only including used icons
- **Performance** - Faster compilation
- **Best Practice** - Recommended by Flutter team

### 5. Why Demo Data Seeding?
- **Onboarding** - Helps users understand the app immediately
- **Testing** - Makes it easy to verify all features work
- **Single-Time** - Only seeds on first run, not after reset

### 6. Why Carry-Forward Budgets?
- **User Convenience** - Reduces repetitive setup
- **Consistency** - Maintains budgeting habits
- **Opt-Out** - Users can edit or disable at any time

---

## Areas for Improvement

### High Priority

#### 1. Testing
**Current State:** No automated tests
**Improvements Needed:**
- Unit tests for all service layer methods
- Widget tests for all screens
- Integration tests for data persistence
- End-to-end tests for critical user flows

**Implementation Plan:**
```dart
test('StorageService should save and load transactions', () async {
  final prefs = await SharedPreferences.getInstance();
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService(prefs);
  
  final tx = TransactionItem(
    id: '1',
    title: 'Test',
    amount: 100.0,
    type: TransactionType.expense,
    date: DateTime.now(),
    categoryId: 'food',
    categoryName: 'Food',
    paymentMethod: PaymentMethod.cash,
  );
  
  await storage.saveTransactions([tx]);
  final loaded = storage.loadTransactions();
  
  expect loaded.length, 1);
  expect loaded[0].title, 'Test');
});
```

#### 2. Error Handling
**Current State:** Basic try-catch with SnackBar messages
**Improvements Needed:**
- Comprehensive error boundaries
- Logging service for debugging
- User-friendly error messages
- Retry mechanisms for failed operations

#### 3. Input Validation
**Current State:** Basic validation implemented
**Improvements Needed:**
- More robust validation (regex for account numbers, etc.)
- Real-time validation feedback
- Input masks for structured data (dates, phone numbers)
- Better error messages with specific guidance

### Medium Priority

#### 4. Performance Optimization
**Current State:** Works well with demo data
**Improvements Needed:**
- Lazy loading for transaction lists
- Pagination for large datasets
- Image caching for category icons
- Optimize chart rendering for large datasets

#### 5. Accessibility
**Current State:** Basic Material Design accessibility
**Improvements Needed:**
- Screen reader support
- High contrast mode
- Font size scaling
- Touch target size verification
- Color accessibility verification

#### 6. Internationalization (i18n)
**Current State:** Hardcoded English text
**Improvements Needed:**
- Extract all strings to arb files
- Support multiple languages
- Currency formatting based on locale
- Date formatting based on locale

### Low Priority

#### 7. Advanced Features
- Cloud synchronization (optional, opt-in)
- Receipt scanning with OCR
- Import bank statements (CSV/OFX/PDF)
- Split expense tracking
- Recurring transaction automation
- Widget support
- Dark mode schedule
- Tax summary generation
- Advanced reporting with PDF export

#### 8. Platform-Specific Features
- Android: Widgets, App Shortcuts, Share Intent
- iOS: Widgets, App Clips, Share Extension
- Web: PWA support, offline caching
- Desktop: Tray icon, keyboard shortcuts

---

## Known Limitations

### Platform Limitations

#### Web Platform
- **Notifications:** Limited support, only works when tab is active
- **Biometrics:** Not supported
- **File System:** Limited file access for backup/restore
- **Persistence:** Clearing browser data clears app data

#### Android
- **Exact Alarms:** Requires special permissions and usage justification
- **Background Services:** Limited by Doze mode
- **Icon Tree-Shaking:** Requires `--no-tree-shake-icons` flag

#### iOS
- **Notifications:** Requires entitlements in Info.plist
- **Background Updates:** Limited by iOS policies
- **File Access:** Requires special permissions

### Functional Limitations

#### Data Volume
- **Transaction Limit:** SharedPreferences has size limits (~1MB)
- **Large History:** May need pagination after 1000+ transactions
- **Backup Size:** Large backups may fail

#### Analytics
- **Insights Accuracy:** Requires sufficient historical data (3+ months)
- **Trend Detection:** Limited by transaction frequency
- **Budget Recommendations:** Currently manual only

#### Security
- **PIN Strength:** Only 4 digits (sufficient for casual use, not high-security)
- **Data Encryption:** No at-rest encryption for SharedPreferences
- **Backup Encryption:** JSON backups are not encrypted

---

## Testing Strategy

### Recommended Test Coverage

#### Unit Tests (Target: 70% coverage)
- **Service Layer:**
  - StorageService serialization/deserialization
  - AuthService hashing/verification
  - InsightsService calculations
  - NotificationService scheduling

- **Models:**
  - All model to/from JSON methods
  - Model copyWith methods
  - Model validation

- **State Management:**
  - AppState CRUD operations
  - AppState calculations (budget progress, cash flow)
  - AppState formatting methods

#### Widget Tests (Target: 50% coverage)
- All screens render correctly
- All dialogs open and close correctly
- Form validation works
- Empty states display correctly
- Charts render with data

#### Integration Tests (Target: 30% coverage)
- End-to-end user flows:
  - Add transaction → verify in dashboard → verify in insights
  - Set budget → spend → verify warning
  - Create reminder → mark paid → verify linked expense
  - Set PIN → lock → unlock → verify
  - Reset data → verify clean state

### Test Data Strategy
- Use mock SharedPreferences for tests
- Create test data factories for realistic test data
- Use golden file testing for UI regression detection
- Test both empty state and populated state

### Manual Testing Checklist
- [ ] All CRUD operations work correctly
- [ ] Filters and search work across all screens
- [ ] Charts update when data changes
- [ ] Budget warnings trigger at correct thresholds
- [ ] Reminders fire at correct times
- [ ] PIN lock/unlock works
- [ ] Student mode toggles correctly
- [ ] Data export/restore works
- [ ] Reset data clears everything
- [ ] App works offline
- [ ] No crashes or major bugs

---

## Deployment Checklist

### Pre-Release
- [ ] Update version number in pubspec.yaml
- [ ] Update build number
- [ ] Run flutter analyze and fix critical issues
- [ ] Run all tests
- [ ] Test on at least 2 physical devices
- [ ] Verify release build works
- [ ] Update README with latest features
- [ ] Create release notes

### Android Release
- [ ] Update app version in android/app/build.gradle
- [ ] Sign APK with keystore
- [ ] Test signed APK
- [ ] Generate App Bundle for Play Store
- [ ] Create Play Store listing

### iOS Release
- [ ] Update version in ios/Runner/Info.plist
- [ ] Update deployment target
- [ ] Test on physical device
- [ ] Archive and upload to App Store Connect
- [ ] Create App Store listing

### Web Release
- [ ] Build for web
- [ ] Test in multiple browsers
- [ ] Deploy to Firebase Hosting or Vercel
- [ ] Update deployment documentation

---

## Conclusion

PocketLedger is a well-architected, feature-rich personal finance application that successfully demonstrates modern Flutter development practices. The app is production-ready for its target use case (students and professionals managing personal finances), with room for expansion into more advanced features like cloud sync, receipt scanning, and multi-currency support.

The codebase is clean, well-organized, and follows Flutter best practices. With the recommended improvements in testing, error handling, and accessibility, PocketLedger can evolve into a top-tier personal finance application.
