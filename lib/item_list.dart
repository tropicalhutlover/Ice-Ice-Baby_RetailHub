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
        final price =
            double.tryParse(item['discountedPrice'].toString()) ?? 0;

        await db.addOrder(
          widget.userId,
          orderGroupId,
          item['name'],
          qty,
          qty * price,
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
    final id = item['id'];
    final qty = quantities[id] ?? 0;

    int stock = int.tryParse(item['stockQty'].toString()) ?? 0;

    return Card(
      child: ListTile(
        title: Text('${item['name']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item['category']}'),
            Text('Base Price: ₱${item['basePrice']}'),
            Text('Discounted Price: ₱${item['discountedPrice']}'),
            Text('Stock: $stock'),

            if (stock == 0)
              const Text(
                'Out of Stock',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),

            Text('Description: ${item['description'] ?? ''}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: qty > 0
                  ? () async {
                setState(() {
                  quantities[id] = qty - 1;
                  stock += 1;
                  item['stockQty'] = stock.toString();
                });

                await DBHelper().updateItem(id, {
                  'stockQty': stock.toString(),
                });
              }
                  : null,
            ),

            Text(qty.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: stock > 0
                  ? () async {
                setState(() {
                  quantities[id] = qty + 1;
                  stock -= 1;
                  item['stockQty'] = stock.toString();
                });

                await DBHelper().updateItem(id, {
                  'stockQty': stock.toString(),
                });
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
