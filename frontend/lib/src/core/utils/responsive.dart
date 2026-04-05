import 'package:flutter/material.dart';

/// Breakpoints and helpers for responsive layouts.
class Responsive {
  Responsive._();

  static const double mobile = 600;
  static const double tablet = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static double horizontalPadding(BuildContext context) =>
      isMobile(context) ? 16 : 24;

  static double contentMaxWidth(BuildContext context) =>
      isMobile(context) ? double.infinity : 700;
}