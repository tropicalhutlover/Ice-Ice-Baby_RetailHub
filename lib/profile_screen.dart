import 'package:flutter/material.dart';
import 'db_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final nameController =
    TextEditingController(text: (data['name'] ?? '').toString());
    final emailController =
    TextEditingController(text: (data['email'] ?? '').toString());
    final addressController =
    TextEditingController(text: (data['address'] ?? '').toString());
    final phoneController =
    TextEditingController(text: (data['phone'] ?? '').toString());

    final userId = data['id'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper().updateUserProfile(
                userId: userId,
                name: nameController.text,
                email: emailController.text,
                address: addressController.text,
                phone: phoneController.text,
              );

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: DBHelper().watchCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load profile.'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No profile data found.'),
            );
          }

          final name = (data['name'] ?? '').toString();
          final email = (data['email'] ?? '').toString();
          final address = (data['address'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final userId = data['id']?.toString() ?? '-';

          Widget tile(String label, String value, IconData icon) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(icon, color: Colors.blue),
                title: Text(label),
                subtitle: Text(value.isEmpty ? '-' : value),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 42, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                tile('Name', name, Icons.badge_outlined),
                tile('Email', email, Icons.email_outlined),
                tile('Address', address, Icons.home_outlined),
                tile('Phone', phone, Icons.phone_outlined),
                tile('User ID', userId, Icons.perm_identity_outlined),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditDialog(context, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
