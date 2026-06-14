import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';
import 'package:gazprof/models/product_item.dart';

/// Singleton provider that listens to the products collection in real time.
/// Any admin change to Firestore propagates instantly to all connected clients.
class ProductsProvider extends ChangeNotifier {
  List<ProductItem> _products = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasError = false;
  bool _initialized = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<ProductItem> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  bool get hasError => _hasError;

  /// Returns a deep copy of the products list (each screen gets its own
  /// quantity-independent copy so one screen's counter doesn't affect another).
  List<ProductItem> freshCopy() {
    return _products.map((p) => ProductItem(p.name, p.price, 0)).toList();
  }

  /// Loads products on first call, then subscribes to Firestore snapshots
  /// so any future changes propagate automatically.
  Future<void> loadIfNeeded() async {
    if (_initialized) return;
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .orderBy('pozitie')
          .get();

      if (snapshot.docs.isEmpty) {
        await _seedDefaultProducts();
        snapshot = await FirebaseFirestore.instance
            .collection(FirestoreCollections.products)
            .orderBy('pozitie')
            .get();
      }

      _products = snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductItem(
          data['nume'] ?? 'Produs',
          (data['pret'] ?? 0.0).toDouble(),
          0,
        );
      }).toList();

      _isLoaded = true;
      _initialized = true;

      // Subscribe to real-time updates
      _subscription = FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .orderBy('pozitie')
          .snapshots()
          .listen(_onSnapshot, onError: _onError);
    } catch (e) {
      debugPrint('ProductsProvider: eroare la încărcarea produselor: $e');
      _isLoaded = true;
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onSnapshot(QuerySnapshot snapshot) {
    _products = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ProductItem(
        data['nume'] ?? 'Produs',
        (data['pret'] ?? 0.0).toDouble(),
        0,
      );
    }).toList();
    _isLoaded = true;
    _hasError = false;
    notifyListeners();
  }

  void _onError(Object e) {
    debugPrint('ProductsProvider stream error: $e');
    _hasError = true;
    notifyListeners();
  }

  Future<void> _seedDefaultProducts() async {
    final defaultProducts = [
      {"nume": "Butelie 10kg", "pret": 120.0},
      {"nume": "Butelie 11kg", "pret": 115.0},
      {"nume": "Butelie 11kg filet", "pret": 115.0},
      {"nume": "Butelie 35kg", "pret": 400.0},
      {"nume": "Ambalaj", "pret": 250.0},
      {"nume": "Ceas butelie", "pret": 40.0},
    ];
    for (int i = 0; i < defaultProducts.length; i++) {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .add({
        'nume': defaultProducts[i]['nume'],
        'pret': defaultProducts[i]['pret'],
        'pozitie': i,
      });
    }
  }

  /// Retry after an error — tears down the stream and re-initializes.
  Future<void> retry() async {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _isLoaded = false;
    _hasError = false;
    _products = [];
    notifyListeners();
    await loadIfNeeded();
  }

  /// Force a reload. With the stream, this is rarely needed, but kept for
  /// callers (e.g. admin_product_setting_screen) that expect instant feedback.
  void invalidate() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _isLoaded = false;
    _hasError = false;
    _products = [];
    notifyListeners();
    loadIfNeeded();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
