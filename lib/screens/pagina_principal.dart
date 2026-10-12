import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaoxa/models/banner_model.dart';
import 'package:xiaoxa/models/navbar_item_model.dart';
import 'package:xiaoxa/models/producto_model.dart';
import 'package:xiaoxa/providers/banner_provider.dart';
import 'package:xiaoxa/screens/producto_card.dart';
import 'package:xiaoxa/services/producto_service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  List<BannerModel> banners = [];

  final ProductoService _productoService = ProductoService();

  List<NavbarItem> _navbarItems = [];
  bool _cargandoNavbar = true; // 👈 nuevo

  List<ProductoModel> _productos = [];
  bool _cargandoProductos = false;

  String _filtroActivo = 'todo';
  Map<String, dynamic> _filtroActual = {};

  static const double _hPad = 16;

  static const double _logoOffset = 0;

  static const double _gapHeaderCategorias = 0;

  static const double _headerHeight = 62;

  static const int _limiteNuevos = 8;

  static const double _categoriasHeight = 28;

  static const double _categoriasOffset = -6;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarNavbarItems();
      _cargarBanners();
      _cargarProductos();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _autoScroll();
      }
    });
  }

  Future<void> _cargarNavbarItems() async {
    if (mounted) setState(() => _cargandoNavbar = true);

    try {
      final items = await _productoService.getNavbarItems();
      if (mounted) {
        setState(() {
          _navbarItems = items
              .where((item) => item.tipo != 'categorias_dropdown')
              .toList();
          _cargandoNavbar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _navbarItems = [];
          _cargandoNavbar = false;
        });
      }
    }
  }

  Future<void> _cargarBanners() async {
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
    await bannerProvider.cargarBanners();
    if (mounted) {
      setState(() => banners = bannerProvider.banners);
    }
  }

  Future<void> _cargarProductos() async {
    if (mounted) setState(() => _cargandoProductos = true);

    try {
      final bool esNuevo = _filtroActual['nuevo'] == true;
      final int limite = esNuevo ? _limiteNuevos : 30;

      final productos = await _productoService.getProductos(
        limit: limite,
        categoria: _filtroActual['categoria'],
        soloConStock: true,
        orden: 'created_at',
        direccion: 'desc',
        promocion: _filtroActual['promocion'] == true ? true : null,
        nuevo: esNuevo ? true : null,
      );

      if (mounted) {
        setState(() {
          _productos = productos;
          _cargandoProductos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productos = [];
          _cargandoProductos = false;
        });
      }
    }
  }

  Future<void> _refrescarProductos() async {
    ProductoService.resetPaginacion();
    await Future.wait([_cargarNavbarItems(), _cargarProductos()]);
  }

  void _cambiarFiltro(String tipo, String valor) {
    Map<String, dynamic> nuevosFiltros = {};

    switch (tipo) {
      case 'nuevo':
        nuevosFiltros = {'nuevo': true};
        break;
      case 'categoria':
        nuevosFiltros = {'categoria': valor};
        break;
      case 'promocion':
        nuevosFiltros = {'promocion': true};
        break;
      default:
        nuevosFiltros = {};
    }

    setState(() {
      _filtroActivo = tipo == 'todo' ? 'todo' : valor;
      _filtroActual = nuevosFiltros;
    });

    _cargarProductos();
  }

  void _autoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      if (_pageController.hasClients && banners.isNotEmpty) {
        _paginaActual = (_paginaActual + 1) % banners.length;
        _pageController.animateToPage(
          _paginaActual,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Barra superior FIJA =====
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lupa
                          GestureDetector(
                            onTap: () => context.go('/busqueda'),
                            child: const Icon(
                              Symbols.search,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),

                          // Logo
                          Padding(
                            padding: const EdgeInsets.only(top: _logoOffset),
                            child: Image.asset(
                              'assets/logo.jpeg',
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                          ),

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

                  SizedBox(height: _gapHeaderCategorias),

                  Transform.translate(
                    offset: Offset(0, _categoriasOffset),
                    child: _cargandoNavbar
                        ? _categoriasSkeleton()
                        : _navbarFiltros(),
                  ),

                  Container(height: 1, color: Colors.black12),
                ],
              ),
            ),

            // ===== Contenido scrolleable =====
            Expanded(
              child: Container(
                color: Colors.white,
                child: RefreshIndicator(
                  onRefresh: _refrescarProductos,
                  color: const Color(0xFFED1C24),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.zero,
                    children: [
                      _bannerCarrusel(),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _hPad),
                        child: _gridProductos(),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 Skeleton de categorías: píldoras grises simulando los filtros
  Widget _categoriasSkeleton() {
    return SizedBox(
      height: _categoriasHeight,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(4, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 16),
                child: Container(
                  width: index.isEven ? 55 : 70, // anchos variados
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200, // 👈 más claro
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _navbarFiltros() {
    final List<Map<String, dynamic>> listaFinal = [
      {'tipo': 'todo', 'nombre': 'Todo', 'valor': 'todo'},
      ..._navbarItems.map(
        (i) => {'tipo': i.tipo, 'nombre': i.nombre, 'valor': i.valor},
      ),
    ];

    return SizedBox(
      height: _categoriasHeight,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(listaFinal.length, (index) {
              final item = listaFinal[index];
              final String tipo = item['tipo'];
              final String nombre = item['nombre'];
              final String valor = item['valor'];

              final bool seleccionado =
                  _filtroActivo == (tipo == 'todo' ? 'todo' : valor);

              return Padding(
                padding: EdgeInsets.only(
                  right: index == listaFinal.length - 1 ? 0 : 16,
                ),
                child: GestureDetector(
                  onTap: () => _cambiarFiltro(tipo, valor),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: seleccionado
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        width: seleccionado ? null : 0,
                        constraints: seleccionado
                            ? const BoxConstraints(minWidth: 20)
                            : null,
                        color: seleccionado ? Colors.black : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _bannerCarrusel() {
    if (banners.isEmpty) {
      return _bannerSkeleton();
    }

    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (_, i) {
              return CachedNetworkImage(
                imageUrl: banners[i].imagen,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200), // 👈 más claro
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          if (banners.length >= 2)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _paginaActual == index ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _paginaActual == index
                          ? Colors.white
                          : Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // 👇 Skeleton del banner: más claro (antes shade300, ahora shade200)
  Widget _bannerSkeleton() {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Container(color: Colors.grey.shade200),
    );
  }

  Widget _gridProductos() {
    if (_cargandoProductos) {
      return _gridSkeleton();
    }

    if (_productos.isEmpty) {
      return _buildSeccionVacia();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 170 / 322,
      ),
      itemCount: _productos.length,
      itemBuilder: (_, i) => _productoCard(_productos[i]),
    );
  }

  Widget _gridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 170 / 322,
      ),
      itemCount: 4,
      itemBuilder: (_, i) => _buildProductoSkeleton(),
    );
  }

  Widget _buildProductoSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Container(color: Colors.grey.shade200)),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: double.infinity,
          color: Colors.grey.shade200,
        ),
        const SizedBox(height: 4),
        Container(height: 12, width: 60, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildSeccionVacia() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          'No hay productos disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _productoCard(ProductoModel p) {
    return ProductoCard(
      producto: {
        ...p.toMap(),
        'imagenes': p.imagenes,
        'imagen_principal': p.imagenPrincipal,
      },
      onTap: () {
        context.push(
          '/detallesProducto',
          extra: {
            ...p.toMap(),
            'imagenes': p.imagenes,
            'imagen_principal': p.imagenPrincipal,
          },
        );
      },
      mostrarCorazon: true,
    );
  }
}
