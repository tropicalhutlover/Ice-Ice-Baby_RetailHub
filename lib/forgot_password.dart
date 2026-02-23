import 'package:flutter/material.dart';
import '../db_helper.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isNewPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  String _feedbackMessage = "";

  void _updatePassword() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _feedbackMessage = "Please fill in all fields.";
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _feedbackMessage = "Passwords do not match.";
      });
      return;
    }

    final db = DBHelper();
    final updatedRows = await db.updatePassword(email, newPassword);

    if (updatedRows > 0) {
      setState(() {
        _feedbackMessage = "Password Updated!";
      });
      _emailController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      setState(() {
        _feedbackMessage = "User with this email does not exist.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),

            // Instruction Text
            const Text(
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Enter your email and new password to reset.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildPasswordTextField(
              controller: _newPasswordController,
              label: 'Enter your new password',
              hint: '8–16 characters',
              obscureText: _isNewPasswordHidden,
              toggleVisibility: () {
                setState(() {
                  _isNewPasswordHidden = !_isNewPasswordHidden;
                });
              },
            ),
            const SizedBox(height: 20),

            _buildPasswordTextField(
              controller: _confirmPasswordController,
              label: 'Re-enter your new password',
              hint: '8–16 characters',
              obscureText: _isConfirmPasswordHidden,
              toggleVisibility: () {
                setState(() {
                  _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                });
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _feedbackMessage,
              style: TextStyle(
                color: _feedbackMessage == "Password Updated!"
                    ? Colors.green
                    : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.lock),
      ),
    );
  }
}
