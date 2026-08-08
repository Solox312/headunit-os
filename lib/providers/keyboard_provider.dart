import 'package:flutter/material.dart';

class KeyboardProvider extends ChangeNotifier {
  bool _isVisible = false;
  TextEditingController? _controller;
  VoidCallback? _onSubmitted;

  bool get isVisible => _isVisible;
  TextEditingController? get controller => _controller;
  VoidCallback? get onSubmitted => _onSubmitted;

  void show(TextEditingController controller, {VoidCallback? onSubmitted}) {
    _controller = controller;
    _onSubmitted = onSubmitted;
    _isVisible = true;
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    _controller = null;
    _onSubmitted = null;
    notifyListeners();
  }
}
