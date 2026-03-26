import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'db_helper.dart';
import 'models/order.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  final Map<int, String> _userNames = {};
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final db = DBHelper();
      final orders = await db.getAllOrders();

      final userIds = orders.map((o) => o.userId).toSet();
      for (final uid in userIds) {
        if (!_userNames.containsKey(uid)) {
          try {
            final u = await db.getUserById(uid);
            _userNames[uid] = u?['name'] ?? 'User #$uid';
          } catch (_) {
            _userNames[uid] = 'User #$uid';
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loadError = null;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Cannot read all orders due to database rules.'
          : 'Failed to load orders. Please try again.';
      setState(() {
        _orders = [];
        _loadError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _loadError = 'Failed to load orders. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load orders. Please try again.'),
        ),
      );
    }
  }

  Map<int, Map<int, List<Order>>> _groupOrders() {
    final byUser = <int, Map<int, List<Order>>>{};
    for (final o in _orders) {
      final uid = o.userId;
      final gid = o.orderGroupId;
      byUser.putIfAbsent(uid, () => {});
      byUser[uid]!.putIfAbsent(gid, () => []).add(o);
    }
    return byUser;
  }

  Future<void> _updateStatus(int orderGroupId, String status) async {
    await DBHelper().updateOrderGroupStatus(orderGroupId, status);
    _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status set to $status')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green[100]!;
      case 'preparing':
        return Colors.orange[100]!;
      default:
        return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
          stream: DBHelper().watchAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load orders.'));
            }

            _orders = snapshot.data ?? [];
            final grouped = _groupOrders();
            final userIds = grouped.keys.toList()..sort();

            if (grouped.isEmpty) {
              return const Center(child: Text('No orders yet'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userIds.length,
              itemBuilder: (_, ui) {
                final uid = userIds[ui];
                final userName = _userNames[uid] ?? 'User #$uid';
                final orderGroups = grouped[uid]!;
                final groupIds = orderGroups.keys.toList()..sort((a, b) => b.compareTo(a));

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...groupIds.map((gid) {
                          final rows = orderGroups[gid]!;
                          final status = rows.first.status;
                          double total = 0;
                          for (final r in rows) {
                            total += r.total;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final r in rows)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${r.itemName} x${r.qty} — ₱${r.total.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: ₱${total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          final newStatus = await showDialog<String>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Order Status'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    title: const Text('Pending'),
                                                    selected: status == 'pending',
                                                    onTap: () => Navigator.pop(ctx, 'pending'),
                                                  ),
                                                  ListTile(
                                                    title: const Text('Preparing'),
                                                    selected: status == 'preparing',
                                                    onTap: () => Navigator.pop(ctx, 'preparing'),
                                                  ),
                                                  ListTile(
                                                    title: const Text('Done'),
                                                    selected: status == 'done',
                                                    onTap: () => Navigator.pop(ctx, 'done'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          if (newStatus != null) {
                                            _updateStatus(gid, newStatus);
                                          }
                                        },
                                        child: Chip(
                                          label: Text(status),
                                          backgroundColor: _statusColor(status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
