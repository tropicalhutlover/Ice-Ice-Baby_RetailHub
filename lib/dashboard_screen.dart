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
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoCard("Products", "$itemCount"),
            infoCard("Orders", "$orderCount"),
            infoCard("Revenue", "₱$revenue"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemListScreen(),
                  ),
                );
              },
              child: const Text("View Items"),
            ),

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

Widget infoCard(String title, String value) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(value),
    ),
  );
}