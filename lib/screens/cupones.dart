// screens/cupones.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/models/cupon_model.dart';
import 'package:xiaoxa/services/cupon_service.dart';
import 'package:material_symbols_icons/symbols.dart';

class Cupones extends StatefulWidget {
  const Cupones({super.key});

  @override
  State<Cupones> createState() => _CuponesState();
}

class _CuponesState extends State<Cupones> {
  static const double _headerHeight = 62;
  static const double _hPad = 16;

  final CuponService _cuponService = CuponService();

  List<CuponModel> _cupones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCupones();
    });
  }

  Future<void> _cargarCupones() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final cupones = await _cuponService.cuponesDisponibles();
      if (mounted) {
        setState(() {
          _cupones = cupones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cupones = [];
          _isLoading = false;
        });
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
                            'Cupones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _cupones.isEmpty
                    ? _emptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 👇 Subtítulo: alineado a la izquierda con el
                          //    icono de la flecha (left: 16 = _hPad) y
                          //    pegado arriba para que quede a la misma
                          //    altura visual que el header.
                          const Padding(
                            padding: EdgeInsets.only(
                              left: _hPad,
                              top: 8,
                              bottom: 8,
                            ),
                            child: Text(
                              'Cupones disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _cargarCupones,
                              color: const Color(0xFFED1C24),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  _hPad,
                                  0,
                                  _hPad,
                                  16,
                                ),
                                itemCount: _cupones.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final cupon = _cupones[index];
                                  return _CuponCard(cupon: cupon);
                                },
                              ),
                            ),
                          ),
                        ],
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
          Icon(Symbols.local_offer, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tienes cupones disponibles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve pronto para ver nuevas ofertas',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET: Card de cupón
// ══════════════════════════════════════════════════════════
class _CuponCard extends StatelessWidget {
  final CuponModel cupon;

  const _CuponCard({required this.cupon});

  int _diasRestantes(String fechaVencimiento) {
    try {
      final partes = fechaVencimiento.split('-');
      if (partes.length == 3) {
        final fecha = DateTime(
          int.parse(partes[0]),
          int.parse(partes[1]),
          int.parse(partes[2]),
        );
        final hoy = DateTime.now();
        final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
        final diff = fecha.difference(hoySoloFecha);
        return diff.inDays < 0 ? 0 : diff.inDays;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final montoTexto = cupon.monto.toStringAsFixed(0);
    final montoMinimoTexto = cupon.montoMinimo.toStringAsFixed(0);
    final dias = _diasRestantes(cupon.fechaVencimiento);

    // 👇 Ancho compartido para el badge del precio y el código
    const double blockWidth = 150;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC168C), Color(0xFFB80E6B)],
        ),
        // 👇 Sin bordes redondeados (rectángulo puro)
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fila superior: texto centrado
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'POR COMPRAS MAYORES A S/$montoMinimoTexto',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'LLÉVATE DE REGALO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 👇 BADGE DEL PRECIO con diseño tipo ticket (muescas laterales
            //    y esquinas tipo mordisco circular)
            SizedBox(
              width: blockWidth,
              child: CustomPaint(
                painter: _TicketPainter(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            'S/',
                            style: TextStyle(
                              color: Color(0xFFEC168C),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            montoTexto,
                            style: const TextStyle(
                              color: Color(0xFFEC168C),
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'DE DESCUENTO',
                        style: TextStyle(
                          color: Color(0xFFEC168C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // "INGRESA EL CÓDIGO:" texto suelto
            const Text(
              'INGRESA EL CÓDIGO:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // 👇 Contenedor del código (mismo ancho que el badge del precio)
            SizedBox(
              width: blockWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(color: Colors.black),
                child: Padding(
                  // 👇 compensa los ~2px que letterSpacing deja al final
                  //    del texto, así los glifos quedan centrados de verdad.
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    cupon.codigo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 👇 Fila final: texto centrado + badge de fecha a la derecha.
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Text(
                    'EN TU CARRITO DE COMPRAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Positioned(
                    // 👇 right: -4 → el badge queda a 16px del borde
                    //    derecho del contenedor, igual que el padding
                    //    inferior del contenedor (16px).
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${dias}D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
}

// ══════════════════════════════════════════════════════════
// PAINTER: Badge blanco tipo ticket
// - Esquinas con muescas circulares (mordisco) en las 4 puntas
// - Muescas semicirculares adicionales en los costados (izq y der)
// ══════════════════════════════════════════════════════════
class _TicketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    const double cornerNotch = 14.0; // radio del mordisco en las esquinas
    const double notchR = 5.0; // radio de la muesca lateral
    const int numNotches = 3; // cantidad de muescas por lado

    final path = Path();

    // ── Borde superior ──
    path.moveTo(cornerNotch, 0);
    path.lineTo(w - cornerNotch, 0);

    // Muesca esquina superior derecha (cuarto de círculo hacia adentro)
    path.arcToPoint(
      Offset(w, cornerNotch),
      radius: const Radius.circular(cornerNotch),
      clockwise: false,
    );

    // ── Borde derecho con muescas semicirculares ──
    final double usableH = h - 2 * cornerNotch;
    final double segH = usableH / numNotches;

    for (int i = 0; i < numNotches; i++) {
      final double midY = cornerNotch + (i + 0.5) * segH;
      final double endY = cornerNotch + (i + 1) * segH;

      path.lineTo(w, midY - notchR);
      path.quadraticBezierTo(w - notchR * 2.2, midY, w, midY + notchR);
      path.lineTo(w, endY);
    }

    // Muesca esquina inferior derecha
    path.arcToPoint(
      Offset(w - cornerNotch, h),
      radius: const Radius.circular(cornerNotch),
      clockwise: false,
    );

    // ── Borde inferior ──
    path.lineTo(cornerNotch, h);

    // Muesca esquina inferior izquierda
    path.arcToPoint(
      Offset(0, h - cornerNotch),
      radius: const Radius.circular(cornerNotch),
      clockwise: false,
    );

    // ── Borde izquierdo con muescas (de abajo hacia arriba) ──
    for (int i = numNotches - 1; i >= 0; i--) {
      final double midY = cornerNotch + (i + 0.5) * segH;
      final double startY = cornerNotch + i * segH;

      path.lineTo(0, midY + notchR);
      path.quadraticBezierTo(notchR * 2.2, midY, 0, midY - notchR);
      path.lineTo(0, startY);
    }

    // Muesca esquina superior izquierda
    path.arcToPoint(
      Offset(cornerNotch, 0),
      radius: const Radius.circular(cornerNotch),
      clockwise: false,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
