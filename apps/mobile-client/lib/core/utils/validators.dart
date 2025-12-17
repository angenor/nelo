/// Form validators
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Validate phone number (Côte d'Ivoire format)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 10) {
      return 'Le numéro doit contenir 10 chiffres';
    }
    if (!RegExp(r'^(0[157])[0-9]{8}$').hasMatch(cleaned)) {
      return 'Format de numéro invalide';
    }
    return null;
  }

  /// Validate PIN code (4-6 digits)
  static String? pin(String? value, {int length = 4}) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code PIN est requis';
    }
    if (value.length != length) {
      return 'Le code PIN doit contenir $length chiffres';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Le code PIN ne doit contenir que des chiffres';
    }
    return null;
  }

  /// Validate OTP code
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code OTP est requis';
    }
    if (value.length != length) {
      return 'Le code OTP doit contenir $length chiffres';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Le code OTP ne doit contenir que des chiffres';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int minLength, [String fieldName = 'Ce champ']) {
    if (value == null || value.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractères';
    }
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int maxLength, [String fieldName = 'Ce champ']) {
    if (value != null && value.length > maxLength) {
      return '$fieldName ne doit pas dépasser $maxLength caractères';
    }
    return null;
  }

  /// Validate minimum value
  static String? minValue(num? value, num minValue, [String fieldName = 'La valeur']) {
    if (value == null || value < minValue) {
      return '$fieldName doit être supérieure ou égale à $minValue';
    }
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
