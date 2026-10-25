# Contributing to PocketLedger

Thank you for your interest in contributing to PocketLedger! This document provides guidelines and instructions for contributing to the project.

## 🤝 How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Description**: A clear and concise description of the bug
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Screenshots**: If applicable, add screenshots to help explain the problem
- **Environment**: 
  - OS: [e.g., Windows 10, macOS 13, Ubuntu 22.04]
  - Flutter version: [run `flutter --version`]
  - Device/emulator: [e.g., iPhone 14, Pixel 5]

### Suggesting Enhancements

Enhancement suggestions are welcome! When suggesting an enhancement:

- Use a clear and descriptive title
- Provide a detailed description of the suggested enhancement
- Explain why this enhancement would be useful
- Provide examples of how the enhancement would be used
- List any alternatives or features you've considered

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/pocketledger.git
   cd pocketledger
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the code style guidelines
   - Add tests for new features
   - Update documentation as needed
   - Add comments to complex code

4. **Commit your changes**
   ```bash
   git commit -m "feat: add feature description"
   ```
   
   Use conventional commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `style:` for code style changes (formatting, etc.)
   - `refactor:` for code refactoring
   - `test:` for adding or updating tests
   - `chore:` for maintenance tasks

5. **Push to the branch**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of your changes
   - Reference any related issues
   - Include screenshots if applicable
   - Ensure all CI checks pass

## 📋 Development Setup

### Prerequisites
- Flutter SDK 3.13.5 or higher
- Dart 3.13.5 or higher
- Android Studio / VS Code with Flutter extension
- Git

### Setup Instructions

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
   flutter run
   ```

4. **Run tests**
   ```bash
   flutter test
   ```

5. **Run analyzer**
   ```bash
   flutter analyze
   ```

## 🎨 Code Style Guidelines

### Dart Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` to format code
- Keep lines under 80 characters when possible
- Use meaningful variable and function names
- Add comments for complex logic

### Flutter Best Practices
- Use `const` constructors where possible
- Prefer `final` over `const` for local variables
- Use `FutureBuilder` and `StreamBuilder` for async operations
- Separate UI from business logic
- Use `ValueNotifier` or `ChangeNotifier` for state management
- Avoid using `setState` when possible

### File Organization
- Keep files focused on a single responsibility
- Group related files in directories
- Use descriptive file names in snake_case
- Keep public APIs well-documented

## 🧪 Testing

### Writing Tests
- Write unit tests for service layer methods
- Write widget tests for UI components
- Write integration tests for critical user flows
- Aim for at least 70% code coverage

### Test Structure
```dart
void main() {
  group('FeatureName', () {
    test('should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## 📖 Documentation

### Code Documentation
- Document public APIs with dartdoc comments
- Include examples for complex functions
- Explain non-obvious logic
- Keep documentation up to date

### README Updates
- Update README.md when adding new features
- Update screenshots when UI changes
- Update version numbers in documentation
- Update CHANGELOG.md for significant changes

## 🐛 Debugging

### Common Issues

#### Build Errors
- Run `flutter clean` to clear build cache
- Run `flutter pub get` to refresh dependencies
- Check Flutter version compatibility
- Verify Android/iOS SDK installation

#### Analyzer Errors
- Run `flutter analyze` to see all issues
- Fix critical errors before submitting PR
- Address warnings when possible
- Update deprecated APIs

#### Runtime Errors
- Check device logs with `flutter logs`
- Add debug print statements
- Use debugger breakpoints
- Test on multiple devices

## 🚀 Release Process

### Version Bumping
1. Update version in `pubspec.yaml`
2. Update version in `android/app/build.gradle`
3. Update version in `ios/Runner/Info.plist`
4. Update CHANGELOG.md
5. Create a git tag

### Building Releases
```bash
# Android APK
flutter build apk --release --no-tree-shake-icons

# Android App Bundle
flutter build appbundle --release --no-tree-shake-icons

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## 📝 Issue Templates

### Bug Report Template
```markdown
**Description**
A clear description of the bug

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected Behavior**
What you expected to happen

**Screenshots**
If applicable, add screenshots

**Environment**
- OS: [e.g., Windows 10]
- Flutter version: [e.g., 3.13.5]
- Device: [e.g., iPhone 14]

**Additional Context**
Add any other context about the problem
```

### Feature Request Template
```markdown
**Description**
A clear description of the feature

**Use Case**
Describe the use case for this feature

**Proposed Solution**
Describe how you think this could be implemented

**Alternatives**
Describe any alternative solutions or features you've considered

**Additional Context**
Add any other context or screenshots
```

## 🎯 Areas for Contribution

### High Priority
- [ ] Add unit tests for service layer
- [ ] Add widget tests for screens
- [ ] Improve error handling
- [ ] Add accessibility features

### Medium Priority
- [ ] Add internationalization support
- [ ] Add dark mode schedule
- [ ] Improve performance optimization
- [ ] Add more chart types

### Low Priority
- [ ] Add receipt scanning
- [ ] Add cloud sync
- [ ] Add multi-currency support
- [ ] Add export to PDF

## 💬 Communication

- For questions, use GitHub Discussions
- For bugs, use GitHub Issues
- For security issues, please email [your email]

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to PocketLedger! 🎉
