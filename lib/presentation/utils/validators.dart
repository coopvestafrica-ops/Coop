/// Validators for form fields
class Validators {
  /// Validates that a value is not empty
  static String? validateNotEmpty(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
  return '$fieldName is required';
  }
  return null;
  }

  /// Validates email format
  static String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
  return 'Email is required';
  }
  final emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
 );
  if (!emailRegex.hasMatch(value)) {
  return 'Please enter a valid email address';
  }
  return null;
  }

  /// Validates phone number format
  static String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
  return 'Phone number is required';
  }
  final phoneRegex = RegExp(r'^[0-9]{10,15}$');
  final cleanedValue = value.replaceAll(RegExp(r'\s+'), '');
  if (!phoneRegex.hasMatch(cleanedValue)) {
  return 'Please enter a valid phone number';
  }
  return null;
  }

  /// Validates name
  static String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
  return 'Name is required';
  }
  if (value.trim().length < 2) {
  return 'Name must be at least 2 characters';
  }
  return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
  return 'Password is required';
  }
  if (value.length < 8) {
  return 'Password must be at least 8 characters';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
  return 'Password must contain an uppercase letter';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
  return 'Password must contain a lowercase letter';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
  return 'Password must contain a number';
  }
  return null;
  }
}
