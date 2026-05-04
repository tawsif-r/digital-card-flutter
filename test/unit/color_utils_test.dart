import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_card/shared/utils/color_utils.dart';

void main() {
  group('hexToColor', () {
    test('converts hex string to Color', () {
      expect(hexToColor('#1A73E8'), equals(const Color(0xFF1A73E8)));
      expect(hexToColor('#FFFFFF'), equals(const Color(0xFFFFFFFF)));
      expect(hexToColor('#000000'), equals(const Color(0xFF000000)));
    });
  });

  group('colorToHex', () {
    test('converts Color to hex string', () {
      expect(colorToHex(const Color(0xFF1A73E8)), equals('#1A73E8'));
      expect(colorToHex(const Color(0xFFFFFFFF)), equals('#FFFFFF'));
      expect(colorToHex(const Color(0xFF000000)), equals('#000000'));
    });

    test('roundtrip: hex -> Color -> hex', () {
      const hex = '#4CAF50';
      expect(colorToHex(hexToColor(hex)), equals(hex));
    });
  });
}
