import 'package:equatable/equatable.dart';

/// Provider opening hours schedule
class ProviderSchedule extends Equatable {
  const ProviderSchedule({
    required this.id,
    required this.providerId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  final String id;
  final String providerId;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String openTime; // Format: "HH:mm"
  final String closeTime; // Format: "HH:mm"
  final bool isClosed;

  @override
  List<Object?> get props => [id, providerId, dayOfWeek];

  /// Get day name in French
  String get dayName {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[dayOfWeek];
  }

  /// Get formatted hours string
  String get hoursText {
    if (isClosed) return 'Fermé';
    return '$openTime - $closeTime';
  }
}
