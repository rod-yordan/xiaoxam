import 'package:flutter/material.dart';
import 'package:xiaoxa/utils/api_config.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback? onTap;
  final bool mostrarCorazon;
  final bool esFavorito;
  final VoidCallback? onCorazonTap;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.mostrarCorazon = false,
    this.esFavorito = false,
    this.onCorazonTap,
  });

  String _formatearPrecio(dynamic precio) {
    if (precio == null) return '0.00';

    if (precio is int) return precio.toStringAsFixed(2);
    if (precio is double) return precio.toStringAsFixed(2);

    if (precio is String) {
      final numero = double.tryParse(precio);
      return numero?.toStringAsFixed(2) ?? '0.00';
    }

    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    String imagenOriginal =
        producto['imagen_principal']?.toString().trim() ?? '';

    final String imagenPrincipal = imagenOriginal.replaceFirst(
      '${ApiConfig.baseUrl}/productos/',
      '${ApiConfig.apiUrl}/imagen/',
    );

    final double precio = (producto['precio'] is num)
        ? (producto['precio'] as num).toDouble()
        : double.tryParse(producto['precio']?.toString() ?? '') ?? 0.0;

    final dynamic precioOfertaRaw = producto['precio_oferta'];
    double? precioOferta;
    if (precioOfertaRaw is num && precioOfertaRaw > 0) {
      precioOferta = precioOfertaRaw.toDouble();
    } else if (precioOfertaRaw is String) {
      final parsed = double.tryParse(precioOfertaRaw);
      if (parsed != null && parsed > 0) precioOferta = parsed;
    }

    final bool tieneOferta = precioOferta != null && precioOferta < precio;
    final int descuentoPorcentaje = tieneOferta
        ? (((precio - precioOferta) / precio) * 100).round()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen con PROPORCIÓN FIJA — mismo tamaño en todas las cards
          AspectRatio(
            aspectRatio: 3 / 4,
            child: imagenPrincipal.isNotEmpty
                ? Image.network(
                    imagenPrincipal,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFFED1C24),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Symbols.image,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Icon(
                        Symbols.image_not_supported,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
          ),

          // Info: SIN padding horizontal — el texto empieza donde empieza la imagen
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        producto['titulo'] ?? 'Producto sin título',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (mostrarCorazon)
                      GestureDetector(
                        onTap: onCorazonTap,
                        child: Icon(
                          Symbols.favorite,
                          fill: esFavorito ? 1 : 0,
                          size: 24,
                          color: esFavorito
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Precio JUSTO debajo del nombre
                if (tieneOferta)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'S/ ${_formatearPrecio(precioOferta)}',
                              style: const TextStyle(
                                color: Color(0xFFED1C24),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (descuentoPorcentaje > 0)
                            // Badge con Center interno para centrar el texto
                            // perfectamente en vertical y horizontal
                            Container(
                              width: 28,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFED1C24),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Text(
                                  '-$descuentoPorcentaje%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'S/ ${_formatearPrecio(precio)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'S/ ${_formatearPrecio(precio)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
