import 'package:intl/intl.dart';

import '../constants/pantry_constants.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _date = DateFormat('d MMM yyyy');
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final _monthYear = DateFormat('MMMM yyyy');

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String monthYear(DateTime value) => _monthYear.format(value);

  static String quantity(double quantity, String unit) {
    final qtyText = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return '$qtyText ${PantryUnits.label(unit)}';
  }
}
