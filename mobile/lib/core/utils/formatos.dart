import 'package:intl/intl.dart';

/// Formateo consistente de moneda y fechas en toda la aplicacion.
class Formatos {
  const Formatos._();

  static final NumberFormat _moneda = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  static final NumberFormat _compacto = NumberFormat.compact();

  static final DateFormat _fechaHora = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy');

  static String moneda(num valor) => _moneda.format(valor);

  static String monedaCompacta(num valor) => '\$${_compacto.format(valor)}';

  static String fechaHora(int epochMs) =>
      _fechaHora.format(DateTime.fromMillisecondsSinceEpoch(epochMs));

  static String fecha(int epochMs) =>
      _fecha.format(DateTime.fromMillisecondsSinceEpoch(epochMs));

  /// Diferencia legible entre [epochMs] y ahora ("hace 5 min").
  static String hace(int epochMs) {
    if (epochMs <= 0) return 'nunca';
    final diferencia = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(epochMs),
    );
    if (diferencia.inMinutes < 1) return 'hace unos segundos';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    return 'hace ${diferencia.inDays} d';
  }
}
