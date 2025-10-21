import 'package:bhajan_app/DashBoard/Screens/auth/login_page.dart';
import 'package:bhajan_app/service/auth_service.dart';
import 'package:flutter/material.dart';

class LogOutScreen extends StatefulWidget {
  const LogOutScreen({super.key});

  @override
  State<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends State<LogOutScreen> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    final authService = AuthService();

    try {
      await authService.signOut(); // Call the existing signOut() method
    } catch (e) {
      // Optional: Show error if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }

    // Optional: wait briefly for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to LoginPage
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(), // While logging out
      ),
    );
  }
}
