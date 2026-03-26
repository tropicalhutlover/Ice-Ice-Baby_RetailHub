import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'db_helper.dart';
import 'models/order.dart';
import 'models/product.dart';

class OrderedListScreen extends StatefulWidget {
  final int userId;

  const OrderedListScreen({super.key, required this.userId});

  @override
  State<OrderedListScreen> createState() => _OrderedListScreenState();
}

class _OrderedListScreenState extends State<OrderedListScreen> {
  List<Order> orders = [];
  List<Product> products = [];
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadOrders();
    loadProducts();
  }

  void loadProducts() async {
    final items = await DBHelper().getItems();
    if (!mounted) return;
    setState(() => products = items);
  }

  void loadOrders() async {
    try {
      final raw = await DBHelper().getOrders(widget.userId);
      if (!mounted) return;
      setState(() {
        orders = raw;
        _loadError = null;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        orders = [];
        _loadError = e.code == 'permission-denied'
            ? 'Cannot read orders due to database rules.'
            : 'Failed to load orders. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loadError!),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        orders = [];
        _loadError = 'Failed to load orders. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load orders. Please try again.'),
        ),
      );
    }
  }

  Product? _findProduct(String name) {
    try {
      return products.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  Map<int, List<Order>> _groupByOrder() {
    final groups = <int, List<Order>>{};
    for (final o in orders) {
      final gid = o.orderGroupId;
      groups.putIfAbsent(gid, () => []).add(o);
    }
    final sorted = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sorted) k: groups[k]!};
  }

  Widget _imageThumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 50,
        height: 50,
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
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 50,
          height: 50,
          color: Colors.blue[50],
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByOrder();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: StreamBuilder<List<Order>>(
          stream: DBHelper().watchOrders(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load orders.'));
            }

            orders = snapshot.data ?? [];
            final groupedData = _groupByOrder();

            if (groupedData.isEmpty) {
              return const Center(child: Text("No orders yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedData.length,
              itemBuilder: (_, index) {
                final gid = groupedData.keys.elementAt(index);
                final rows = groupedData[gid]!;
                final status = rows.first.status;

                double total = 0;
                for (final r in rows) {
                  total += r.total;
                }

                Color statusColor = Colors.grey[300]!;
                if (status == 'done') statusColor = Colors.green[100]!;
                if (status == 'preparing') statusColor = Colors.orange[100]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final r in rows)
                          Builder(
                            builder: (_) {
                              final product = _findProduct(r.itemName);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _imageThumb(product?.imageUrl ?? ''),
                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.itemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          if (product != null)
                                            Text(
                                              product.description,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),

                                          const SizedBox(height: 4),

                                          Text(
                                            'Qty: ${r.qty} • ₱${r.total.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ₱${total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(status),
                              backgroundColor: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
