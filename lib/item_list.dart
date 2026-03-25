import 'dart:async';

import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'db_helper.dart';
import 'models/product.dart';

class ItemListScreen extends StatefulWidget {
  final int userId;

  const ItemListScreen({super.key, required this.userId});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Product> items = [];
  final Map<int, int> quantities = {};
  bool _isLoadingItems = false;
  String? _loadError;
  StreamSubscription<List<Product>>? _itemsSubscription;

  int get _cartCount {
    int count = 0;
    for (final qty in quantities.values) {
      count += qty;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _startItemsSubscription();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }

  void _startItemsSubscription() {
    _itemsSubscription?.cancel();
    setState(() {
      _isLoadingItems = true;
      _loadError = null;
    });

    _itemsSubscription = DBHelper().watchItems().listen(
      (fetched) {
        if (!mounted) return;
        final currentIds = fetched.where((p) => p.id != null).map((p) => p.id!).toSet();

        // Keep existing local cart quantities while syncing against live catalog updates.
        quantities.removeWhere((key, _) => !currentIds.contains(key));
        for (final p in fetched) {
          if (p.id != null) {
            quantities.putIfAbsent(p.id!, () => 0);
          }
        }

        setState(() {
          items = fetched;
          _isLoadingItems = false;
          _loadError = null;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isLoadingItems = false;
          _loadError = 'Failed to load items. Please try again.';
        });
      },
    );
  }

  void _openCart() async {
    if (_isLoadingItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for items to finish loading.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cartCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    final result = await Navigator.push<CartScreenResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          userId: widget.userId,
          products: items,
          initialQuantities: quantities,
        ),
      ),
    );

    if (result == null || !mounted) return;

    quantities
      ..clear()
      ..addAll(result.quantities);
    setState(() {});

    if (result.checkedOut) {
      quantities.clear();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _quickCheckout() async {
    final hasSelection = quantities.values.any((qty) => qty > 0);
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    final result = await DBHelper().checkoutOrder(
      userId: widget.userId,
      quantities: quantities,
    );
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    quantities.clear();
    setState(() {});
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            onPressed: _cartCount > 0 ? _openCart : null,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _cartCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingItems
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_loadError!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _startItemsSubscription,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => _itemCard(items[i]),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cartCount > 0 ? _openCart : null,
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: Text('View Cart ($_cartCount)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isLoadingItems || _cartCount == 0) ? null : _quickCheckout,
                    child: const Text('Quick Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(Product item) {
    final id = item.id;
    if (id == null) return const SizedBox.shrink();
    final qty = quantities[id] ?? 0;

    final availableStock = item.stockQty - qty;

    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: Colors.blue[50],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 52,
                  height: 52,
                  color: Colors.blue[50],
                  child: const Icon(Icons.icecream, color: Colors.blue),
                ),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item.category}'),
            Text('Base Price: ₱${item.basePrice.toStringAsFixed(2)}'),
            Text('Discounted Price: ₱${item.discountedPrice.toStringAsFixed(2)}'),
            Text('Stock: ${availableStock < 0 ? 0 : availableStock}'),

            if (availableStock <= 0)
              const Text(
                'Out of Stock',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),

            Text('Description: ${item.description}'),
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
                  quantities[id] = qty - 1;
                });
              }
                  : null,
            ),

            Text(qty.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: availableStock > 0
                  ? () {
                setState(() {
                  quantities[id] = qty + 1;
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
