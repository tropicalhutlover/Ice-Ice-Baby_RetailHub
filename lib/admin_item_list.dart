import 'package:flutter/material.dart';
import 'add_ice_cream_screen.dart';
import 'db_helper.dart';
import 'models/product.dart';

class AdminItemListScreen extends StatefulWidget {
  const AdminItemListScreen({super.key});

  @override
  State<AdminItemListScreen> createState() => _AdminItemListScreenState();
}

class _AdminItemListScreenState extends State<AdminItemListScreen> {
  final Set<int> _busyItemIds = <int>{};

  Future<void> _deleteItem(Product item) async {
    final id = item.id;
    if (id == null || _busyItemIds.contains(id)) return;

    setState(() => _busyItemIds.add(id));
    try {
      await DBHelper().deleteItem(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyItemIds.remove(id));
      }
    }
  }

  void _showEditDialog(Product item) {
    final name = TextEditingController(text: item.name);
    final sku = TextEditingController(text: item.sku);
    final category = TextEditingController(text: item.category);
    final basePrice = TextEditingController(text: item.basePrice.toString());
    final discountedPrice = TextEditingController(text: item.discountedPrice.toString());
    final stockQty = TextEditingController(text: item.stockQty.toString());
    final supplier = TextEditingController(text: item.supplier);
    final description = TextEditingController(text: item.description);
    final imageUrl = TextEditingController(text: item.imageUrl);
    final dateAdded = TextEditingController(text: item.dateAdded);

    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                TextField(controller: imageUrl, decoration: const InputDecoration(labelText: 'Image URL')),
                TextField(controller: dateAdded, decoration: const InputDecoration(labelText: 'Date Added')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isUpdating) return;

                final id = item.id;
                if (id == null) return;

                setDialogState(() => isUpdating = true);
                setState(() => _busyItemIds.add(id));

                try {
                  final updatedItem = item.copyWith(
                    name: name.text.trim(),
                    sku: sku.text.trim(),
                    category: category.text.trim(),
                    basePrice: double.tryParse(basePrice.text.trim()) ?? item.basePrice,
                    discountedPrice: double.tryParse(discountedPrice.text.trim()) ?? item.discountedPrice,
                    stockQty: int.tryParse(stockQty.text.trim()) ?? item.stockQty,
                    supplier: supplier.text.trim(),
                    description: description.text.trim(),
                    imageUrl: imageUrl.text.trim(),
                    dateAdded: dateAdded.text.trim(),
                  );

                  await DBHelper().updateItem(updatedItem);

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item updated successfully.')),
                  );
                } catch (_) {
                  if (!mounted) return;
                  setDialogState(() => isUpdating = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Update failed. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _busyItemIds.remove(id));
                  }
                }
              },
              child: isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageThumb(Product item) {
    if (item.imageUrl.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.icecream, color: Colors.blue),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        item.imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          height: 90,
          color: Colors.blue[50],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
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
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: DBHelper().watchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load items.'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items available.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final id = item.id;
              final isBusy = id != null && _busyItemIds.contains(id);

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _imageThumb(item),
                      const SizedBox(height: 8),
                      Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('SKU: ${item.sku}'),
                      Text('Category: ${item.category}'),
                      Text('Base Price: ₱${item.basePrice.toStringAsFixed(2)}'),
                      Text('Discounted Price: ₱${item.discountedPrice.toStringAsFixed(2)}'),
                      Text('Stock: ${item.stockQty}'),
                      Text('Supplier: ${item.supplier}'),
                      Text('Description: ${item.description}'),
                      Text('Date Added: ${item.dateAdded}'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: isBusy ? null : () => _showEditDialog(item),
                          ),
                          IconButton(
                            icon: isBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.delete, color: Colors.red),
                            onPressed: isBusy ? null : () => _deleteItem(item),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
