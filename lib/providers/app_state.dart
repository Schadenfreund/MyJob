import 'package:flutter/material.dart';

/// Global app state provider
class AppState extends ChangeNotifier {
  int _currentNavIndex = 0;
  bool _isInitialized = false;

  int get currentNavIndex => _currentNavIndex;
  bool get isInitialized => _isInitialized;

  /// Set navigation index
  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  /// Mark app as initialized
  void setInitialized() {
    _isInitialized = true;
    notifyListeners();
  }
}
