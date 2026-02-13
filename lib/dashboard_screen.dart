import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'item_list.dart';
import 'ordered_list.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int itemCount = 0;
  int orderCount = 0;
  double revenue = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  void loadStats() async {
    final db = DBHelper();

    final items = await db.getItems();
    final orders = await db.getOrders(widget.userId);

    itemCount = items.length;
    orderCount = orders.length;
    revenue = orders.fold(
      0,
          (sum, order) => sum + (order['total'] as num),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome Card (UI change only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action Buttons (same navigation as before)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemListScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Text("View Products"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderedListScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Text("View Orders"),
            ),
          ],
        ),
      ),
    );
  }
}
