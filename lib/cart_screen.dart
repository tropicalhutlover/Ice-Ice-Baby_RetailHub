import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'models/product.dart';

class CartScreenResult {
  final Map<int, int> quantities;
  final bool checkedOut;

  const CartScreenResult({
    required this.quantities,
    required this.checkedOut,
  });
}

class CartScreen extends StatefulWidget {
  final int userId;
  final List<Product> products;
  final Map<int, int> initialQuantities;

  const CartScreen({
    super.key,
    required this.userId,
    required this.products,
    required this.initialQuantities,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const double _taxRate = 0.12;
  late Map<int, int> _quantities;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _quantities = Map<int, int>.from(widget.initialQuantities);
  }

  List<Product> get _cartProducts {
    return widget.products.where((p) {
      final id = p.id;
      if (id == null) return false;
      return (_quantities[id] ?? 0) > 0;
    }).toList();
  }

  int _qty(Product p) {
    final id = p.id;
    if (id == null) return 0;
    return _quantities[id] ?? 0;
  }

  double get _subtotal {
    double sum = 0;
    for (final p in _cartProducts) {
      sum += _qty(p) * p.discountedPrice;
    }
    return sum;
  }

  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  int get _itemCount {
    int count = 0;
    for (final qty in _quantities.values) {
      count += qty;
    }
    return count;
  }

  void _changeQty(Product p, int next) {
    final id = p.id;
    if (id == null) return;

    final clamped = next.clamp(0, p.stockQty);
    setState(() {
      _quantities[id] = clamped;
    });
  }

  Future<void> _checkout() async {
    if (_isCheckingOut) return;
    if (_itemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    final result = await DBHelper().checkoutOrder(
      userId: widget.userId,
      quantities: _quantities,
    );

    if (!mounted) return;
    setState(() => _isCheckingOut = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    _quantities.clear();
    if (mounted) {
      Navigator.pop(
        context,
        CartScreenResult(quantities: _quantities, checkedOut: true),
      );
    }
  }

  void _closeCart() {
    Navigator.pop(
      context,
      CartScreenResult(quantities: _quantities, checkedOut: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProducts = _cartProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeCart,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartProducts.isEmpty
                ? const Center(child: Text('No items in cart yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartProducts.length,
                    itemBuilder: (_, i) {
                      final p = cartProducts[i];
                      final qty = _qty(p);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('₱${p.discountedPrice.toStringAsFixed(2)} each'),
                                    Text('Stock: ${p.stockQty}'),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: qty > 0 ? () => _changeQty(p, qty - 1) : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Text(qty.toString()),
                              IconButton(
                                onPressed: qty < p.stockQty
                                    ? () => _changeQty(p, qty + 1)
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                              IconButton(
                                onPressed: () => _changeQty(p, 0),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('₱${_subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax (12%)'),
                    Text('₱${_tax.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '₱${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCheckingOut ? null : _checkout,
                    child: _isCheckingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text('Check Out ($_itemCount item${_itemCount == 1 ? '' : 's'})'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
