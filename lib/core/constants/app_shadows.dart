import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0D0F172A), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x0D0F172A),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x140F172A),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1A0F172A),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x140F172A),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}
