import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  Future<DatabaseReference> _itemsRef() async => _root.child('items');
  Future<DatabaseReference> _ordersRef() async => _root.child('orders');
  Future<DatabaseReference> _usersRef() async => _root.child('users');

  // Users

  Future<int> registerUser(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final userId = _nextIntId();

    await (await _usersRef()).child(cred.user!.uid).set({
      'id': userId,
      'name': name,
      'email': email,
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
    final snap = await (await _usersRef())
        .orderByChild('id')
        .equalTo(id)
        .get();

    final list = _snapshotToList(snap);
    return list.isNotEmpty ? list.first : null;
  }

  // Items

  Future<void> insertItem(Map<String, dynamic> item) async {
    final id = _nextIntId();
    item['id'] = id;

    await (await _itemsRef()).child(id.toString()).set(item);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final snap = await (await _itemsRef()).get();
    return _snapshotToList(snap);
  }

  Future<void> updateItem(int id, Map<String, dynamic> item) async {
    await (await _itemsRef()).child(id.toString()).update(item);
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

  Future<List<Map<String, dynamic>>> getOrders(int userId) async {
    final snap = await (await _ordersRef())
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    return _snapshotToList(snap);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final snap = await (await _ordersRef()).get();
    return _snapshotToList(snap);
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
