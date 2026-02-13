import 'package:flutter/material.dart';
import '../db_helper.dart';

class OrderedListScreen extends StatefulWidget {
  final int userId;

  const OrderedListScreen({super.key, required this.userId});

  @override
  State<OrderedListScreen> createState() => _OrderedListScreenState();
}

class _OrderedListScreenState extends State<OrderedListScreen> {
  List orders = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadOrders();
  }

  void loadOrders() async {
    orders = await DBHelper().getOrders(widget.userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ordered Items"),
        backgroundColor: Colors.indigo,
      ),
      body: orders.isEmpty
          ? const Center(child: Text("No orders yet"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.icecream,
                      size: 60,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orders[index]['itemName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Quantity: ${orders[index]['qty']}"),
                      Text("Total: ₱${orders[index]['total']}"),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
