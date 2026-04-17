import 'package:flutter/material.dart';

abstract class AppColors {
  static const kBlue = Color(0xFF2563EB);
  static const kGreen = Color(0xFF16A34A);
  static const kRed = Color(0xFFDC2626);
  static const kYellow = Color(0xFFF59E0B);
  static const kGrey = Color(0xFF6B7280);
  static const kLight = Color(0xFFF3F4F6);

  static const kNavyBlue = Color(0xFF003087);
  static const kErrorRed = Color(0xFFC0392B);
  static const kSuccessGreen = Color(0xFF2E7D6B);

  // Form
  static const kFieldBg     = Color(0xFFF2F0EB);
  static const kFieldBorder = Color(0xFFD8D6CF);
  static const kFieldText   = Color(0xFF6B6B7A);

  // Line map
  static const kLineColors = <String, Color>{
    'azul': kBlue,
    'verde': kGreen,
    'vermelha': kRed,
    'amarela': kYellow,
  };
}