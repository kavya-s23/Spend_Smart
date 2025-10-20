import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatefulWidget {
  final String userId;
  final double dailyLimit; // ✅ receives limit from home
  const AnalyticsScreen({
    super.key,
    required this.userId,
    required this.dailyLimit,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<int, double> monthlyData = {};
  Map<String, double> categoryData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      Map<int, double> tempMonthly = {};
      Map<String, double> tempCategory = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['timestamp'] as Timestamp).toDate();
        final day = date.day;
        final amount = (data['amount'] ?? 0).toDouble();
        final category = data['category'] ?? 'Other';

        tempMonthly[day] = (tempMonthly[day] ?? 0) + amount;
        tempCategory[category] = (tempCategory[category] ?? 0) + amount;
      }

      setState(() {
        monthlyData = tempMonthly;
        categoryData = tempCategory;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching analytics: $e");
    }
  }

  Widget _buildMonthlyChart() {
    if (monthlyData.isEmpty) {
      return const Center(child: Text("No spending data this month"));
    }

    final maxY = ([
      ...monthlyData.values,
      widget.dailyLimit,
    ]).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 24,
      ), // ✅ spacing added
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + 500,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            // 🧭 X-axis labels (Days)
            bottomTitles: AxisTitles(
              axisNameSize: 24,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Day of Month',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 💰 Y-axis labels (₹)
            leftTitles: AxisTitles(
              axisNameSize: 24,
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY / 5).roundToDouble(),
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '₹${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Amount (₹)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // 🟥 Limit line (visual indicator for daily limit)
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: widget.dailyLimit,
                color: Colors.redAccent,
                strokeWidth: 2,
                dashArray: [6, 6],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.centerLeft,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) =>
                      "Daily Limit ₹${widget.dailyLimit.toInt()}",
                ),
              ),
            ],
          ),

          // 🧱 Bars for each day
          barGroups: monthlyData.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: entry.value > widget.dailyLimit
                      ? Colors.red
                      : Colors.indigo,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800), // ✅ animation
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    if (categoryData.isEmpty) {
      return const Center(child: Text("No category data available"));
    }

    return PieChart(
      PieChartData(
        sections: categoryData.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            title: '₹${entry.value.toInt()}',
            color: Colors
                .primaries[entry.key.hashCode % Colors.primaries.length]
                .shade400,
            radius: 80,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Spending Analytics"),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📈 Spending Trends (This Month)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: _buildMonthlyChart(),
                  ), // ✅ adjusted height
                  const SizedBox(height: 32),
                  const Text(
                    "🍰 Category Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 250, child: _buildCategoryPieChart()),
                ],
              ),
            ),
    );
  }
}
