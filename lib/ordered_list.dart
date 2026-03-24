import 'package:flutter/material.dart';
import 'db_helper.dart';

class OrderedListScreen extends StatefulWidget {
  final int userId;

  const OrderedListScreen({super.key, required this.userId});

  @override
  State<OrderedListScreen> createState() => _OrderedListScreenState();
}

class _OrderedListScreenState extends State<OrderedListScreen> {
  List<Map<String, dynamic>> orders = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadOrders();
  }

  void loadOrders() async {
    final raw = await DBHelper().getOrders(widget.userId);
    if (mounted) setState(() => orders = raw);
  }

  Map<int, List<Map<String, dynamic>>> _groupByOrder() {
    final groups = <int, List<Map<String, dynamic>>>{};
    for (final o in orders) {
      final gid = o['orderGroupId'] as int? ?? o['id'] as int;
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
        child: orders.isEmpty
            ? const Center(child: Text("No orders yet"))
            : RefreshIndicator(
                onRefresh: () async => loadOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupIds.length,
                  itemBuilder: (_, index) {
                    final gid = groupIds[index];
                    final rows = grouped[gid]!;
                    final status = (rows.first['status'] ?? 'pending').toString();
                    double total = 0;
                    for (final r in rows) {
                      total += (r['total'] as num?)?.toDouble() ?? 0;
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
                                            r['itemName']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'Qty: ${r['qty']} • ₱${r['total']}',
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
