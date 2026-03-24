import 'package:flutter/material.dart';
import 'db_helper.dart';

class AddIceCreamScreen extends StatefulWidget {
  const AddIceCreamScreen({super.key});

  @override
  State<AddIceCreamScreen> createState() => _AddIceCreamScreenState();
}

class _AddIceCreamScreenState extends State<AddIceCreamScreen> {
  final name = TextEditingController();
  final sku = TextEditingController();
  final category = TextEditingController();
  final basePrice = TextEditingController();
  final discountedPrice = TextEditingController();
  final stock = TextEditingController();
  final description = TextEditingController();
  final supplier = TextEditingController();
  final imageUrl = TextEditingController();
  final dateAdded = TextEditingController();

  Future<void> _addItem() async {
    try {
      await DBHelper().insertItem({
        'name': name.text,
        'sku': sku.text,
        'category': category.text,
        'basePrice': basePrice.text,
        'discountedPrice': discountedPrice.text,
        'stockQty': stock.text,
        'description': description.text,
        'supplier': supplier.text,
        'imageUrl': imageUrl.text,
        'dateAdded': dateAdded.text,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
    } catch (e) {
      print("ADD ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add failed: $e')),
      );
    }
  }

  Widget field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          field('Name', name),
          field('SKU', sku),
          field('Category', category),
          field('Base Price', basePrice),
          field('Discounted Price', discountedPrice),
          field('Stock Qty', stock),
          field('Description', description),
          field('Supplier', supplier),
          field('Image URL', imageUrl),
          field('Date Added (e.g. 2026-03-25)', dateAdded),

          ElevatedButton(
            onPressed: _addItem,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
