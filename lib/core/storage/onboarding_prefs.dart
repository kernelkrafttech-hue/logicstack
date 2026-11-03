import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kOnboardingSeenKey = 'onboarding.seen.v1';

/// Persisted "has the user finished onboarding" flag. We treat
/// SharedPreferences as the source of truth so the welcome carousel only
/// appears on a brand-new install — if a user signs out we don't replay it.
class OnboardingPrefs {
  OnboardingPrefs(this._prefs);

  final SharedPreferences _prefs;

  bool get hasSeenWelcome => _prefs.getBool(_kOnboardingSeenKey) ?? false;

  Future<void> markSeen() => _prefs.setBool(_kOnboardingSeenKey, true);
}

/// Loaded once at app startup; everything that reads onboarding state
/// awaits this future so we don't flash the dashboard before the prefs
/// load.
final FutureProvider<OnboardingPrefs> onboardingPrefsProvider =
    FutureProvider<OnboardingPrefs>(
  (FutureProviderRef<OnboardingPrefs> ref) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return OnboardingPrefs(prefs);
  },
);

/// Reactive flag wrapper. Stays in sync with the prefs after [markSeen]
/// is called from the onboarding screen.
final StateProvider<bool> onboardingSeenProvider = StateProvider<bool>(
  (StateProviderRef<bool> ref) {
    final OnboardingPrefs? prefs =
        ref.watch(onboardingPrefsProvider).valueOrNull;
    return prefs?.hasSeenWelcome ?? true; // default true → don't block
  },
);
