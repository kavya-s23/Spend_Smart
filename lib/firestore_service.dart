import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ➕ Add a new transaction
  Future<void> addTransaction(
    String userId,
    String category,
    double amount,
    String description,
  ) async {
    try {
      await _db.collection('transactions').add({
        'userId': userId,
        'category': category,
        'amount': amount,
        'description': description,
        'timestamp': DateTime.now(),
      });
      print("✅ Transaction added successfully!");
    } catch (e) {
      print("❌ Error adding transaction: $e");
      rethrow;
    }
  }

  // 🧾 Fetch all transactions for a given user
  Stream<QuerySnapshot> getTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 💰 Get today's total spending
  Future<double> getTodaysTotal(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['amount'] ?? 0).toDouble();
      }

      print("💸 Total spent today: ₹$total");
      return total;
    } catch (e) {
      print("❌ Error fetching today's total: $e");
      return 0;
    }
  }

  // 📈 Save user-specific daily limit
  Future<void> setDailyLimit(String userId, double limit) async {
    try {
      await _db.collection('users').doc(userId).set({
        'dailyLimit': limit,
      }, SetOptions(merge: true));
      print("✅ Daily limit updated: ₹$limit");
    } catch (e) {
      print("❌ Error saving daily limit: $e");
    }
  }

  // 📉 Fetch user's daily limit
  Future<double> getDailyLimit(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('dailyLimit')) {
        return (doc['dailyLimit'] ?? 1000).toDouble();
      }
      return 1000; // default
    } catch (e) {
      print("❌ Error fetching daily limit: $e");
      return 1000;
    }
  }

  // 📊 Get spending per day for current month (for bar chart)
  Future<Map<int, double>> getMonthlySpending(String userId) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      final snapshot = await _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThan: end)
          .get();

      final Map<int, double> data = {};
      for (var doc in snapshot.docs) {
        final d = (doc['timestamp'] as Timestamp).toDate().day;
        data[d] = (data[d] ?? 0) + (doc['amount'] ?? 0);
      }

      print("📊 Monthly spending data fetched successfully.");
      return data;
    } catch (e) {
      print("❌ Error fetching monthly data: $e");
      return {};
    }
  }

  // 🍰 Category totals for pie chart
  Future<Map<String, double>> getCategoryTotals(String userId) async {
    try {
      final snapshot = await _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, double> totals = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Other';
        final amount = (data['amount'] ?? 0).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }

      print("🍰 Category totals fetched successfully.");
      return totals;
    } catch (e) {
      print("❌ Error fetching category totals: $e");
      return {};
    }
  }
}
