import 'package:xiaoxa/models/producto_model.dart';
import 'package:xiaoxa/models/variante_model.dart';

class ItemCarritoModel {
  final int idDetalle;
  final int cantidad;
  final ProductoModel producto;
  final VarianteModel variante;

  ItemCarritoModel({
    required this.idDetalle,
    required this.cantidad,
    required this.producto,
    required this.variante,
  });

  factory ItemCarritoModel.fromJson(Map<String, dynamic> json) {
    // El backend devuelve estructura anidada:
    //   { id_detalle, cantidad, variante: { ..., producto: {...} } }
    final varianteJson = json['variante'] as Map<String, dynamic>? ?? {};
    final productoJson =
        varianteJson['producto'] as Map<String, dynamic>? ?? {};

    return ItemCarritoModel(
      idDetalle: (json['id_detalle'] ?? 0) as int,
      cantidad: (json['cantidad'] ?? 1) as int,
      producto: ProductoModel.fromJson(productoJson),
      variante: VarianteModel.fromJson(varianteJson),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_detalle': idDetalle,
      'id_variante': variante.id,
      'id_producto': producto.id,
      'titulo': producto.titulo,
      'detalles': producto.detalles,
      'precio': producto.precio,
      'precio_oferta': producto.precioOferta,
      'descuento': producto.descuento,
      'imagenes': producto.imagenes,
      'imagen_principal': producto.imagenPrincipal,
      'categoria': producto.categoria,
      'categoria_id': producto.categoriaId,
      'marca': producto.marca,
      'talla': variante.talla,
      'color': variante.color,
      'stock': variante.stock,
      'sku': variante.sku,
      'cantidad': cantidad,
    };
  }

  double get subtotal {
    final precio = producto.precioOferta ?? producto.precio;
    return precio * cantidad;
  }

  String get titulo => producto.titulo;
  String get talla => variante.talla;
  String? get color => variante.color;
}
