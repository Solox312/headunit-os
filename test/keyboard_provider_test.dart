import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/providers/keyboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyboardProvider State Tests', () {
    test('KeyboardProvider initializes hidden', () {
      final provider = KeyboardProvider();
      expect(provider.isVisible, isFalse);
      expect(provider.controller, isNull);
    });

    test('show opens keyboard with text controller', () {
      final provider = KeyboardProvider();
      final controller = TextEditingController(text: 'test');

      provider.show(controller);
      expect(provider.isVisible, isTrue);
      expect(provider.controller, equals(controller));
    });

    test('hide closes keyboard', () {
      final provider = KeyboardProvider();
      final controller = TextEditingController();

      provider.show(controller);
      expect(provider.isVisible, isTrue);

      provider.hide();
      expect(provider.isVisible, isFalse);
      expect(provider.controller, isNull);
    });
  });
}
