import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFD4667B);
  static const primaryLight = Color(0xFFF2A4B4);
  static const primaryDark = Color(0xFFB04560);
  static const background = Color(0xFFF8F4F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF2A2A2A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const divider = Color(0xFFEEEEEE);
  static const kakao = Color(0xFFFEE500);
  static const periodRed = Color(0xFFE57373);

  static const gradient = LinearGradient(
    colors: [Color(0xFFD4667B), Color(0xFFF4A0B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const pinkShadow = [
    BoxShadow(color: Color(0x30D4667B), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
