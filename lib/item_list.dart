import 'package:flutter/material.dart';
import 'db_helper.dart';

class ItemListScreen extends StatefulWidget {
  final int userId;

  const ItemListScreen({super.key, required this.userId});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Map<String, dynamic>> items = [];
  final Map<int, int> quantities = {};

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    items = await DBHelper().getItems();

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
        final price = (item['discountedPrice'] ?? 0) as num;

        await db.addOrder(
          widget.userId,
          orderGroupId,
          item['name'],
          qty,
          qty * price.toDouble(),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => _itemCard(items[i]),
            ),
          ),
          ElevatedButton(onPressed: placeOrder, child: const Text('Order')),
        ],
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final qty = quantities[item['id']] ?? 0;

    return Card(
      child: ListTile(
        title: Text(item['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item['category']}'),
            Text('Price: ₱${item['discountedPrice']}'),
            Text('Stock: ${item['stockQty']}'),
            Text(item['description'] ?? ''),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
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
            Text(qty.toString()),
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
      ),
    );
  }
}
