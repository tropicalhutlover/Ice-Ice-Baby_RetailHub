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
  int _selectedIndex = 0;

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

    setState(() {
      itemCount = items.length;
      orderCount = orders.length;
      revenue = orders.fold(
        0,
            (sum, order) => sum + (order['total'] as num),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens = [
    DashboardContent(
      itemCount: itemCount,
      orderCount: orderCount,
      revenue: revenue,
      userId: widget.userId,
    ),
    const ItemListScreen(),
    const Center(child: Text('Account Screen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: const Text('Store Dashboard'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}


class DashboardContent extends StatelessWidget {
  final int itemCount;
  final int orderCount;
  final double revenue;
  final int userId;

  const DashboardContent({
    super.key,
    required this.itemCount,
    required this.orderCount,
    required this.revenue,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      'Store Manager',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Today\'s Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _statCard(
                    'Orders', orderCount.toString(), Icons.shopping_cart),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _statCard(
                    'Revenue', '₱${revenue.toStringAsFixed(2)}',
                    Icons.attach_money),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _statCard(
                    'Products', itemCount.toString(), Icons.inventory),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _statCard('Customers', '-', Icons.people),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton(context, 'Add Item', Icons.add, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Item clicked')),
                );
              }),
              _actionButton(context, 'View Orders', Icons.list, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderedListScreen(userId: userId),
                  ),
                );
              }),
              _actionButton(context, 'Settings', Icons.settings, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings clicked')),
                );
              }),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


Widget _statCard(String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}

Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    ) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
