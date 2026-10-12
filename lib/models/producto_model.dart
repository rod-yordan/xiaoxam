import 'variante_model.dart';

class ProductoModel {
  final int id;
  final String titulo;
  final List<String> detalles;
  final double precio;
  final double? precioOferta;
  final int? descuento;
  final List<String> imagenes;
  final String imagenPrincipal;
  final String? categoria;
  final int? categoriaId;
  final String? marca;
  final List<String> tallas;
  final List<String> colores;
  final int stock;
  final String? sku;
  final bool disponible;
  final bool enOferta;
  final List<VarianteModel> variantes;

  ProductoModel({
    required this.id,
    required this.titulo,
    required this.detalles,
    required this.precio,
    this.precioOferta,
    this.descuento,
    required this.imagenes,
    required this.imagenPrincipal,
    this.categoria,
    this.categoriaId,
    this.marca,
    required this.tallas,
    required this.colores,
    required this.stock,
    this.sku,
    required this.disponible,
    required this.enOferta,
    required this.variantes,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    // ── Helpers seguros
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? toDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    String toStr(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is num) return value.toString();
      if (value is List && value.isNotEmpty) {
        return value.first?.toString() ?? '';
      }
      return value.toString();
    }

    List<String> toStrList(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .map((e) {
            if (e is String) return e;
            if (e is num) return e.toString();
            if (e is Map) {
              return (e['url'] ?? e['imagen'] ?? e['ruta'] ?? e['nombre'] ?? '')
                  .toString();
            }
            return e?.toString() ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<VarianteModel> variantes = [];
    if (json['variantes'] != null && json['variantes'] is List) {
      variantes = (json['variantes'] as List)
          .where((v) => v is Map)
          .map((v) => VarianteModel.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }

    return ProductoModel(
      id: (json['id_producto'] ?? json['id'] ?? 0) as int,
      titulo: toStr(json['nombre_producto'] ?? json['titulo']),
      detalles: toStrList(
        json['detalles'] ?? json['descripcion'],
      ), // 👈 acepta ambos
      precio: toDouble(json['precio']),
      precioOferta: toDoubleOrNull(json['precio_oferta']),
      descuento: json['descuento'] is int ? json['descuento'] : null,
      imagenes: toStrList(json['imagenes']),
      imagenPrincipal: toStr(json['imagen_principal'] ?? json['imagen']),
      categoria: toStr(json['categoria_nombre'] ?? json['categoria']),
      categoriaId: json['id_categoria'] ?? json['categoria_id'],
      marca: json['marca'] != null ? toStr(json['marca']) : null,
      tallas: toStrList(json['tallas']),
      colores: toStrList(json['colores']),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sku: json['sku'] != null ? toStr(json['sku']) : null,
      disponible: json['disponible'] ?? true,
      enOferta: json['en_oferta'] ?? false,
      variantes: variantes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'detalles': detalles,
      'precio': precio,
      'precio_oferta': precioOferta,
      'descuento': descuento,
      'imagenes': imagenes,
      'imagen_principal': imagenPrincipal,
      'categoria': categoria,
      'categoria_id': categoriaId,
      'marca': marca,
      'tallas': tallas,
      'colores': colores,
      'stock': stock,
      'sku': sku,
      'disponible': disponible,
      'en_oferta': enOferta,
      'variantes': variantes.map((v) => v.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'detalles': detalles,
      'precio': precio,
      'precio_oferta': precioOferta,
      'descuento': descuento,
      'imagenes': imagenes,
      'imagen_principal': imagenPrincipal,
      'categoria': categoria,
      'categoria_id': categoriaId,
      'marca': marca,
      'tallas': tallas,
      'colores': colores,
      'stock': stock,
      'sku': sku,
      'disponible': disponible,
      'en_oferta': enOferta,
      'variantes': variantes.map((v) => v.toJson()).toList(),
    };
  }

  VarianteModel? getVariante({required String talla, String? color}) {
    try {
      return variantes.firstWhere(
        (v) => v.talla == talla && (color == null || v.color == color),
      );
    } catch (e) {
      return null;
    }
  }

  bool tieneStockTalla(String talla) {
    return variantes.any((v) => v.talla == talla && v.stock > 0);
  }

  List<String> getColoresPorTalla(String talla) {
    return variantes
        .where((v) => v.talla == talla && v.stock > 0 && v.color != null)
        .map((v) => v.color!)
        .toSet()
        .toList();
  }

  VarianteModel? getVarianteById(int idVariante) {
    try {
      return variantes.firstWhere((v) => v.id == idVariante);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, String>> getColoresConHex() {
    final Map<String, Map<String, String>> unicos = {};

    for (final v in variantes) {
      if (v.color == null || v.color!.isEmpty) continue;
      if (unicos.containsKey(v.color)) continue;

      unicos[v.color!] = {'nombre': v.color!, 'hex': v.colorHex ?? '#cccccc'};
    }

    return unicos.values.toList();
  }

  String? getPrimeraImagenPorColor(String color) {
    for (final v in variantes) {
      if (v.color?.toLowerCase() == color.toLowerCase()) {
        if (v.imagenes.isNotEmpty) {
          return v.imagenes.first;
        }
      }
    }
    return null;
  }

  List<String> getImagenesPorColor(String color) {
    final List<String> resultado = [];
    for (final v in variantes) {
      if (v.color?.toLowerCase() == color.toLowerCase()) {
        resultado.addAll(v.imagenes);
      }
    }
    return resultado.toSet().toList();
  }

  bool tieneStockCombinacion(String talla, String color) {
    return variantes.any(
      (v) =>
          v.talla == talla &&
          v.color?.toLowerCase() == color.toLowerCase() &&
          v.stock > 0,
    );
  }
}
