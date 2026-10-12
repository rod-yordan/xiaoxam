class VarianteModel {
  final int id;
  final String talla;
  final String? color;
  final String? colorHex;
  final int stock;
  final String sku;
  final bool disponible;
  final List<String> imagenes;
  final String? imagenPrincipal;

  VarianteModel({
    required this.id,
    required this.talla,
    this.color,
    this.colorHex,
    required this.stock,
    required this.sku,
    required this.disponible,
    this.imagenes = const [],
    this.imagenPrincipal,
  });

  factory VarianteModel.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is num) return value.toString();
      if (value is List && value.isNotEmpty) {
        return value.first?.toString() ?? '';
      }
      return value.toString();
    }

    List<String> imagenes = [];
    if (json['imagenes'] != null && json['imagenes'] is List) {
      imagenes = (json['imagenes'] as List)
          .map((img) {
            if (img is String) return img;
            if (img is Map) {
              return (img['url'] ?? img['imagen'] ?? img['ruta'] ?? '')
                  .toString();
            }
            return img?.toString() ?? '';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return VarianteModel(
      id: (json['id'] ?? json['id_variante'] ?? 0) as int,
      talla: toStr(json['talla']),
      color: json['color'] != null ? toStr(json['color']) : null,
      colorHex: json['color_hex'] != null ? toStr(json['color_hex']) : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sku: toStr(json['sku']),
      disponible:
          json['disponible'] ?? ((json['stock'] as num?)?.toInt() ?? 0) > 0,
      imagenes: imagenes,
      imagenPrincipal: json['imagen_principal'] != null
          ? toStr(json['imagen_principal'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talla': talla,
      'color': color,
      'color_hex': colorHex,
      'stock': stock,
      'sku': sku,
      'disponible': disponible,
      'imagenes': imagenes,
      'imagen_principal': imagenPrincipal,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talla': talla,
      'color': color,
      'colorHex': colorHex,
      'stock': stock,
      'sku': sku,
      'disponible': disponible,
      'imagenes': imagenes,
      'imagen_principal': imagenPrincipal,
    };
  }

  String get nombreCompleto {
    if (color != null && color!.isNotEmpty) {
      return 'Talla $talla - $color';
    }
    return 'Talla $talla';
  }

  bool get esColorClaro {
    if (colorHex == null || colorHex!.isEmpty) return false;
    final hex = colorHex!.replaceAll('#', '');
    if (hex.length != 6) return false;

    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);

    final luminancia = 0.299 * r + 0.587 * g + 0.114 * b;
    return luminancia > 230;
  }
}
