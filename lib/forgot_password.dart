import 'package:flutter/material.dart';
import 'db_helper.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  String _feedbackMessage = "";

  void _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _feedbackMessage = "Please enter your email.";
      });
      return;
    }

    try {
      await DBHelper().sendPasswordResetEmail(email);

      setState(() {
        _feedbackMessage = "Password reset email sent.";
      });

      _emailController.clear();
    } catch (e) {
      setState(() {
        _feedbackMessage = "Failed to send reset email.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendResetLink,
              child: const Text('Send Reset Link'),
            ),
            const SizedBox(height: 20),
            Text(_feedbackMessage),
          ],
        ),
      ),
    );
  }
}
