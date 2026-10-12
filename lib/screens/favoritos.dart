import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaoxa/screens/producto_card.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/favoritos_provider.dart';
import 'package:xiaoxa/providers/auth_provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class Favoritos extends StatefulWidget {
  const Favoritos({super.key});

  @override
  State<Favoritos> createState() => _FavoritosState();
}

class _FavoritosState extends State<Favoritos> {
  static const double _headerHeight = 62;
  static const double _hPad = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final favoritosProvider = Provider.of<FavoritosProvider>(
        context,
        listen: false,
      );
      favoritosProvider.cargarFavoritos(authProvider);
    });
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
                          // Flecha de retroceso
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
                            'Favoritos',
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
              child: Consumer2<FavoritosProvider, AuthProvider>(
                builder: (context, favoritosProvider, authProvider, child) {
                  final productosFavoritos =
                      favoritosProvider.productosFavoritos;

                  if (productosFavoritos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.favorite,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes favoritos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega productos a tus favoritos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    color: Colors.white,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _hPad,
                        vertical: 16,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 170 / 322,
                          ),
                      itemCount: productosFavoritos.length,
                      itemBuilder: (context, index) {
                        final producto = productosFavoritos[index];
                        return ProductoCard(
                          producto: producto,
                          onTap: () {
                            context.push('/detallesProducto', extra: producto);
                          },
                          mostrarCorazon: true,
                          esFavorito: true,
                          onCorazonTap: () async {
                            await favoritosProvider.eliminarFavorito(
                              producto,
                              authProvider,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Eliminado de favoritos'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                        );
                      },
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
}
