import '../../core/date_time/local_date.dart';

class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.currencyCode,
    required this.locale,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.onboardingComplete = false,
  });

  final String displayName;
  final String currencyCode;
  final String locale;

  /// IANA zone used for all financial calendar calculations.
  final String timezone;
  final LocalDate? dateOfBirth;
  final bool onboardingComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? displayName,
    String? currencyCode,
    String? locale,
    String? timezone,
    LocalDate? dateOfBirth,
    bool clearDateOfBirth = false,
    bool? onboardingComplete,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        currencyCode: currencyCode ?? this.currencyCode,
        locale: locale ?? this.locale,
        timezone: timezone ?? this.timezone,
        dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
