// screens/detalles_producto.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaoxa/providers/auth_provider.dart';
import 'package:xiaoxa/providers/favoritos_provider.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/models/producto_model.dart';
import 'package:xiaoxa/models/variante_model.dart';
import 'package:material_symbols_icons/symbols.dart';

class DetallesProducto extends StatefulWidget {
  final Map<String, dynamic> producto;

  const DetallesProducto({super.key, required this.producto});

  @override
  State<DetallesProducto> createState() => _DetallesProductoState();
}

class _DetallesProductoState extends State<DetallesProducto> {
  late ProductoModel _producto;
  VarianteModel? _varianteSeleccionada;

  String? _colorSeleccionado;
  String? _tallaSeleccionada;
  int _paginaActual = 0;
  final PageController _pageController = PageController();

  bool _showScrollIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _producto = ProductoModel.fromJson(widget.producto);

    if (_producto.variantes.isNotEmpty) {
      final primeraConStock = _producto.variantes.firstWhere(
        (v) => v.stock > 0,
        orElse: () => _producto.variantes.first,
      );

      _colorSeleccionado = primeraConStock.color;
      _tallaSeleccionada = primeraConStock.talla;
      _varianteSeleccionada = primeraConStock;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorTimer?.cancel();
    super.dispose();
  }

  List<String> get _imagenesActuales {
    if (_varianteSeleccionada != null &&
        _varianteSeleccionada!.imagenes.isNotEmpty) {
      return _varianteSeleccionada!.imagenes;
    }

    if (_colorSeleccionado != null) {
      final porColor = _producto.getImagenesPorColor(_colorSeleccionado!);
      if (porColor.isNotEmpty) return porColor;
    }

    if (_producto.imagenPrincipal.isNotEmpty) {
      return [_producto.imagenPrincipal];
    }
    return _producto.imagenes;
  }

  List<String> get _imagenesTodas {
    final todas = <String>[];
    final vistas = <String>{};

    for (final variante in _producto.variantes) {
      for (final img in variante.imagenes) {
        if (!vistas.contains(img)) {
          vistas.add(img);
          todas.add(img);
        }
      }
    }

    if (todas.isEmpty && _producto.imagenPrincipal.isNotEmpty) {
      todas.add(_producto.imagenPrincipal);
    }

    return todas;
  }

  void _onScrollActivity() {
    if (mounted) setState(() => _showScrollIndicator = true);
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showScrollIndicator = false);
    });
  }

  void _irAPrimeraImagenDeColor(String color) {
    final imagenesColor = _producto.getImagenesPorColor(color);
    if (imagenesColor.isEmpty) return;

    final primera = imagenesColor.first;
    final index = _imagenesTodas.indexOf(primera);

    if (index >= 0 && _pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  String _formatearPrecio(dynamic precio) {
    if (precio == null) return '';
    double valor = precio is int
        ? precio.toDouble()
        : (precio is double ? precio : double.tryParse(precio.toString()) ?? 0);
    return valor.toStringAsFixed(2);
  }

  void _seleccionarColor(String color) {
    setState(() {
      _colorSeleccionado = color;

      String? tallaEncontrada;
      VarianteModel? varianteEncontrada;

      for (final talla in _producto.tallas) {
        final v = _varianteDe(color, talla);
        if (v != null && v.stock > 0) {
          tallaEncontrada = talla;
          varianteEncontrada = v;
          break;
        }
      }

      if (varianteEncontrada == null) {
        for (final talla in _producto.tallas) {
          final v = _varianteDe(color, talla);
          if (v != null) {
            tallaEncontrada = talla;
            varianteEncontrada = v;
            break;
          }
        }
      }

      _tallaSeleccionada = tallaEncontrada;
      _varianteSeleccionada = varianteEncontrada;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _irAPrimeraImagenDeColor(color);
    });
  }

  void _seleccionarTalla(VarianteModel variante) {
    if (variante.stock <= 0) return;
    setState(() {
      _tallaSeleccionada = variante.talla;
      _varianteSeleccionada = variante;
    });
  }

  VarianteModel? _varianteDe(String color, String talla) {
    try {
      return _producto.variantes.firstWhere(
        (v) =>
            v.color?.toLowerCase() == color.toLowerCase() && v.talla == talla,
      );
    } catch (_) {
      return null;
    }
  }

  void _mostrarMensajeConfirmacion(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: Colors.green,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Agregado al carrito',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  void _verificarUsuarioYAgregarCarrito(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para agregar al carrito'),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/cuenta/iniciarSesion');
      return;
    }

    _agregarAlCarrito(context);
  }

  Future<void> _agregarAlCarrito(BuildContext context) async {
    final carritoProvider = Provider.of<CarritoProvider>(
      context,
      listen: false,
    );

    final productoCarrito = {
      'id': _producto.id,
      'id_variante': _varianteSeleccionada?.id,
      'titulo': _producto.titulo,
      'precio': _producto.precio,
      'precio_oferta': _producto.precioOferta,
      'descuento': _producto.descuento,
      'imagenes': _imagenesActuales,
      'imagen_principal': _imagenesActuales.isNotEmpty
          ? _imagenesActuales.first
          : '',
      'talla': _tallaSeleccionada,
      'color': _colorSeleccionado,
      'cantidad': 1,
    };

    await carritoProvider.agregarProducto(context, productoCarrito);

    if (carritoProvider.error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${carritoProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      _mostrarMensajeConfirmacion(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int descuentoPorcentaje = _producto.descuento ?? 0;
    bool tieneOferta = _producto.precioOferta != null;
    final imagenes = _imagenesTodas;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ============ BARRA SUPERIOR ============
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    height: 62,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Icon(
                              Symbols.arrow_back,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _producto.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Consumer<CarritoProvider>(
                            builder: (context, carritoProvider, child) {
                              final cantidadTotal =
                                  carritoProvider.cantidadTotal;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () => context.push('/carrito'),
                                    child: const Icon(
                                      Symbols.local_mall,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (cantidadTotal > 0)
                                    Positioned(
                                      right: -3,
                                      top: -3,
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFED1C24),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            cantidadTotal > 9
                                                ? '9+'
                                                : cantidadTotal.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: Colors.black12),
                ],
              ),
            ),

            // ============ CONTENIDO ============
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ---- Galería ----
                    SizedBox(
                      height: 500,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollStartNotification ||
                                  notification is ScrollUpdateNotification) {
                                _onScrollActivity();
                              }
                              return false;
                            },
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imagenes.length,
                              onPageChanged: (index) =>
                                  setState(() => _paginaActual = index),
                              itemBuilder: (context, index) {
                                return Container(
                                  color: Colors.white,
                                  child: Image.network(
                                    imagenes[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Symbols.image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          if (imagenes.length > 1)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: _showScrollIndicator ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  height: 5,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final segmentWidth =
                                          constraints.maxWidth /
                                          imagenes.length;

                                      return Stack(
                                        children: [
                                          AnimatedPositioned(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeOut,
                                            left: segmentWidth * _paginaActual,
                                            top: 0,
                                            child: Container(
                                              width: segmentWidth,
                                              height: 5,
                                              color: Colors.grey.shade700
                                                  .withAlpha(140),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ---- Info del producto ----
                    Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_producto.marca != null &&
                                _producto.marca!.isNotEmpty)
                              Text(
                                _producto.marca!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _producto.titulo,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                if (tieneOferta) ...[
                                  Text(
                                    'S/ ${_formatearPrecio(_producto.precioOferta)}',
                                    style: const TextStyle(
                                      color: Color(0xFFED1C24),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Stack(
                                    children: [
                                      Text(
                                        'S/ ${_formatearPrecio(_producto.precio)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            height: 1,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else
                                  Text(
                                    'S/ ${_formatearPrecio(_producto.precio)}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                if (descuentoPorcentaje > 0) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFED1C24),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-$descuentoPorcentaje%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_producto.colores.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Text(
                                    'Color:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_colorSeleccionado != null)
                                    Text(
                                      _colorSeleccionado!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: _producto.getColoresConHex().map((c) {
                                  final nombre = c['nombre']!;
                                  final hex = c['hex']!;
                                  final seleccionado =
                                      nombre == _colorSeleccionado;
                                  final claro = _esColorClaro(hex);

                                  return GestureDetector(
                                    onTap: () => _seleccionarColor(nombre),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(hex),
                                        shape: BoxShape.circle,
                                        border: (claro && !seleccionado)
                                            ? Border.all(
                                                color: Colors.black12,
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: seleccionado
                                          ? Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: claro
                                                        ? Colors.grey.shade400
                                                        : Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],

                            if (_producto.tallas.isNotEmpty) ...[
                              const Text(
                                'Talla:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: _producto.tallas.map((talla) {
                                  final variante = _varianteDe(
                                    _colorSeleccionado ?? '',
                                    talla,
                                  );
                                  final disponible =
                                      variante != null && variante.stock > 0;
                                  final seleccionada =
                                      talla == _tallaSeleccionada;

                                  return GestureDetector(
                                    onTap: disponible
                                        ? () => _seleccionarTalla(variante)
                                        : null,
                                    child: Container(
                                      width: 48,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: seleccionada
                                            ? Colors.black
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: seleccionada
                                              ? Colors.black
                                              : Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        talla,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: seleccionada
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============ BOTONES INFERIORES ============
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  // ===== Añadir a favoritos =====
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Consumer<FavoritosProvider>(
                        builder: (context, favoritosProvider, child) {
                          final esFavorito = favoritosProvider.esFavorito(
                            widget.producto,
                          );

                          return OutlinedButton(
                            onPressed: () async {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );

                              final seAgrego = await favoritosProvider
                                  .toggleFavorito(
                                    widget.producto,
                                    authProvider,
                                  );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    seAgrego
                                        ? 'Agregado a favoritos'
                                        : 'Eliminado de favoritos',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              esFavorito
                                  ? 'En favoritos'
                                  : 'Añadir a favoritos',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ===== Añadir a la bolsa =====
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed:
                            _varianteSeleccionada != null &&
                                _varianteSeleccionada!.stock > 0
                            ? () => _verificarUsuarioYAgregarCarrito(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_varianteSeleccionada != null &&
                                  _varianteSeleccionada!.stock > 0)
                              ? const Color(0xFFED1C24)
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          (_varianteSeleccionada != null &&
                                  _varianteSeleccionada!.stock > 0)
                              ? 'Añadir a la bolsa'
                              : 'Sin stock',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  bool _esColorClaro(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length != 6) return false;
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return (0.299 * r + 0.587 * g + 0.114 * b) > 230;
  }
}
