import 'package:flutter/material.dart';
import 'db_helper.dart';

class ItemListScreen extends StatefulWidget {
  final int userId;

  const ItemListScreen({super.key, required this.userId});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List items = [];
  final Map<int, int> quantities = {};

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final db = DBHelper();

    if ((await db.getItems()).isEmpty) {
      await db.insertItem("Cookies & Cream", 450);
      await db.insertItem("Mango Overload", 800);
      await db.insertItem("Coffee", 450);
      await db.insertItem("Rocky Road", 650);
    }

    items = await db.getItems();

    for (var item in items) {
      quantities[item['id']] = 0;
    }

    setState(() {});
  }

  void placeOrder() async {
    final db = DBHelper();
    final orderGroupId = DateTime.now().millisecondsSinceEpoch;

    for (var item in items) {
      final qty = quantities[item['id']] ?? 0;
      if (qty > 0) {
        final total = qty * (item['price'] as num).toDouble();
        await db.addOrder(
          widget.userId,
          orderGroupId,
          item['name'],
          qty,
          total,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item List'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _itemCard(items[index]);
              },
            ),
          ),

          // Order Button
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.local_grocery_store),
                label: const Text(
                  'Order Ice Cream',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(Map item) {
    final qty = quantities[item['id']] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.icecream,
                size: 40,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₱${item['price']}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: qty > 0
                      ? () {
                    setState(() {
                      quantities[item['id']] = qty - 1;
                    });
                  }
                      : null,
                ),
                Text(
                  qty.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      quantities[item['id']] = qty + 1;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
