import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';

final calendarIndicatorSettingsControllerProvider =
    Provider<CalendarIndicatorSettingsController>((ref) {
      return CalendarIndicatorSettingsController(ref);
    });

class CalendarIndicatorSettingsController {
  CalendarIndicatorSettingsController(this._ref);

  final Ref _ref;

  Future<void> setOvertimeIndicatorThreshold(double hours) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }

    await _ref
        .read(userProfileRepositoryProvider)
        .updateOvertimeIndicatorThreshold(uid: user.uid, hours: hours);
  }
}
