import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final bool isExpense;
  final bool isStudentOnly;
  final bool isCustom;

  CategoryItem({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    required this.isExpense,
    this.isStudentOnly = false,
    this.isCustom = false,
  });

  // ignore: prefer_const_constructors
  IconData get iconData => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
      );

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'colorValue': colorValue,
        'isExpense': isExpense,
        'isStudentOnly': isStudentOnly,
        'isCustom': isCustom,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCodePoint: json['iconCodePoint'] as int,
        iconFontFamily: json['iconFontFamily'] as String?,
        colorValue: json['colorValue'] as int,
        isExpense: json['isExpense'] as bool? ?? true,
        isStudentOnly: json['isStudentOnly'] as bool? ?? false,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  // Static constant icons for tree-shaking
  static const Map<String, IconData> _iconMap = {
    'food': Icons.restaurant,
    'groceries': Icons.shopping_basket,
    'transport': Icons.directions_bus,
    'shopping': Icons.shopping_bag,
    'rent': Icons.home,
    'utilities': Icons.bolt,
    'entertainment': Icons.movie,
    'healthcare': Icons.local_hospital,
    'subscriptions': Icons.subscriptions,
    'education': Icons.school,
    'tuition': Icons.school_outlined,
    'books': Icons.menu_book,
    'hostel_mess': Icons.night_shelter,
    'canteen': Icons.fastfood,
    'salary': Icons.account_balance_wallet,
    'pocket_money': Icons.payments,
    'scholarship': Icons.military_tech,
    'freelance': Icons.laptop_mac,
    'investment_income': Icons.trending_up,
    'other_income': Icons.attach_money,
    'other_expense': Icons.more_horiz,
    'fd_maturity': Icons.account_balance,
    'insurance_renewal': Icons.security,
    'rd_renewal': Icons.savings,
  };

  static IconData getIconForId(String id) {
    return _iconMap[id] ?? Icons.more_horiz;
  }

  static List<CategoryItem> get defaultCategories => [
        // Expenses
        CategoryItem(
          id: 'food',
          name: 'Food & Dining',
          iconCodePoint: _iconMap['food']!.codePoint,
          colorValue: Colors.deepOrangeAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'groceries',
          name: 'Groceries',
          iconCodePoint: _iconMap['groceries']!.codePoint,
          colorValue: Colors.teal.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'transport',
          name: 'Transport',
          iconCodePoint: _iconMap['transport']!.codePoint,
          colorValue: Colors.blueAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'shopping',
          name: 'Shopping',
          iconCodePoint: _iconMap['shopping']!.codePoint,
          colorValue: Colors.pinkAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'rent',
          name: 'Rent & Housing',
          iconCodePoint: _iconMap['rent']!.codePoint,
          colorValue: Colors.indigoAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'utilities',
          name: 'Bills & Utilities',
          iconCodePoint: _iconMap['utilities']!.codePoint,
          colorValue: Colors.amber.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'entertainment',
          name: 'Entertainment',
          iconCodePoint: _iconMap['entertainment']!.codePoint,
          colorValue: Colors.purpleAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'healthcare',
          name: 'Healthcare',
          iconCodePoint: _iconMap['healthcare']!.codePoint,
          colorValue: Colors.redAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'subscriptions',
          name: 'Subscriptions',
          iconCodePoint: _iconMap['subscriptions']!.codePoint,
          colorValue: Colors.deepPurpleAccent.value,
          isExpense: true,
        ),
        CategoryItem(
          id: 'education',
          name: 'Education',
          iconCodePoint: _iconMap['education']!.codePoint,
          colorValue: Colors.cyan.value,
          isExpense: true,
        ),

        // Student Special Expenses
        CategoryItem(
          id: 'tuition',
          name: 'Tuition & College Fees',
          iconCodePoint: _iconMap['tuition']!.codePoint,
          colorValue: Colors.blue.value,
          isExpense: true,
          isStudentOnly: true,
        ),
        CategoryItem(
          id: 'books',
          name: 'Books & Stationery',
          iconCodePoint: _iconMap['books']!.codePoint,
          colorValue: Colors.lightGreen.value,
          isExpense: true,
          isStudentOnly: true,
        ),
        CategoryItem(
          id: 'hostel_mess',
          name: 'Hostel & Mess',
          iconCodePoint: _iconMap['hostel_mess']!.codePoint,
          colorValue: Colors.orange.value,
          isExpense: true,
          isStudentOnly: true,
        ),
        CategoryItem(
          id: 'canteen',
          name: 'Campus Canteen & Hangouts',
          iconCodePoint: _iconMap['canteen']!.codePoint,
          colorValue: Colors.deepOrange.value,
          isExpense: true,
          isStudentOnly: true,
        ),

        // Income Categories
        CategoryItem(
          id: 'salary',
          name: 'Salary',
          iconCodePoint: _iconMap['salary']!.codePoint,
          colorValue: Colors.green.value,
          isExpense: false,
        ),
        CategoryItem(
          id: 'pocket_money',
          name: 'Pocket Money / Allowance',
          iconCodePoint: _iconMap['pocket_money']!.codePoint,
          colorValue: Colors.lightGreenAccent.shade700.value,
          isExpense: false,
          isStudentOnly: true,
        ),
        CategoryItem(
          id: 'scholarship',
          name: 'Scholarship / Grant',
          iconCodePoint: _iconMap['scholarship']!.codePoint,
          colorValue: Colors.amber.shade700.value,
          isExpense: false,
          isStudentOnly: true,
        ),
        CategoryItem(
          id: 'freelance',
          name: 'Freelance & Side Hustle',
          iconCodePoint: _iconMap['freelance']!.codePoint,
          colorValue: Colors.indigo.value,
          isExpense: false,
        ),
        CategoryItem(
          id: 'investment_income',
          name: 'Investments / Returns',
          iconCodePoint: _iconMap['investment_income']!.codePoint,
          colorValue: 0xFF00C853,
          isExpense: false,
        ),
        CategoryItem(
          id: 'other_income',
          name: 'Other Income',
          iconCodePoint: _iconMap['other_income']!.codePoint,
          colorValue: Colors.tealAccent.shade700.value,
          isExpense: false,
        ),
        CategoryItem(
          id: 'other_expense',
          name: 'Other Expenses',
          iconCodePoint: _iconMap['other_expense']!.codePoint,
          colorValue: Colors.blueGrey.value,
          isExpense: true,
        ),

        // FD & Financial Record Categories
        CategoryItem(
          id: 'fd_maturity',
          name: 'FD Maturity',
          iconCodePoint: _iconMap['fd_maturity']!.codePoint,
          colorValue: Colors.teal.value,
          isExpense: false,
        ),
        CategoryItem(
          id: 'insurance_renewal',
          name: 'Insurance Renewal',
          iconCodePoint: _iconMap['insurance_renewal']!.codePoint,
          colorValue: Colors.indigo.value,
          isExpense: false,
        ),
        CategoryItem(
          id: 'rd_renewal',
          name: 'RD Renewal',
          iconCodePoint: _iconMap['rd_renewal']!.codePoint,
          colorValue: Colors.green.value,
          isExpense: false,
        ),
      ];
}

