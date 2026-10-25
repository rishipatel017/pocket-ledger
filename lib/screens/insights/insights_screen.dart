import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../state/app_state.dart';
import '../../models/transaction_item.dart';
import '../../services/insights_service.dart';
import '../../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  final AppState appState;

  const InsightsScreen({super.key, required this.appState});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DateTime _targetDate = DateTime.now();
  int _touchedPieIndex = -1;
  String _selectedChartType = 'donut'; // 'donut', 'bar', 'trend'

  void _previousMonth() {
    setState(() {
      _targetDate = DateTime(_targetDate.year, _targetDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_targetDate.year == now.year && _targetDate.month == now.month) return;
    setState(() {
      _targetDate = DateTime(_targetDate.year, _targetDate.month + 1, 1);
    });
  }

  void _showCategoryDrillDown(CategorySpend spend) {
    final txs = widget.appState.allTransactions.where((t) =>
        t.type == TransactionType.expense &&
        t.categoryId == spend.categoryId &&
        t.date.year == _targetDate.year &&
        t.date.month == _targetDate.month).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spend.categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${spend.count} transactions • ${spend.percentage.toStringAsFixed(1)}% of expenses',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.appState.formatAmount(spend.amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: txs.isEmpty
                    ? const Center(child: Text('No transactions in this period.'))
                    : ListView.builder(
                        itemCount: txs.length,
                        itemBuilder: (context, i) {
                          final tx = txs[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tx.title,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${DateFormat('dd MMM yyyy, hh:mm a').format(tx.date)} • ${tx.paymentMethod.displayName}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.darkTextSecondary),
                            ),
                            trailing: Text(
                              widget.appState.formatAmount(tx.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.expenseRed,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions for target month
    final targetMonthTxs = widget.appState.allTransactions.where((t) =>
        t.date.year == _targetDate.year && t.date.month == _targetDate.month);

    final monthIncome = targetMonthTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final monthExpense = targetMonthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final monthSavings = monthIncome - monthExpense;
    final savingsRate = monthIncome > 0 ? (monthSavings / monthIncome) * 100 : 0.0;

    final categorySpans = InsightsService.calculateCategorySpans(
      transactions: widget.appState.allTransactions,
      targetDate: _targetDate,
    );

    final insights = InsightsService.generateInsights(
      transactions: widget.appState.allTransactions,
      budgets: widget.appState.budgets,
      settings: widget.appState.settings,
      targetDate: _targetDate,
    );

    final monthComparison = InsightsService.compareMonths(
      transactions: widget.appState.allTransactions,
      targetDate: _targetDate,
    );

    final dailySpends = InsightsService.calculateDailyTrend(
      transactions: widget.appState.allTransactions,
      targetDate: _targetDate,
      days: 7,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Navigator Bar
            _buildMonthNavigator(),
            const SizedBox(height: 16),

            // Summary Metric Cards Grid (Total Income, Total Expense, Net Savings, Savings Rate)
            _buildSummaryMetrics(
              monthIncome,
              monthExpense,
              monthSavings,
              savingsRate,
            ),
            const SizedBox(height: 18),

            // Chart Type Selector
            _buildChartSelector(),
            const SizedBox(height: 14),

            // Interactive Chart Container
            _buildChartDisplay(
              categorySpans,
              dailySpends,
              monthExpense,
              isDark,
            ),
            const SizedBox(height: 18),

            // Month-over-Month Comparison Card
            _buildMonthComparisonCard(monthComparison),
            const SizedBox(height: 18),

            // Spending Insights Observation Cards
            _buildInsightsList(insights),
            const SizedBox(height: 18),

            // Category Breakdown List with Drill-Down
            _buildCategoryBreakdownList(categorySpans),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final now = DateTime.now();
    final isCurrentMonth =
        _targetDate.year == now.year && _targetDate.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_targetDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(
    double income,
    double expense,
    double savings,
    double savingsRate,
  ) {
    return Row(
      children: [
        Expanded(
          child: _metricBox(
            title: 'Income',
            amount: income,
            color: AppColors.incomeGreen,
            icon: Icons.south_west,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricBox(
            title: 'Expenses',
            amount: expense,
            color: AppColors.expenseRed,
            icon: Icons.north_east,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricBox(
            title: 'Savings',
            amount: savings,
            color: savings >= 0 ? AppColors.primaryMint : AppColors.expenseCoral,
            icon: Icons.savings_outlined,
            subtitle: '${savingsRate.toStringAsFixed(0)}% saved',
          ),
        ),
      ],
    );
  }

  Widget _metricBox({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.appState.formatAmount(amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _chartTab('donut', 'Categories (Donut)', Icons.pie_chart_outline),
          _chartTab('bar', 'Daily Spends (Bar)', Icons.bar_chart),
          _chartTab('trend', 'Cash Trend (Line)', Icons.show_chart),
        ],
      ),
    );
  }

  Widget _chartTab(String type, String label, IconData icon) {
    final isSelected = _selectedChartType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChartType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMint : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartDisplay(
    List<CategorySpend> categorySpans,
    List<DailySpend> dailySpends,
    double totalExpense,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          if (_selectedChartType == 'donut')
            _buildDonutChart(categorySpans, totalExpense)
          else if (_selectedChartType == 'bar')
            _buildBarChart(dailySpends, isDark)
          else
            _buildLineTrendChart(dailySpends, isDark),
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<CategorySpend> list, double totalExpense) {
    if (list.isEmpty || totalExpense <= 0) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.darkTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No expenses recorded for this month.',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add transactions to see category breakdown',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      Colors.deepOrangeAccent,
      Colors.teal,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.amber,
      Colors.cyan,
      Colors.green,
      Colors.indigoAccent,
      Colors.blueGrey,
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 52,
                  sections: List.generate(list.length, (i) {
                    final isTouched = i == _touchedPieIndex;
                    final fontSize = isTouched ? 14.0 : 11.0;
                    final radius = isTouched ? 50.0 : 42.0;
                    final item = list[i];
                    final color = colors[i % colors.length];

                    return PieChartSectionData(
                      color: color,
                      value: item.amount,
                      title: isTouched
                          ? '${item.percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  Text(
                    widget.appState.formatAmount(totalExpense),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap any category below to drill down into transactions:',
          style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<DailySpend> dailySpends, bool isDark) {
    if (dailySpends.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.darkTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No daily spending data available',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add transactions to see daily trends',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    final maxSpend = dailySpends.fold<double>(
      100.0,
      (max, e) => e.expense > max ? e.expense : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Expense Trend',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxSpend * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = dailySpends[group.x.toInt()];
                    return BarTooltipItem(
                      '${item.label}\n${widget.appState.formatAmount(rod.toY)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < dailySpends.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dailySpends[idx].label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(dailySpends.length, (i) {
                final d = dailySpends[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: d.expense,
                      color: AppColors.expenseRed,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineTrendChart(List<DailySpend> dailySpends, bool isDark) {
    final maxVal = dailySpends.fold<double>(
      100.0,
      (max, e) {
        final higher = e.expense > e.income ? e.expense : e.income;
        return higher > max ? higher : max;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Income vs Expense Trend',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                _legendDot(AppColors.incomeGreen, 'Income'),
                const SizedBox(width: 8),
                _legendDot(AppColors.expenseRed, 'Expense'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              maxY: maxVal * 1.25,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < dailySpends.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dailySpends[idx].label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Income Line
                LineChartBarData(
                  spots: List.generate(
                    dailySpends.length,
                    (i) => FlSpot(i.toDouble(), dailySpends[i].income),
                  ),
                  isCurved: true,
                  color: AppColors.incomeGreen,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                // Expense Line
                LineChartBarData(
                  spots: List.generate(
                    dailySpends.length,
                    (i) => FlSpot(i.toDouble(), dailySpends[i].expense),
                  ),
                  isCurved: true,
                  color: AppColors.expenseRed,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary),
        ),
      ],
    );
  }

  Widget _buildMonthComparisonCard(MonthComparison comp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expDelta = comp.expenseChangePercent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows,
                  color: AppColors.primaryMint, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Month-over-Month Comparison',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Month',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                  Text(
                    widget.appState.formatAmount(comp.currentMonthExpense),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (expDelta > 0
                          ? AppColors.expenseRed
                          : AppColors.incomeGreen)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      expDelta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: expDelta > 0
                          ? AppColors.expenseRed
                          : AppColors.incomeGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${expDelta.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: expDelta > 0
                            ? AppColors.expenseRed
                            : AppColors.incomeGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Previous Month',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                  Text(
                    widget.appState.formatAmount(comp.previousMonthExpense),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(List<SpendingInsight> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryMint, size: 20),
            SizedBox(width: 8),
            Text(
              'Spending Insights & Observations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: insight.color.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(insight.icon, color: insight.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: insight.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight.message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryBreakdownList(List<CategorySpend> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Category Breakdown (Tap to drill down)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Text(
            'No expense data recorded for this month.',
            style: TextStyle(color: AppColors.darkTextSecondary),
          )
        else
          ...list.map((item) {
            return InkWell(
              onTap: () => _showCategoryDrillDown(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${item.count} items • ${item.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.appState.formatAmount(item.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.expenseRed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
