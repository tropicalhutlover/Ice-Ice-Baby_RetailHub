import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'db_helper.dart';
import 'models/order.dart';

class OrderedListScreen extends StatefulWidget {
  final int userId;

  const OrderedListScreen({super.key, required this.userId});

  @override
  State<OrderedListScreen> createState() => _OrderedListScreenState();
}

class _OrderedListScreenState extends State<OrderedListScreen> {
  List<Order> orders = [];
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadOrders();
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByOrder();
    final groupIds = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.blue,
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
        child: _loadError != null
          ? Center(child: Text(_loadError!))
          : orders.isEmpty
            ? const Center(child: Text("No orders yet"))
            : RefreshIndicator(
                onRefresh: () async => loadOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupIds.length,
                  itemBuilder: (_, index) {
                    final gid = groupIds[index];
                    final rows = grouped[gid]!;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final r in rows)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.icecream,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.itemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'Qty: ${r.qty} • ₱${r.total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ₱${total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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
                ),
              ),
      ),
    );
  }
}
