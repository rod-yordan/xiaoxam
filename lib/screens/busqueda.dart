import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/screens/producto_card.dart';
import 'package:xiaoxa/services/producto_service.dart';
import 'package:xiaoxa/models/producto_model.dart';
import 'package:material_symbols_icons/symbols.dart';

class Busqueda extends StatefulWidget {
  const Busqueda({super.key});

  @override
  State<Busqueda> createState() => _BusquedaState();
}

class _BusquedaState extends State<Busqueda> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ProductoService _productoService = ProductoService();

  List<ProductoModel> _resultados = [];
  bool _cargando = false;
  bool _busquedaRealizada = false;
  String _ultimaBusqueda = '';

  static const double _headerHeight = 62;
  static const double _hPad = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _buscar(String query) async {
    final q = query.trim();

    if (q.isEmpty) {
      setState(() {
        _resultados = [];
        _busquedaRealizada = false;
        _ultimaBusqueda = '';
      });
      return;
    }

    if (q == _ultimaBusqueda && _resultados.isNotEmpty) {
      return;
    }

    setState(() {
      _cargando = true;
      _busquedaRealizada = true;
      _ultimaBusqueda = q;
    });

    try {
      final productos = await _productoService.buscarProductos(
        q,
        page: 0,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _resultados = productos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultados = [];
          _cargando = false;
        });
      }
    }
  }

  void _limpiar() {
    _controller.clear();
    setState(() {
      _resultados = [];
      _busquedaRealizada = false;
      _ultimaBusqueda = '';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= BARRA SUPERIOR CON BUSCADOR =================
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
                          // Botón atrás
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

                          // Campo de búsqueda
                          Expanded(
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icono lupa — Symbols (misma librería)
                                  const Icon(
                                    Symbols.search,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: _buscar,
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Buscar por nombre',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 15,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (_controller.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: _limpiar,
                                      child: const Icon(
                                        Symbols.close,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
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
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFED1C24)),
      );
    }

    if (!_busquedaRealizada) {
      return _estadoInicial();
    }

    if (_resultados.isEmpty) {
      return _sinResultados();
    }

    return _gridResultados();
  }

  Widget _estadoInicial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Busca tu producto favorito',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe el nombre del producto',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _sinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No encontramos productos para "$_ultimaBusqueda"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridResultados() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 170 / 322,
      ),
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final producto = _resultados[index];
        return ProductoCard(
          producto: {
            ...producto.toMap(),
            'imagenes': producto.imagenes,
            'imagen_principal': producto.imagenPrincipal,
          },
          onTap: () {
            context.push(
              '/detallesProducto',
              extra: {
                ...producto.toMap(),
                'imagenes': producto.imagenes,
                'imagen_principal': producto.imagenPrincipal,
              },
            );
          },
          mostrarCorazon: true,
        );
      },
    );
  }
}
