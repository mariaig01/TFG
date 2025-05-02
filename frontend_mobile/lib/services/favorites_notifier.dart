// services/favorites_notifier.dart
import 'package:flutter/material.dart';

class FavoritesNotifier extends ChangeNotifier {
  final Set<int> _guardados = {};

  bool isSaved(int postId) => _guardados.contains(postId);

  void toggleSave(int postId, bool isSavedNow) {
    if (isSavedNow) {
      _guardados.add(postId);
    } else {
      _guardados.remove(postId);
    }
    notifyListeners();
  }

  void setGuardados(Set<int> initialSaved) {
    _guardados.clear();
    _guardados.addAll(initialSaved);
    notifyListeners();
  }
}
