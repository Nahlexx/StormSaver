import 'package:flutter/material.dart';

class SidebarProvider extends ChangeNotifier {
  double _width = 260;
  static const double minWidth = 220;
  static const double maxWidth = 400;

  double get width => _width;

  void setWidth(double newWidth) {
    if (newWidth >= minWidth && newWidth <= maxWidth && _width != newWidth) {
      _width = newWidth;
      notifyListeners();
    }
  }

  void resetWidth() {
    if (_width != 260) {
      _width = 260;
      notifyListeners();
    }
  }
} 