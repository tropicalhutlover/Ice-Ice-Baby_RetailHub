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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Forgot your Password?',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
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
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Update Password'),
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
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
      ),
    );
  }
}
