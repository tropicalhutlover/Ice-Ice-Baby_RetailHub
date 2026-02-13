import 'package:flutter/material.dart';
import '../db_helper.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final db = DBHelper();

    // optional: add default items first time
    if ((await db.getItems()).isEmpty) {
      await db.insertItem("Cookies & Cream", 450);
      await db.insertItem("Mango Overload", 800);
      await db.insertItem("Coffee", 450);
      await db.insertItem("Rocky Road", 650);
    }

    items = await db.getItems();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item List"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          return ListTile(
            leading: const Icon(Icons.icecream),
            title: Text(items[i]['name']),
            subtitle: Text("₱${items[i]['price']}"),
          );
        },
      ),
    );
  }
}