import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DBHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  int _nextIntId() {
    return DateTime.now().microsecondsSinceEpoch;
  }

  List<Map<String, dynamic>> _snapshotToList(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return [];

    final raw = snapshot.value;
    if (raw is! Map) return [];

    final list = <Map<String, dynamic>>[];
    raw.forEach((key, value) {
      if (value is Map) {
        final map = Map<String, dynamic>.from(value.cast<String, dynamic>());
        map['id'] ??= int.tryParse(key.toString()) ?? _nextIntId();
        list.add(map);
      }
    });
    return list;
  }

  Future<DatabaseReference> _itemsRef() async => _root.child('items');

  Future<DatabaseReference> _ordersRef() async => _root.child('orders');

  Future<DatabaseReference> _usersRef() async => _root.child('users');

  Future<bool> userExists(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
    return methods.isNotEmpty;
  }

  Future<int> updatePassword(String email, String newPassword) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 1;
    } on FirebaseAuthException {
      return 0;
    }
  }

  Future<int> registerUser(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existingMethods =
        await _auth.fetchSignInMethodsForEmail(normalizedEmail);
    if (existingMethods.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'An account already exists for this email.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    try {
      final userId = _nextIntId();
      await (await _usersRef()).child(cred.user!.uid).set({
        'id': userId,
        'name': name.trim(),
        'email': normalizedEmail,
        'isAdmin': 0,
      });

      return userId;
    } catch (_) {
      // Avoid orphan auth users when profile write to database fails.
      await cred.user?.delete();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final snap = await (await _usersRef()).child(cred.user!.uid).get();
      if (!snap.exists || snap.value == null) {
        final userId = _nextIntId();
        final fallbackProfile = {
          'id': userId,
          'name': cred.user?.displayName ??
              cred.user?.email?.split('@').first ??
              'User',
          'email': normalizedEmail,
          'isAdmin': 0,
        };
        await (await _usersRef()).child(cred.user!.uid).set(fallbackProfile);
        return fallbackProfile;
      }

      final data = Map<String, dynamic>.from(
        (snap.value as Map).cast<String, dynamic>(),
      );
      data['email'] ??= normalizedEmail;
      data['isAdmin'] ??= 0;
      return data;
    } on FirebaseAuthException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    if (id < 0) return null;

    final users = await (await _usersRef())
        .orderByChild('id')
        .equalTo(id)
        .limitToFirst(1)
        .get();
    final list = _snapshotToList(users);
    return list.isNotEmpty ? list.first : null;
  }

  Future insertItem(String name, double price) async {
    final id = _nextIntId();
    await (await _itemsRef()).child(id.toString()).set({
      'id': id,
      'name': name,
      'price': price,
    });
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final snap = await (await _itemsRef()).get();
    final items = _snapshotToList(snap);
    items.sort((a, b) =>
        (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    return items;
  }

  Future addOrder(int userId, int orderGroupId, String item, int qty, double total) async {
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
    final rows = _snapshotToList(snap);
    rows.sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
    return rows;
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final snap = await (await _ordersRef()).get();
    final rows = _snapshotToList(snap);
    rows.sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
    return rows;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await (await _ordersRef()).child(orderId.toString()).update({'status': status});
  }

  Future<void> updateOrderGroupStatus(int orderGroupId, String status) async {
    final snap = await (await _ordersRef())
        .orderByChild('orderGroupId')
        .equalTo(orderGroupId)
        .get();
    if (!snap.exists || snap.value == null) return;

    final raw = snap.value;
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      await (await _ordersRef()).child(entry.key.toString()).update({'status': status});
    }
  }

  Future<void> updateItem(int id, String name, double price) async {
    await (await _itemsRef()).child(id.toString()).update({
      'name': name,
      'price': price,
    });
  }

  Future<void> deleteItem(int id) async {
    await (await _itemsRef()).child(id.toString()).remove();
  }
}
