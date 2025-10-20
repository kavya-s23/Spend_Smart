import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SpendSmartApp());
}

class SpendSmartApp extends StatefulWidget {
  const SpendSmartApp({super.key});

  @override
  State<SpendSmartApp> createState() => _SpendSmartAppState();
}

class _SpendSmartAppState extends State<SpendSmartApp> {
  int _currentIndex = 0;
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // 🔹 If not signed in, show Google login screen
    if (user == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _auth.signInWithGoogle();
                setState(() {});
              },
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ✅ Corrected: Added dailyLimit parameter
    final screens = [
      SpendSmartHome(userId: user.uid),
      AnalyticsScreen(userId: user.uid, dailyLimit: 1000),
      ProfileScreen(user: user),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
