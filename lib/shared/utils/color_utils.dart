import 'package:flutter/material.dart';

Color hexToColor(String hex) =>
    Color(int.parse(hex.replaceFirst('#', '0xFF')));

String colorToHex(Color color) =>
    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
