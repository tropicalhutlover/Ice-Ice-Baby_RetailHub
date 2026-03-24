import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard.dart';
import 'register_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Login Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Email
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

            // Password
            TextField(
              controller: _passwordController,
              obscureText: _passwordHidden,
              decoration: InputDecoration(
                labelText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            const SizedBox(height: 30),

            // Login
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
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  final db = DBHelper();
                  final user = await db.login(email, password);

                  if (user != null && context.mounted) {
                    final isAdmin = (user['isAdmin'] ?? 0) == 1;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isAdmin
                            ? AdminDashboardScreen(
                          userId: user['id'],
                          userName: user['name'] ?? 'Admin',
                        )
                            : DashboardScreen(
                          userId: user['id'],
                          userName: user['name'] ?? '',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("User does not exist or wrong password"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Create Account
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Forgot Password
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPassword(),
                  ),
                );
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
