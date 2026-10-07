import 'package:flutter/material.dart';

/// Пороги из ПР6 (360 / 768 / 1280 / 1920).
abstract final class AppBreakpoints {
  static const tablet = 768.0;
  static const desktop = 1280.0;
  static const wide = 1920.0;
  static const maxContentWidth = 1400.0;
  static const formMaxWidth = 720.0;
  static const dialogMaxWidth = 480.0;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool useBottomNavigation(BuildContext context) =>
      widthOf(context) < tablet;

  static bool useTableOnLists(BuildContext context) =>
      widthOf(context) >= desktop;

  static bool showAllRailLabels(BuildContext context) =>
      widthOf(context) >= desktop;

  static bool constrainPageWidth(BuildContext context) =>
      widthOf(context) >= wide;
}
