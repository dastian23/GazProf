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
  bool _hasError = false;

  List<ProductItem> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  /// True dacă ultimul fetch a eșuat. Ecranele pot afișa un mesaj + buton retry.
  bool get hasError => _hasError;

  /// Returns a deep copy of the products list (each screen gets its own
  /// quantity-independent copy so one screen's counter doesn't affect another).
  List<ProductItem> freshCopy() {
    return _products.map((p) => ProductItem(p.name, p.price, 0)).toList();
  }

  Future<void> loadIfNeeded() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    _hasError = false;
    // Nu apelăm notifyListeners() la start — evităm un rebuild inutil
    // (guard-ul din ecrane verifică isLoading, nu avem nevoie de rebuild acum)

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
      // Marcăm _isLoaded = true pentru a opri ciclul infinit de retry.
      // _hasError = true permite ecranelor să afișeze un mesaj + buton retry.
      _isLoaded = true;
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Permite reîncărcarea manuală după o eroare (apelat din butonul Retry).
  Future<void> retry() async {
    _isLoaded = false;
    _hasError = false;
    _products = [];
    await loadIfNeeded();
  }

  /// Call this when an admin changes the product list so it reloads on next use.
  void invalidate() {
    _isLoaded = false;
    _hasError = false;
    _products = [];
    notifyListeners();
  }
}
