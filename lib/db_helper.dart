import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/order.dart';
import 'models/product.dart';

class CheckoutResult {
  final bool success;
  final String message;

  const CheckoutResult({required this.success, required this.message});
}

class DBHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  int _nextIntId() => DateTime.now().microsecondsSinceEpoch;

  List<Map<String, dynamic>> _snapshotToList(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return [];

    final raw = snapshot.value;
    if (raw is! Map) return [];

    final list = <Map<String, dynamic>>[];

    raw.forEach((key, value) {
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        map['id'] ??= int.tryParse(key.toString()) ?? _nextIntId();
        list.add(map);
      }
    });

    return list;
  }

  List<Product> _snapshotToProducts(DataSnapshot snapshot) {
    final rows = _snapshotToList(snapshot);
    return rows.map(Product.fromMap).toList();
  }

  List<Order> _snapshotToOrders(DataSnapshot snapshot) {
    final rows = _snapshotToList(snapshot);
    return rows.map(Order.fromMap).toList();
  }

  Future<DatabaseReference> _itemsRef() async => _root.child('items');
  Future<DatabaseReference> _ordersRef() async => _root.child('orders');
  Future<DatabaseReference> _usersRef() async => _root.child('users');

  // Users

  Future<int> registerUser(
    String name,
    String email,
    String password, {
    String address = '',
    String phone = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final userId = _nextIntId();

    await (await _usersRef()).child(cred.user!.uid).set({
      'id': userId,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'isAdmin': 0,
    });

    return userId;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final snap = await (await _usersRef()).child(cred.user!.uid).get();

      if (!snap.exists) return null;

      return Map<String, dynamic>.from(
          (snap.value as Map).cast<String, dynamic>());
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      final snap = await (await _usersRef())
          .orderByChild('id')
          .equalTo(id)
          .get();

      final list = _snapshotToList(snap);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap = await (await _usersRef()).child(uid).get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from((snap.value as Map).cast<String, dynamic>());
  }

  Stream<Map<String, dynamic>?> watchCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<Map<String, dynamic>?>.value(null);
    }

    return _root.child('users').child(uid).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;
      return Map<String, dynamic>.from((snapshot.value as Map).cast<String, dynamic>());
    });
  }

  Future<void> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    required String address,
    required String phone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await (await _usersRef()).child(uid).update({
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
    });
  }

  // Items

  Future<void> insertItem(Product item) async {
    final id = _nextIntId();
    final newItem = item.copyWith(id: id);
    await (await _itemsRef()).child(id.toString()).set(newItem.toMap());
  }

  Future<List<Product>> getItems() async {
    final snap = await (await _itemsRef()).get();
    return _snapshotToProducts(snap);
  }

  Stream<List<Product>> watchItems() {
    return _root.child('items').onValue.map((event) {
      return _snapshotToProducts(event.snapshot);
    });
  }

  Future<void> updateItem(Product item) async {
    if (item.id == null) {
      throw ArgumentError('Product id is required for update.');
    }
    await (await _itemsRef()).child(item.id.toString()).update(item.toMap());
  }

  Future<void> deleteItem(int id) async {
    await (await _itemsRef()).child(id.toString()).remove();
  }

  // Orders

  Future<void> addOrder(
      int userId, int orderGroupId, String item, int qty, double total) async {
    final id = _nextIntId();

    await (await _ordersRef()).child(id.toString()).set({
      'id': id,
      'userId': userId,
      'orderGroupId': orderGroupId,
      'itemName': item,
      'qty': qty,
      'total': total,
      'status': 'pending',
    });
  }

  Future<CheckoutResult> checkoutOrder({
    required int userId,
    required Map<int, int> quantities,
  }) async {
    final requested = <int, int>{};
    for (final entry in quantities.entries) {
      if (entry.value > 0) {
        requested[entry.key] = entry.value;
      }
    }

    if (requested.isEmpty) {
      return const CheckoutResult(
        success: false,
        message: 'Please select at least one item.',
      );
    }

    try {
      final itemsSnap = await (await _itemsRef()).get();
      if (!itemsSnap.exists || itemsSnap.value == null) {
        return const CheckoutResult(
          success: false,
          message: 'Items are unavailable. Please try again.',
        );
      }

      final products = _snapshotToProducts(itemsSnap);
      final byId = <int, Product>{
        for (final p in products)
          if (p.id != null) p.id!: p,
      };

      final updates = <String, dynamic>{};
      final orderGroupId = DateTime.now().millisecondsSinceEpoch;
      int itemIndex = 0;

      for (final entry in requested.entries) {
        final itemId = entry.key;
        final qty = entry.value;

        final item = byId[itemId];
        if (item == null) {
          return CheckoutResult(
            success: false,
            message: 'An item was removed. Please refresh and try again.',
          );
        }

        if (qty > item.stockQty) {
          return CheckoutResult(
            success: false,
            message: 'Insufficient stock for ${item.name}.',
          );
        }

        // Generate unique orderId by combining timestamp and index
        final orderId = _nextIntId() + itemIndex;
        final order = Order(
          id: orderId,
          userId: userId,
          orderGroupId: orderGroupId,
          itemName: item.name,
          qty: qty,
          total: qty * item.discountedPrice,
          status: 'pending',
        );

        updates['orders/${order.id}'] = order.toMap();
        updates['items/$itemId/stockQty'] = (item.stockQty - qty).toString();
        itemIndex++;
      }

      await _root.update(updates);

      return const CheckoutResult(
        success: true,
        message: 'Order placed successfully.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const CheckoutResult(
          success: false,
          message: 'Checkout blocked by database rules. Verify items/orders write permissions.',
        );
      }
      return CheckoutResult(
        success: false,
        message: e.message ?? 'Checkout failed. Please try again.',
      );
    } catch (_) {
      return const CheckoutResult(
        success: false,
        message: 'Checkout failed. Please try again.',
      );
    }
  }

  Future<List<Order>> getOrders(int userId) async {
    final snap = await (await _ordersRef())
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    return _snapshotToOrders(snap);
  }

  Stream<List<Order>> watchOrders(int userId) {
    return _root
        .child('orders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) => _snapshotToOrders(event.snapshot));
  }

  Future<List<Order>> getAllOrders() async {
    final snap = await (await _ordersRef()).get();
    return _snapshotToOrders(snap);
  }

  Stream<List<Order>> watchAllOrders() {
    return _root.child('orders').onValue.map((event) {
      return _snapshotToOrders(event.snapshot);
    });
  }

  Future<void> updateOrderGroupStatus(
      int orderGroupId, String status) async {
    final snap = await (await _ordersRef())
        .orderByChild('orderGroupId')
        .equalTo(orderGroupId)
        .get();

    if (!snap.exists || snap.value == null) return;

    final raw = snap.value as Map;
    final updates = <String, dynamic>{};

    raw.forEach((key, value) {
      updates['$key/status'] = status;
    });

    await (await _ordersRef()).update(updates);
  }

  // Password Reset

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
