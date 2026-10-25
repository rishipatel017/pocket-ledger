# Changelog

All notable changes to the PocketLedger project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of PocketLedger
- Expense and income tracking with full CRUD operations
- 20+ default categories with icons and colors
- Student mode with specialized categories
- Financial dashboard with weekly/monthly views
- Budget management with progress tracking
- Bill reminders with recurring support
- Fixed Deposit, Recurring Deposit, and Insurance tracking
- Savings goals with progress visualization
- Spending insights and analytics
- Financial calendar with event tracking
- Interactive charts (Donut, Bar, Line)
- PIN lock security with biometric support
- CSV export and JSON backup/restore
- Currency selection (8 currencies)
- Theme switching (light/dark/system)
- Loading screen with animated logo
- Automatic budget carry-forward from previous month
- Input validation for all forms
- FD-related reminder categories

### Changed
- Improved demo data to be more realistic
- Enhanced calendar with FD/Financial record sections
- Improved chart empty states with helpful messages
- Fixed notification service API compatibility

### Fixed
- Fixed ListTile background color warnings
- Fixed data seeding to only occur on first run
- Fixed loading screen overflow on small screens
- Fixed IconData tree-shaking for Android builds
- Fixed notification service for flutter_local_notifications v22+
- Fixed BuildContext across async gaps warnings

## [1.0.0] - 2026-10-18

### Added
- Initial project setup
- Core MVP features
- Basic UI implementation
- Local storage integration
- Demo data seeding
