import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';
import 'package:gazprof/models/product_item.dart';

/// Singleton provider that loads the products list once per app session.
/// All order-creation screens (DispecerHome, AdminDocumente, SoferCreateOrder)
/// read from this cache instead of each issuing a separate Firestore read.
class ProductsProvider extends ChangeNotifier {
  List<ProductItem> _products = [];
  bool _isLoading = false;
  bool _isLoaded = false;

  List<ProductItem> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  /// Returns a deep copy of the products list (each screen gets its own
  /// quantity-independent copy so one screen's counter doesn't affect another).
  List<ProductItem> freshCopy() {
    return _products.map((p) => ProductItem(p.name, p.price, 0)).toList();
  }

  Future<void> loadIfNeeded() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .orderBy('pozitie')
          .get();

      if (snapshot.docs.isEmpty) {
        // Seed default products only once if the collection is empty
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
        // Reload after seeding
        _isLoading = false;
        await loadIfNeeded();
        return;
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
    } catch (e) {
      debugPrint('ProductsProvider: eroare la încărcarea produselor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call this when an admin changes the product list so it reloads on next use.
  void invalidate() {
    _isLoaded = false;
    _products = [];
    notifyListeners();
  }
}
