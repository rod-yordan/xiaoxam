// models/tipo_documento_model.dart

class TipoDocumentoModel {
  final int id;
  final String nombre;

  TipoDocumentoModel({required this.id, required this.nombre});

  factory TipoDocumentoModel.fromJson(Map<String, dynamic> json) {
    return TipoDocumentoModel(
      id: (json['id'] ?? json['id_tipo_documento'] ?? 0) as int,
      nombre: (json['nombre'] ?? json['nombre_tipo_documento'] ?? '')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}
