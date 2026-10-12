import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/services/cupon_service.dart';
import 'package:xiaoxa/services/producto_service.dart';
import 'package:material_symbols_icons/symbols.dart';

class Carrito extends StatefulWidget {
  const Carrito({super.key});

  @override
  State<Carrito> createState() => _CarritoState();
}

class _CarritoState extends State<Carrito> {
  static const double _headerHeight = 62;
  static const double _hPad = 16;
  static const double _cuponHeight = 38;

  final CuponService _cuponService = CuponService();
  final ProductoService _productoService = ProductoService();
  final TextEditingController _cuponController = TextEditingController();

  String? _codigoCuponAplicado;
  double _descuentoAplicado = 0;
  bool _cargandoCupon = false;

  @override
  void dispose() {
    _cuponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    height: _headerHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                            child: const Icon(
                              Symbols.arrow_back,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Carrito',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: Colors.black12),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: Consumer<CarritoProvider>(
                builder: (context, carritoProvider, child) {
                  final productos = carritoProvider.productos;

                  if (productos.isEmpty) {
                    return _emptyState();
                  }

                  return Container(
                    color: const Color(0xFFF7F7F7),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: productos.length,
                            itemBuilder: (context, index) {
                              final producto = productos[index];
                              return _ItemCarrito(
                                producto: producto,
                                index: index,
                                onTap: () =>
                                    _irADetalleProducto(context, producto),
                              );
                            },
                          ),
                        ),

                        _buildTotalSection(context, carritoProvider),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.local_mall, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tu bolsa está vacía',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos para continuar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _irADetalleProducto(
    BuildContext context,
    Map<String, dynamic> producto,
  ) async {
    final idProducto = producto['id_producto'];
    if (idProducto == null) return;

    try {
      final productoCompleto = await _productoService.getProductoById(
        idProducto is int ? idProducto : int.parse(idProducto.toString()),
      );

      if (context.mounted) {
        context.push('/detallesProducto', extra: productoCompleto.toMap());
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el producto: $e'),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  Widget _buildTotalSection(
    BuildContext context,
    CarritoProvider carritoProvider,
  ) {
    final subtotal = carritoProvider.total;
    final total = (subtotal - _descuentoAplicado).clamp(0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          if (_codigoCuponAplicado != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Symbols.local_offer,
                      size: 16,
                      color: Color(0xFFFF0000),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cupón: $_codigoCuponAplicado',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _quitarCupon,
                      child: const Icon(
                        Symbols.delete,
                        size: 14,
                        color: Color(0xFFFF0000),
                      ),
                    ),
                  ],
                ),
                Text(
                  '-S/ ${_descuentoAplicado.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF0000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Input + Botón con altura 38px
            SizedBox(
              height: _cuponHeight,
              child: Row(
                children: [
                  // Input (Container con borde + TextField con InputBorder.none)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _cuponController,
                          textCapitalization: TextCapitalization.characters,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: 'Código de descuento',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón Aplicar
                  Container(
                    height: _cuponHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _cargandoCupon ? null : _aplicarCuponManual,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: _cargandoCupon
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Aplicar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  '/informacionCompra',
                  extra: {
                    'codigo_cupon': _codigoCuponAplicado,
                    'descuento': _descuentoAplicado,
                    'subtotal': subtotal,
                    'total': total,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Continuar con la compra',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _aplicarCuponManual() async {
    final codigo = _cuponController.text.trim().toUpperCase();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un código de cupón'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() => _cargandoCupon = true);

    try {
      final resultado = await _cuponService.aplicarCupon(codigo);

      if (mounted) {
        setState(() {
          _codigoCuponAplicado = codigo;
          _descuentoAplicado = (resultado['descuento'] as num).toDouble();
          _cargandoCupon = false;
          _cuponController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cupón $codigo aplicado'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoCupon = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.black),
        );
      }
    }
  }

  Future<void> _quitarCupon() async {
    try {
      await _cuponService.quitarCupon();
    } catch (_) {
      // Si falla igual lo quitamos localmente
    }

    if (mounted) {
      setState(() {
        _codigoCuponAplicado = null;
        _descuentoAplicado = 0;
      });
    }
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET: Item del carrito — StatefulWidget para bloquear botones
// ══════════════════════════════════════════════════════════
class _ItemCarrito extends StatefulWidget {
  final Map<String, dynamic> producto;
  final int index;
  final VoidCallback onTap;

  const _ItemCarrito({
    required this.producto,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ItemCarrito> createState() => _ItemCarritoState();
}

class _ItemCarritoState extends State<_ItemCarrito> {
  // Bloquea los botones mientras se procesa el cambio de cantidad
  bool _procesandoCantidad = false;

  Future<void> _cambiarCantidad(
    BuildContext context,
    CarritoProvider carritoProvider,
    int delta,
  ) async {
    if (_procesandoCantidad) return;

    final int cantidad = (widget.producto['cantidad'] as num?)?.toInt() ?? 1;

    setState(() => _procesandoCantidad = true);

    try {
      if (delta < 0 && cantidad <= 1) {
        // Eliminar el producto
        await carritoProvider.eliminarProducto(context, widget.index);
      } else if (delta > 0) {
        await carritoProvider.incrementarCantidad(context, widget.index);
      } else {
        await carritoProvider.decrementarCantidad(context, widget.index);
      }
    } finally {
      if (mounted) setState(() => _procesandoCantidad = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carritoProvider = Provider.of<CarritoProvider>(context);

    final producto = widget.producto;

    final String imagenPrincipal = producto['imagen_principal'] ?? '';
    final String titulo = producto['titulo'] ?? '';
    final int cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
    final String talla = producto['talla'] ?? '';
    final String color = producto['color'] ?? '';

    final double precioBase = (producto['precio'] as num?)?.toDouble() ?? 0.0;
    final double? precioOfertaRaw = (producto['precio_oferta'] as num?)
        ?.toDouble();

    final bool tieneOferta =
        precioOfertaRaw != null &&
        precioOfertaRaw > 0 &&
        precioOfertaRaw < precioBase;

    final double precioFinal = tieneOferta ? precioOfertaRaw : precioBase;

    final int descuento = tieneOferta && precioBase > 0
        ? (((precioBase - precioOfertaRaw) / precioBase) * 100).round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 130,
              child: imagenPrincipal.isNotEmpty
                  ? Image.network(
                      imagenPrincipal,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 130,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Symbols.image,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Symbols.image,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    titulo,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (descuento > 0) ...[
                        Container(
                          width: 28,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED1C24),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              '-$descuento%',
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
                        const SizedBox(width: 6),
                      ],
                      if (tieneOferta) ...[
                        Text(
                          'S/ ${precioBase.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'S/ ${precioFinal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: tieneOferta
                              ? const Color(0xFFFF0000)
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Color: $color',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Talla: $talla',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Selector de cantidad — se bloquea mientras procesa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedOpacity(
                        opacity: _procesandoCantidad ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring: _procesandoCantidad,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: InkWell(
                                    onTap: () => _cambiarCantidad(
                                      context,
                                      carritoProvider,
                                      -1,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Symbols.remove,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 22,
                                  child: Center(
                                    child: Text(
                                      cantidad.toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: InkWell(
                                    onTap: () => _cambiarCantidad(
                                      context,
                                      carritoProvider,
                                      1,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Symbols.add,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
