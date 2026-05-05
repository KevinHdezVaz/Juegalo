import 'package:intl/intl.dart';

extension IntFormatX on int {
  /// Formats an integer with thousands separator: 10000 → "10,000"
  String get formatted => NumberFormat('#,###').format(this);
}

extension DoubleUsdX on double {
  /// Formatea USD sin redondear — hasta 4 decimales, sin trailing zeros.
  /// 1.0 → "$1"  |  1.001 → "$1.001"  |  1.5 → "$1.5"
  String get fmtUsd {
    final s = toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '\$$s';
  }
}
