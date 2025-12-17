import 'package:flutter/material.dart';

/// Application spacing constants
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4dp)
  static const double unit = 4.0;

  // Spacing values
  static const double xxs = 4.0; // unit * 1
  static const double xs = 8.0; // unit * 2
  static const double sm = 12.0; // unit * 3
  static const double md = 16.0; // unit * 4
  static const double lg = 24.0; // unit * 6
  static const double xl = 32.0; // unit * 8
  static const double xxl = 48.0; // unit * 12
  static const double xxxl = 64.0; // unit * 16

  // Padding presets
  static const EdgeInsets paddingXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Border radius presets
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
}
