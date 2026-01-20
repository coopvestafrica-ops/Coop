import 'package:flutter/material.dart';

/// App-wide color constants for compatibility
/// Maps common color names to CoopvestColors
class AppColors {
  // Primary colors
  static Color get primary => const Color(0xFF1A5D1A);
  static Color get primaryLight => const Color(0xFF2E8B2E);
  static Color get primaryDark => const Color(0xFF0D3D0D);
  
  // Secondary colors
  static Color get secondary => const Color(0xFFFFB800);
  static Color get secondaryLight => const Color(0xFFFFD54F);
  static Color get secondaryDark => const Color(0xFFC7A600);
  // Text colors
  static Color get textPrimary => const Color(0xFF1A1A1A);
  static Color get textSecondary => const Color(0xFF6B7280);
  static Color get textTertiary => const Color(0xFF9CA3AF);
  static Color get textLight => const Color(0xFFFFFFFF);
  // Background colors
  static Color get background => const Color(0xFFF9FAFB);
  static Color get surface => const Color(0xFFFFFFFF);
  static Color get surfaceVariant => const Color(0xFFF3F4F6);
  // Status colors
  static Color get success => const Color(0xFF22C55E);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get error => const Color(0xFFEF4444);
  static Color get info => const Color(0xFF3B82F6);
  // Neutral colors
  static Color get border => const Color(0xFFE5E7EB);
  static Color get divider => const Color(0xFFF3F4F6);
  static Color get disabled => const Color(0xFFD1D5DB);
  static Color get overlay => const Color(0xFF000000);
  // Transparent
  static Color get transparent => Colors.transparent;
  // Helper method to get color from string name
  static Color? fromName(String name) {
  switch (name.toLowerCase()) {
  case 'primary': return primary;
  case 'secondary': return secondary;
  case 'success': return success;
  case 'warning': return warning;
  case 'error': return error;
  case 'info': return info;
  case 'textprimary': return textPrimary;
  case 'textsecondary': return textSecondary;
  case 'background': return background;
  case 'surface': return surface;
  default: return null;
  }
  }
}
/// Currency formatting utilities
class AppCurrencyFormatter {
  static const String nairaSymbol = '₦';
  static const String dollarSymbol = '\$';
  static const String poundSymbol = '£';
  static const String euroSymbol = '€';
  /// Format number with thousand separators
  static String formatNumber(dynamic value, {int decimalPlaces = 0}) {
  if (value == null) return '';
  
  double numValue = 0.0;
  if (value is int) {
  numValue = value.toDouble();
  } else if (value is double) {
  numValue = value;
  } else if (value is String) {
  numValue = double.tryParse(value) ?? 0.0;
  final formatString = decimalPlaces > 0 
  ? '#,##0.${'0' * decimalPlaces}' 
  : '#,##0';
  // Using NumberFormat
  final formatter = NumberFormat(formatString, 'en_US');
  return formatter.format(numValue);
  /// Format as currency (Naira)
  static String formatNaira(dynamic value, {bool showSymbol = true}) {
  final formatted = formatNumber(value);
  return showSymbol ? '$nairaSymbol $formatted' : formatted;
  /// Format as currency (USD)
  static String formatUSD(dynamic value, {bool showSymbol = true}) {
  return showSymbol ? '$dollarSymbol $formatted' : formatted;
  /// Parse currency string to double
  static double parseCurrency(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? 0.0;
/// Extension methods for number formatting
extension NumberExtension on double {
  String format({int decimalPlaces = 0}) {
  return AppCurrencyFormatter.format(this, decimalPlaces: decimalPlaces);
  String toNaira({bool showSymbol = true}) {
  return AppCurrencyFormatter.formatNaira(this, showSymbol: showSymbol);
  String toUSD({bool showSymbol = true}) {
  return AppCurrencyFormatter.formatUSD(this, showSymbol: showSymbol);
extension IntExtension on int {
/// String extension for common operations
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
  if (isEmpty) return this;
  return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  /// Capitalize each word
  String capitalizeWords() {
  return split(' ').map((word) => word.capitalize()).join(' ');
  /// Check if string is numeric
  bool get isNumeric {
  if (isEmpty) return false;
  return double.tryParse(this) != null;
  /// Get numeric value
  double? get numericValue => double.tryParse(this);