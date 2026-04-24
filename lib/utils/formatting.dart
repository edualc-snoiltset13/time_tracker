// lib/utils/formatting.dart
import 'package:intl/intl.dart';

/// Formats an item price using the currency's locale-specific symbol.
/// Falls back to a plain "CODE 0.00" string if the currency code is unknown
/// to intl. Returns null when there is no price to display.
String? formatItemPrice(double? price, String? currency) {
  if (price == null) return null;
  final code = (currency == null || currency.isEmpty) ? 'USD' : currency;
  try {
    return NumberFormat.simpleCurrency(name: code).format(price);
  } catch (_) {
    return '$code ${price.toStringAsFixed(2)}';
  }
}
