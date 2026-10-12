import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/screens/producto_card.dart';
import 'package:xiaoxa/services/producto_service.dart';
import 'package:xiaoxa/models/producto_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';

class CatalogoParte2 extends StatefulWidget {
  final String categoria;
  final int? categoriaId;

  const CatalogoParte2({
    super.key,
    required this.categoria,
    required this.categoriaId,
  });

  @override
  State<CatalogoParte2> createState() => _CatalogoParte2State();
}

class _CatalogoParte2State extends State<CatalogoParte2> {
  final ProductoService _productoService = ProductoService();
  List<ProductoModel> _productos = [];
  bool _isLoading = true;

  static const double _headerHeight = 62;
  static const double _hPad = 16;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);

    try {
      final productos = await _productoService.getProductos(
        page: 0,
        limit: 50,
        categoriaId: widget.categoriaId,
      );

      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _productos = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refrescar() async {
    await _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= BARRA SUPERIOR =================
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
                          // Flecha
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/catalogo');
                              }
                            },
                            child: const Icon(
                              Symbols.arrow_back,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Título al lado de la flecha (con ellipsis)
                          Expanded(
                            child: Text(
                              widget.categoria,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Carrito
                          Consumer<CarritoProvider>(
                            builder: (context, carritoProvider, child) {
                              final cantidadTotal =
                                  carritoProvider.cantidadTotal;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () => context.go('/carrito'),
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

            // ================= CONTENIDO =================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refrescar,
                color: const Color(0xFFED1C24),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED1C24),
                        ),
                      )
                    : _productos.isEmpty
                    ? _emptyState()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _hPad),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 170 / 322,
                              ),
                          itemCount: _productos.length,
                          itemBuilder: (context, index) {
                            final producto = _productos[index];
                            return ProductoCard(
                              producto: producto.toMap(),
                              onTap: () {
                                context.push(
                                  '/detallesProducto',
                                  extra: producto.toMap(),
                                );
                              },
                              mostrarCorazon: true,
                            );
                          },
                        ),
                      ),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en esta categoría',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Pronto tendremos más productos para ti',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
