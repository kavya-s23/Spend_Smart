import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class SpendSmartHome extends StatefulWidget {
  final String userId;
  const SpendSmartHome({super.key, required this.userId});

  @override
  State<SpendSmartHome> createState() => _SpendSmartHomeState();
}

class _SpendSmartHomeState extends State<SpendSmartHome> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  double todaysTotal = 0;
  double dailyLimit = 1000;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodaysTotal();
  }

  // ✅ Fetch today's total and trigger smart alerts
  Future<void> _fetchTodaysTotal() async {
    final total = await _firestore.getTodaysTotal(widget.userId);
    setState(() {
      todaysTotal = total;
      isLoading = false;
    });

    _checkSpendingAlerts(); // ✅ Trigger alert after fetching data
  }

  // ✅ Smart alerts for overspending
  void _checkSpendingAlerts() {
    final usageRatio = todaysTotal / dailyLimit;

    if (usageRatio >= 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "⚠️ You've exceeded your daily spending limit!",
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } else if (usageRatio >= 0.8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "⚠️ Warning: You've reached 80% of your daily limit!",
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Progress bar color changes dynamically
  Color getProgressColor() {
    final ratio = todaysTotal / dailyLimit;
    if (ratio >= 1.0) return Colors.redAccent;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.indigo;
  }

  // ✅ Change daily limit popup
  void _changeDailyLimit() {
    final controller = TextEditingController(text: dailyLimit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Daily Limit"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Daily Limit (₹)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit > 0) {
                setState(() => dailyLimit = newLimit);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ✅ Add expense bottom sheet
  void _addExpenseForm() {
    final formKey = GlobalKey<FormState>();
    final category = TextEditingController();
    final amount = TextEditingController();
    final desc = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Expense",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter a category" : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount (₹)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter an amount" : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: desc,
                  decoration: const InputDecoration(
                    labelText: "Description (optional)",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await _firestore.addTransaction(
                        widget.userId,
                        category.text.trim(),
                        double.parse(amount.text.trim()),
                        desc.text.trim(),
                      );

                      await _fetchTodaysTotal(); // Refresh and trigger alerts
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add Expense"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    final progress = (todaysTotal / dailyLimit).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("SpendSmart - Daily Tracker"),
        actions: [
          IconButton(
            onPressed: _changeDailyLimit,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Spending",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("₹${todaysTotal.toStringAsFixed(2)} / ₹$dailyLimit"),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: getProgressColor(),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder(
                      stream: _firestore.getTransactions(widget.userId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("❌ Error loading data"),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = (snapshot.data! as dynamic).docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No transactions yet. Tap + to add one!",
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final date = (data['timestamp'] as Timestamp)
                                .toDate();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(
                                  data['category'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${data['description'] ?? ''}\n${date.toLocal()}",
                                ),
                                trailing: Text(
                                  "₹${data['amount']}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addExpenseForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
