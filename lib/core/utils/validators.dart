/// Form validators shared across auth and property screens.
class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
  );

  static final RegExp _stateRegex = RegExp(r'^[A-Za-z]{2}$');

  static final RegExp _zipRegex = RegExp(r'^\d{5}(-\d{4})?$');

  static String? email(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? usState(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'State is required';
    if (!_stateRegex.hasMatch(trimmed)) {
      return 'Use a 2-letter state code (e.g. CA)';
    }
    return null;
  }

  static String? zipCode(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'ZIP code is required';
    if (!_zipRegex.hasMatch(trimmed)) {
      return 'Enter a valid ZIP (12345 or 12345-6789)';
    }
    return null;
  }
}
