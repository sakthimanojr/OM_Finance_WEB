import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String currency(num? amount) => _inrFormat.format(amount ?? 0);

  static String date(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static DateTime? tryParse(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
