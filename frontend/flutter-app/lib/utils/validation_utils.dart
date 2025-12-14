class ValidationUtils {
  static final RegExp _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Very forgiving international phone validation.
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  static bool isValidEmail(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    return _emailRegex.hasMatch(value);
  }

  static bool isValidPhone(String input) {
    final value = input.trim().replaceAll(' ', '');
    if (value.isEmpty) return false;
    return _phoneRegex.hasMatch(value);
  }

  static String? validateRequired(String? value, {String message = 'Required'}) {
    if (value == null) return message;
    if (value.trim().isEmpty) return message;
    return null;
  }

  static String? validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email';
    if (!isValidEmail(v)) return 'Please enter a valid email';
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < minLength) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your phone number';
    if (!isValidPhone(v)) return 'Please enter a valid phone number';
    return null;
  }
}
