import 'package:flutter/material.dart';

/// Extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);

  /// Get the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get the bottom padding (safe area)
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  /// Get the top padding (safe area)
  double get topPadding => MediaQuery.of(this).padding.top;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Show a snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  /// Hide the current snackbar
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}

/// Extension methods for String
extension StringExtensions on String {
  /// Capitalize the first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid phone number (Côte d'Ivoire format)
  bool get isValidPhone {
    // Accepts formats: +225 XX XX XX XX XX or 07 XX XX XX XX
    return RegExp(r'^(\+225|00225)?[0-9]{10}$').hasMatch(replaceAll(' ', ''));
  }

  /// Format phone number for display
  String get formatPhone {
    final cleaned = replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8, 10)}';
    }
    return this;
  }
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format date as "dd/MM/yyyy"
  String get formatDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Format time as "HH:mm"
  String get formatTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format date and time
  String get formatDateTime {
    return '$formatDate $formatTime';
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// Extension methods for num
extension NumExtensions on num {
  /// Format as currency (XOF)
  String get formatCurrency {
    return '${toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} FCFA';
  }

  /// Format as distance (km or m)
  String get formatDistance {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)} km';
    }
    return '${toStringAsFixed(0)} m';
  }
}
