import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/screens/categoria_card.dart';
import 'package:xiaoxa/providers/categoria_provider.dart';
import 'package:xiaoxa/services/producto_service.dart';
import 'package:xiaoxa/utils/api_config.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';

class CatalogoParte1 extends StatefulWidget {
  const CatalogoParte1({super.key});

  @override
  State<CatalogoParte1> createState() => _CatalogoParte1State();
}

class _CatalogoParte1State extends State<CatalogoParte1> {
  final ProductoService _productoService = ProductoService();

  final Map<int, String> _imagenesCategorias = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoriaProvider = Provider.of<CategoriaProvider>(
        context,
        listen: false,
      );
      await categoriaProvider.cargarCategorias();
      await _cargarImagenesDeCategorias(categoriaProvider.categorias);
    });
  }

  Future<void> _cargarImagenesDeCategorias(
    List<Map<String, dynamic>> categorias,
  ) async {
    for (final categoria in categorias) {
      final idCategoria = categoria['id_categoria'];
      if (idCategoria == null) continue;

      try {
        final productos = await _productoService.getProductos(
          page: 0,
          limit: 1,
          categoriaId: idCategoria is int
              ? idCategoria
              : int.tryParse(idCategoria.toString()),
        );

        if (productos.isNotEmpty) {
          final imagenOriginal =
              productos.first.imagenPrincipal?.toString().trim() ?? '';

          final imagenUrl = imagenOriginal.replaceFirst(
            '${ApiConfig.baseUrl}/productos/',
            '${ApiConfig.apiUrl}/imagen/',
          );

          if (mounted) {
            setState(() {
              _imagenesCategorias[idCategoria is int
                      ? idCategoria
                      : int.parse(idCategoria.toString())] =
                  imagenUrl;
            });
          }
        }
      } catch (e) {
        // ignorar
      }
    }
  }

  String? _obtenerImagen(int? idCategoria) {
    if (idCategoria == null) return null;
    return _imagenesCategorias[idCategoria];
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
                    height: 62,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Flecha
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

                          // Título al lado de la flecha
                          const Text(
                            'Catálogo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Empuja el carrito a la derecha
                          const Spacer(),

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
              child: Container(
                color: const Color(0xFFF7F7F7),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<CategoriaProvider>(
                    builder: (context, categoriaProvider, child) {
                      if (categoriaProvider.isLoading) {
                        return _cargandoGrid();
                      }

                      if (categoriaProvider.categorias.isEmpty) {
                        return const Center(
                          child: Text('No hay categorías disponibles'),
                        );
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: categoriaProvider.categorias.length,
                        itemBuilder: (context, index) {
                          final categoria = categoriaProvider.categorias[index];
                          final nombreCategoria =
                              categoria['nombre_categoria'] ?? '';
                          final idCategoria = categoria['id_categoria'];

                          return CategoriaCard(
                            titulo: nombreCategoria,
                            imagenPath: _obtenerImagen(idCategoria),
                            onTap: () {
                              context.push(
                                '/catalogo-parte2',
                                extra: {
                                  'categoria': nombreCategoria,
                                  'categoriaId': idCategoria,
                                },
                              );
                            },
                          );
                        },
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

  Widget _cargandoGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
