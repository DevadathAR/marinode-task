import 'package:flutter/material.dart';

class AppTextStyle {
  static TextStyle regularText(
          {required double size, Color? color, FontStyle? fontstyle}) =>
      TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w400,
          color: color,
          fontStyle: fontstyle);
  static TextStyle mediumText({required double size, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
  static TextStyle semiboldText({required double size, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );
  static TextStyle boldText({required double size, Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
