import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _passwordHidden = true;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Registration Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
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

            TextField(
              controller: _passwordController,
              obscureText: _passwordHidden,
              decoration: InputDecoration(
                labelText: 'Enter your password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordHidden
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordHidden = !_passwordHidden;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Enter your address',
                hintText: 'House #, Street, Barangay, City',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.house),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Enter your phone number',
                hintText: '+63 000-000-0000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_isRegistering) return;

                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final address = _addressController.text.trim();
                  final phone = _phoneController.text.trim();

                  if (name.isEmpty || email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All fields are required")),
                    );
                    return;
                  }

                  final db = DBHelper();
                  setState(() => _isRegistering = true);

                  try {
                    await db.registerUser(
                      name,
                      email,
                      password,
                      address: address,
                      phone: phone,
                    );
                    if (!context.mounted) return;
                    setState(() => _isRegistering = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Registered successfully")),
                    );
                    Navigator.pop(context);
                  } on FirebaseAuthException catch (e) {
                    if (!context.mounted) return;
                    setState(() => _isRegistering = false);
                    String message;
                    switch (e.code) {
                      case 'email-already-in-use':
                        message = 'Email already exists';
                        break;
                      case 'weak-password':
                        message = 'Password is too weak (minimum 6 characters)';
                        break;
                      case 'invalid-email':
                        message = 'Invalid email format';
                        break;
                      case 'operation-not-allowed':
                        message = 'Email/Password sign-in is not enabled in Firebase';
                        break;
                      default:
                        message = e.message ?? 'Registration failed. Please try again.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    setState(() => _isRegistering = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Registration failed. Please try again."),
                      ),
                    );
                  }
                },
                child: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Link to Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _isRegistering ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
