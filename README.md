# PocketLedger

<p align="center">
  <img src="assets/logo.png" alt="PocketLedger Logo" width="200"/>
</p>

<p align="center">
  <i>Track Smart. Spend Better.</i>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.13.5-blue.svg" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13.5-blue.svg" alt="Dart"></a>
  <a href="https://github.com"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

A privacy-focused personal finance mobile application built with Flutter, designed for students and working professionals. PocketLedger helps you track daily expenses, manage budgets, set bill reminders, and analyze spending patterns - all without requiring bank integrations or internet connectivity.

## 📱 Features

### Core Functionality
- **Expense & Income Tracking** - Add, edit, view, and delete transactions with detailed categorization
- **Category Management** - 20+ default categories with customizable icons and colors
- **Financial Dashboard** - Real-time summary of income, expenses, budget status, and cash flow
- **Budget Management** - Set monthly and category-specific budgets with progress tracking
- **Bill Reminders** - Create recurring reminders for bills, subscriptions, and payments
- **Financial Records** - Track Fixed Deposits (FD), Recurring Deposits (RD), and Insurance policies
- **Savings Goals** - Set and track savings goals with progress visualization
- **Spending Insights** - AI-powered observations about spending patterns
- **Financial Calendar** - View all financial events on a unified calendar
- **Data Export** - Export transactions as CSV and full backup as JSON
- **PIN Lock Security** - Optional app lock with PIN and biometric authentication
- **Student Mode** - Specialized categories and runway calculations for students

### Analytics & Visualization
- **Donut Chart** - Expense distribution by category
- **Bar Chart** - Daily spending trends
- **Line Chart** - Income vs expense trends over time
- **Summary Cards** - Total income, expenses, savings, and budget utilization
- **Period Comparison** - Compare current month with previous month
- **Transaction Drill-down** - Tap chart categories to view detailed transactions

### Privacy & Security
- **100% Offline** - Core functionality works without internet
- **Local Storage** - All data stored locally on device
- **PIN Protection** - Optional 4-digit PIN lock with biometric support
- **Data Backup** - Encrypted export/restore of all application data
- **No Cloud Sync** - Your data never leaves your device

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.13.5 or higher
- Dart 3.13.5 or higher
- Android Studio / VS Code with Flutter extension
- For Android: Android SDK with API level 21+
- For iOS: Xcode 12+ (macOS only)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/pocketledger.git
cd pocketledger
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For Chrome (Web)
flutter run -d chrome

# For Android
flutter run

# For iOS (macOS only)
flutter run
```

4. **Build for release**
```bash
# Android APK
flutter build apk --release --no-tree-shake-icons

# Android App Bundle
flutter build appbundle --release --no-tree-shake-icons

# Web
flutter build web --release
```

## 📸 Screenshots

### Home Screen
- Financial summary with income/expense overview
- Budget progress indicators
- Recent transactions list
- Upcoming bill reminders
- Quick-add floating action button

### Transactions Screen
- Full transaction history with search and filters
- Filter by date, category, type, and payment method
- Edit and delete transactions
- View transaction details

### Insights Screen
- Interactive charts (Donut, Bar, Line)
- Category-wise spending breakdown
- Month-over-month comparison
- Spending insights and observations
- Daily spending trends

### Calendar Screen
- Unified financial calendar
- Bill due dates and reminders
- FD/Insurance maturity dates
- Transaction dates
- Color-coded event types

### Settings Screen
- Student mode toggle
- PIN lock setup and management
- Currency selection
- Category manager
- Budget management
- Savings goals
- Financial records (FD, Insurance)
- Data export and backup
- Reset all data

## 🛠️ Tech Stack

| Component | Technology |
|------------|------------|
| **Framework** | Flutter 3.13.5 |
| **Language** | Dart 3.13.5 |
| **State Management** | ChangeNotifier with Provider pattern |
| **Local Storage** | shared_preferences |
| **Charts** | fl_chart |
| **Notifications** | flutter_local_notifications |
| **Crypto** | crypto (for PIN hashing) |
| **UUID** | uuid |
| **File Path** | path_provider |
| **Date Formatting** | intl |

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                  # Data models
│   ├── app_settings.dart
│   ├── budget_item.dart
│   ├── category_item.dart
│   ├── financial_record_item.dart
│   ├── reminder_item.dart
│   ├── savings_goal_item.dart
│   └── transaction_item.dart
├── services/                # Business logic
│   ├── auth_service.dart
│   ├── insights_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── state/                   # App state management
│   └── app_state.dart
├── screens/                 # UI screens
│   ├── home/
│   ├── transactions/
│   ├── insights/
│   ├── calendar/
│   ├── settings/
│   ├── loading_screen.dart
│   ├── pin_lock_screen.dart
│   └── main_navigation_screen.dart
├── dialogs/                 # Modal dialogs
│   ├── add_transaction_dialog.dart
│   ├── add_reminder_dialog.dart
│   ├── add_budget_dialog.dart
│   ├── add_financial_record_dialog.dart
│   └── add_goal_dialog.dart
└── theme/                   # App theming
    └── app_theme.dart
```

## 🎨 Features in Detail

### Student Mode
- Specialized categories: Tuition, Books, Stationery, Hostel, Mess, Canteen, Pocket Money
- Monthly allowance tracking
- Daily burn rate calculation
- Days of runway forecast
- Scholarship and freelance income categories

### Budget System
- Overall monthly budget
- Category-specific budgets
- Progress visualization with color-coded indicators
- Warning thresholds (80%, 100%)
- Automatic carry-forward from previous month

### Bill Reminders
- One-time and recurring reminders
- Daily, weekly, monthly, quarterly, yearly recurrence
- Advance notification settings
- Mark as paid with linked expense creation
- Payment history tracking

### Financial Records
- Fixed Deposit tracking with maturity dates
- Insurance policy management
- Recurring Deposit tracking
- Interest rate and maturity amount calculations
- Maturity/renewal date alerts

### Data Management
- CSV export of all transactions
- Full JSON backup including settings, categories, budgets, reminders, financial records, and savings goals
- Restore from backup
- Reset all data with confirmation

## 🔒 Security Features

- **PIN Lock** - 4-digit PIN protection
- **Biometric Support** - Fingerprint/FaceID on supported devices
- **Auto-lock** - Configurable auto-lock timer
- **Security Question** - PIN recovery mechanism
- **Hashed Storage** - PIN and security answers are securely hashed
- **Hide Balances** - Option to hide all monetary amounts

## 🌐 Localization

Currently supports multiple currency symbols:
- INR (₹) - Indian Rupee
- USD ($) - US Dollar
- EUR (€) - Euro
- GBP (£) - British Pound
- JPY (¥) - Japanese Yen
- CAD (C$) - Canadian Dollar
- AUD (A$) - Australian Dollar
- KRW (₩) - South Korean Won

## 🐛 Known Issues

- Web platform has limited notification support
- Tree-shaking icons requires `--no-tree-shake-icons` flag for Android builds
- Some deprecated API warnings (non-breaking)

## 🚧 Future Improvements

### Planned Features
- [ ] Cloud synchronization (optional)
- [ ] Receipt scanning with OCR
- [ ] Multi-currency support with conversion
- [ ] Split expense tracking
- [ ] Recurring transaction automation
- [ ] Dark mode schedule
- [ ] Widget support for home screen
- [ ] Import bank statements (CSV/OFX)
- [ ] Advanced reporting with PDF export
- [ ] Tax summary generation
- [ ] Goal-based budget recommendations

### Technical Improvements
- [ ] Unit tests and integration tests
- [ ] End-to-end testing
- [ ] CI/CD pipeline setup
- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Internationalization (i18n) support
- [ ] Desktop applications (Windows, macOS, Linux)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📧 Contact

For questions, suggestions, or issues, please open an issue on GitHub.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- fl_chart library for beautiful charts
- flutter_local_notifications for notification handling
- The open-source community for various Flutter packages

---

<p align="center">
  <b>Built with ❤️ using Flutter</b>
</p>
