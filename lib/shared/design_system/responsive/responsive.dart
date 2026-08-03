library;

import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'app_layout.dart';

/// Responsive helper used throughout the application.
abstract final class Responsive {
  const Responsive._();

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isMobile(BuildContext context) {
    return width(context) < AppBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= AppBreakpoints.mobile &&
        width(context) < AppBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return width(context) >= AppBreakpoints.desktop;
  }

  static bool isWideDesktop(BuildContext context) {
    return width(context) >= AppBreakpoints.wideDesktop;
  }

  static double maxContentWidth(BuildContext context) {
    return isWideDesktop(context)
        ? AppLayout.dashboardMaxWidth
        : AppLayout.maxContentWidth;
  }
}