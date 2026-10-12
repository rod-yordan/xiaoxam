// models/cupon_model.dart

class CuponModel {
  final int id;
  final String codigo;
  final double monto; // monto de descuento en S/
  final double montoMinimo; // monto mínimo de compra
  final String fechaVencimiento;

  CuponModel({
    required this.id,
    required this.codigo,
    required this.monto,
    required this.montoMinimo,
    required this.fechaVencimiento,
  });

  factory CuponModel.fromJson(Map<String, dynamic> json) {
    return CuponModel(
      id: json['id_cupon'] ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      montoMinimo: (json['monto_minimo'] as num?)?.toDouble() ?? 0,
      fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
    );
  }

  /// Formatea la fecha para mostrar "Vence: dd/mm/yyyy"
  String get fechaFormateada {
    try {
      final partes = fechaVencimiento.split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
      return fechaVencimiento;
    } catch (_) {
      return fechaVencimiento;
    }
  }
}
