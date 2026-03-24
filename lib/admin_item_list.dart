import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_ice_cream_screen.dart';

class AdminItemListScreen extends StatefulWidget {
  const AdminItemListScreen({super.key});

  @override
  State<AdminItemListScreen> createState() => _AdminItemListScreenState();
}

class _AdminItemListScreenState extends State<AdminItemListScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DBHelper().getItems();
    setState(() => _items = items);
  }

  Future<void> _deleteItem(Map item) async {
    await DBHelper().deleteItem(item['id']);
    _loadItems();
  }

  void _showEditDialog(Map item) {
    final name = TextEditingController(text: item['name']?.toString() ?? '');
    final sku = TextEditingController(text: item['sku']?.toString() ?? '');
    final category = TextEditingController(text: item['category']?.toString() ?? '');
    final basePrice = TextEditingController(text: item['basePrice']?.toString() ?? '');
    final discountedPrice = TextEditingController(text: item['discountedPrice']?.toString() ?? '');
    final stockQty = TextEditingController(text: item['stockQty']?.toString() ?? '');
    final supplier = TextEditingController(text: item['supplier']?.toString() ?? '');
    final description = TextEditingController(text: item['description']?.toString() ?? '');
    final dateAdded = TextEditingController(text: item['dateAdded']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Ice Cream'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU')),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: basePrice, decoration: const InputDecoration(labelText: 'Base Price')),
              TextField(controller: discountedPrice, decoration: const InputDecoration(labelText: 'Discounted Price')),
              TextField(controller: stockQty, decoration: const InputDecoration(labelText: 'Stock Qty')),
              TextField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier')),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: dateAdded, decoration: const InputDecoration(labelText: 'Date Added')),
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
              final id = item['id'];
              if (id == null) return;

              try {
                await DBHelper().updateItem(id, {
                  'name': name.text,
                  'sku': sku.text,
                  'category': category.text,
                  'basePrice': basePrice.text,
                  'discountedPrice': discountedPrice.text,
                  'stockQty': stockQty.text,
                  'supplier': supplier.text,
                  'description': description.text,
                  'dateAdded': dateAdded.text,
                });

                Navigator.pop(context);
                _loadItems();
              } catch (e) {
                print("UPDATE ERROR: $e");

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Update failed: $e")),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Ice Cream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddIceCreamScreen()),
              );
              _loadItems();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('SKU: ${item['sku']}'),
                  Text('Category: ${item['category']}'),
                  Text('Base Price: ₱${item['basePrice']}'),
                  Text('Discounted Price: ₱${item['discountedPrice']}'),
                  Text('Stock: ${item['stockQty']}'),
                  Text('Supplier: ${item['supplier']}'),
                  Text('Description: ${item['description']}'),
                  Text('Date Added: ${item['dateAdded']}'),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(item),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
