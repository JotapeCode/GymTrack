import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _short = DateFormat('dd/MM', 'pt_BR');
  static final _long = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
  static final _number = NumberFormat('#,##0.##', 'pt_BR');

  static String date(DateTime d) => _date.format(d);
  static String shortDate(DateTime d) => _short.format(d);

  static String longDate(DateTime d) {
    final text = _long.format(d);
    return text[0].toUpperCase() + text.substring(1);
  }

  /// "1 série", "3 séries".
  static String plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  static String number(num value) => _number.format(value);

  static String weight(num kg) => '${_number.format(kg)} kg';

  static String signedWeight(num kg) =>
      '${kg > 0 ? '+' : ''}${_number.format(kg)} kg';

  /// "Hoje", "Ontem", "Há 3 dias" ou a data.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = a.difference(b).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff > 1 && diff < 7) return 'Há $diff dias';
    return date(d);
  }

  static String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Valor para preencher um campo editável (sem separador de milhar).
  static String decimalInput(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString().replaceAll('.', ',');

  /// Aceita vírgula ou ponto como separador decimal.
  static double? parseDecimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
}
