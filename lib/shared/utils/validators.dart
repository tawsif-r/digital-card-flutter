class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (value.length > 72) return 'Password must be at most 72 characters.';
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final re = RegExp(r'^https?://');
    if (!re.hasMatch(value.trim())) return 'Enter a valid URL (https://...).';
    return null;
  }

  static String? hexColor(String? value) {
    if (value == null || value.trim().isEmpty) return 'Color is required.';
    final re = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid hex color (#RRGGBB).';
    return null;
  }
}
