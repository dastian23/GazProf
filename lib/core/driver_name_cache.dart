import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gazprof/core/constants.dart';

/// Cache centralizat pentru numele șoferilor.
/// Înregistrările expiră după [_ttl] pentru a reflecta schimbările de nume.
class DriverNameCache {
  DriverNameCache._();
  static final DriverNameCache instance = DriverNameCache._();

  static const Duration _ttl = Duration(minutes: 30);

  final Map<String, _Entry> _cache = {};

  /// Returnează numele din cache dacă e valid, altfel null.
  String? get(String uid) {
    final entry = _cache[uid];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > _ttl) {
      _cache.remove(uid);
      return null;
    }
    return entry.name;
  }

  /// Stochează un nume în cache.
  void set(String uid, String name) {
    _cache[uid] = _Entry(name, DateTime.now());
  }

  /// Invalidează un singur uid (util când un user îți schimbă numele).
  void invalidate(String uid) => _cache.remove(uid);

  /// Goलते tot cache-ul.
  void clear() => _cache.clear();

  /// Preîncarcă numele lipsă din Firestore într-un singur batch.
  Future<void> preload(Iterable<String?> ids) async {
    final missing = ids
        .whereType<String>()
        .where((id) => get(id) == null)
        .toList();
    if (missing.isEmpty) return;

    await Future.wait(missing.map((id) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(id)
            .get();
        if (doc.exists) {
          set(id, (doc.data() as Map)['nume'] ?? 'Necunoscut');
        }
      } catch (e) {
        debugPrint('DriverNameCache: eroare la preload $id: $e');
      }
    }));
  }
}

class _Entry {
  final String name;
  final DateTime storedAt;
  _Entry(this.name, this.storedAt);
}
