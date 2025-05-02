import 'package:flutter/material.dart';

class LikesNotifier extends ChangeNotifier {
  final Map<int, bool> _likes = {};
  final Map<int, int> _likesCount = {};

  bool isLiked(int postId) => _likes[postId] ?? false;
  int getLikesCount(int postId) => _likesCount[postId] ?? 0;

  void toggleLike(int postId, bool isLikedNow, int newCount) {
    _likes[postId] = isLikedNow;
    _likesCount[postId] = newCount;
    notifyListeners();
  }

  void setLikes(Map<int, bool> initialLikes, Map<int, int> counts) {
    _likes.addAll(initialLikes);
    _likesCount.addAll(counts);
    notifyListeners();
  }
}
