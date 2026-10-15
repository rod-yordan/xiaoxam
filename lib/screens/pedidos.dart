// screens/pedidos.dart
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:xiaoxa/services/pedido_service.dart';

class MisPedidos extends StatefulWidget {
  const MisPedidos({super.key});

  @override
  State<MisPedidos> createState() => _MisPedidosState();
}

class _MisPedidosState extends State<MisPedidos> {
  final PedidoService _pedidoService = PedidoService();

  List<dynamic> _pedidos = [];
  bool _isLoading = true;
  String? _error;

  final Set<int> _expandidos = {};
  final Map<int, Map<String, dynamic>> _detallesCache = {};
  final Map<int, bool> _cargandoDetalle = {};
  final Map<int, String> _errorDetalle = {};
  final Map<int, bool> _descargando = {};

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pedidos = await _pedidoService.obtenerMisPedidos();
      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDetalle(int idPedido) async {
    if (_expandidos.contains(idPedido)) {
      setState(() => _expandidos.remove(idPedido));
      return;
    }

    setState(() {
      _expandidos.add(idPedido);
      _errorDetalle.remove(idPedido);
    });

    if (_detallesCache.containsKey(idPedido)) return;

    setState(() => _cargandoDetalle[idPedido] = true);

    try {
      final detalle = await _pedidoService.obtenerDetallePedido(idPedido);
      if (mounted) {
        setState(() {
          _detallesCache[idPedido] = detalle;
          _cargandoDetalle[idPedido] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorDetalle[idPedido] = e.toString();
          _cargandoDetalle[idPedido] = false;
        });
      }
    }
  }

  Future<void> _descargarGuia(int idPedido, String numeroPedido) async {
    setState(() => _descargando[idPedido] = true);

    try {
      final result = await _pedidoService.descargarGuia(idPedido);

      // Mapear extensión a MimeType
      MimeType mime;
      switch (result.extension.toLowerCase()) {
        case 'pdf':
          mime = MimeType.pdf;
          break;
        case 'jpg':
        case 'jpeg':
          mime = MimeType.jpeg;
          break;
        case 'png':
          mime = MimeType.png;
          break;
        default:
          mime = MimeType.other;
      }

      final path = await FileSaver.instance.saveFile(
        name: 'guia-pedido-$numeroPedido',
        bytes: Uint8List.fromList(result.bytes),
        fileExtension: result.extension, // ✅ nombre correcto en 0.4.0
        mimeType: mime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guía descargada en: $path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _descargando[idPedido] = false);
    }
  }

  /// Formato: dd/mm/yyyy hh:mm
  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'Fecha no disponible';
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year.toString();
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$anio $hora:$minuto';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Mis compras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _pedidos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pedidos.length,
              itemBuilder: (context, index) =>
                  _buildPedidoCard(_pedidos[index]),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.error, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar tus pedidos',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPedidos,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.shopping_bag, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tienes pedidos aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando realices tu primera compra,\naparecerá aquí',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ir a comprar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(dynamic pedido) {
    final idPedido = pedido['id_pedido'] as int? ?? 0;
    final numeroPedido = pedido['numero_pedido']?.toString() ?? 'N/A';
    final fecha = _formatearFecha(
      pedido['fecha_pedido'] ?? pedido['created_at'],
    );
    final expandido = _expandidos.contains(idPedido);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header
          InkWell(
            onTap: () => _toggleDetalle(idPedido),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido $numeroPedido',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fecha,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expandido
                        ? Symbols.keyboard_arrow_up
                        : Symbols.keyboard_arrow_down,
                    size: 22,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),

          // ── Detalle inline
          if (expandido) _buildDetalleExpandido(idPedido),
        ],
      ),
    );
  }

  Widget _buildDetalleExpandido(int idPedido) {
    if (_cargandoDetalle[idPedido] == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_errorDetalle[idPedido] != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _errorDetalle[idPedido]!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _errorDetalle.remove(idPedido);
                    _cargandoDetalle[idPedido] = false;
                  });
                  _toggleDetalle(idPedido);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final detalle = _detallesCache[idPedido];
    if (detalle == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 20),

          _buildSeguimiento(detalle),

          const SizedBox(height: 20),

          _buildTablaProductos(detalle),

          const SizedBox(height: 16),

          _buildDatosEntrega(detalle),

          if (detalle['tiene_archivo'] == true &&
              detalle['archivo_url'] != null) ...[
            const SizedBox(height: 16),
            _buildArchivoAdjunto(idPedido, detalle),
          ],
        ],
      ),
    );
  }

  Widget _buildSeguimiento(Map<String, dynamic> detalle) {
    final estado = detalle['estado_pedido']?.toString() ?? 'Pendiente';
    final idTipoEntrega = detalle['id_tipo_entrega'];

    final esRetiro = idTipoEntrega != 2;

    final pasos = esRetiro
        ? const [
            _Paso('Pendiente', Symbols.schedule),
            _Paso('Listo para recoger', Symbols.storefront),
            _Paso('Entregado', Symbols.verified),
          ]
        : const [
            _Paso('Pendiente', Symbols.schedule),
            _Paso('En camino', Symbols.local_shipping),
            _Paso('Listo para recoger', Symbols.storefront),
            _Paso('Entregado', Symbols.verified),
          ];

    final nombres = pasos.map((p) => p.nombre).toList();
    final indiceActual = nombres.indexOf(estado);
    final indice = indiceActual < 0 ? -1 : indiceActual;

    const indigo = Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < pasos.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Container(
                    height: 1.5,
                    color: i <= indice ? indigo : Colors.grey.shade300,
                  ),
                ),
              ),
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= indice ? indigo : Colors.grey.shade100,
                    ),
                    child: Icon(
                      pasos[i].icono,
                      size: 16,
                      color: i <= indice ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pasos[i].nombre == 'Listo para recoger'
                        ? 'Listo para\nrecoger'
                        : pasos[i].nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: i <= indice
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i <= indice ? indigo : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTablaProductos(Map<String, dynamic> detalle) {
    final detalles = (detalle['detalles'] as List<dynamic>?) ?? [];
    final total = _toDouble(detalle['total_pedido']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // HEADER
          Container(
            color: const Color(0xFFF1F1F1),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 45,
                  child: Text(
                    'Producto',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 18,
                  child: Text(
                    'Precio Unit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 17,
                  child: Text(
                    'Cantidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          // FILAS
          ...detalles.map((d) => _filaProducto(d as Map<String, dynamic>)),
          // TOTAL
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(flex: 45, child: SizedBox()),
                const Expanded(flex: 18, child: SizedBox()),
                const Expanded(
                  flex: 17,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'S/ ${total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaProducto(Map<String, dynamic> detalle) {
    final producto = detalle['producto'] as Map<String, dynamic>?;
    final nombre = producto?['nombre']?.toString() ?? 'Producto eliminado';
    final color = detalle['color']?.toString() ?? '—';
    final talla = detalle['talla']?.toString() ?? '—';
    final precio = _toDouble(detalle['precio_unitario']);
    final cantidad = detalle['cantidad'] ?? 1;
    final subtotal = _toDouble(detalle['subtotal']);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                ),
                const SizedBox(height: 3),
                Text(
                  'Color: $color   Talla: $talla',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'S/ ${precio.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
          Expanded(
            flex: 17,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'S/ ${subtotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosEntrega(Map<String, dynamic> detalle) {
    final esRetiro = detalle['id_tipo_entrega'] != 2;
    final direccion = detalle['direccion_entrega']?.toString();
    final tiempo = detalle['tiempo_entrega']?.toString();
    final destino = _ubicacionCompleta(detalle);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATOS DE ENTREGA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          _filaEntrega(
            'Tipo de entrega',
            detalle['tipo_entrega']?.toString() ?? '—',
          ),

          if (!esRetiro) _filaEntrega('Destino', destino ?? '—'),

          _filaEntrega(
            'Dirección',
            (direccion == null || direccion.isEmpty)
                ? 'En espera de asignación'
                : direccion,
            pendiente: direccion == null || direccion.isEmpty,
          ),

          _filaEntrega(
            'Tiempo de entrega',
            (tiempo == null || tiempo.isEmpty)
                ? 'En espera de asignación'
                : tiempo,
            pendiente: tiempo == null || tiempo.isEmpty,
          ),
        ],
      ),
    );
  }

  Widget _filaEntrega(String label, String valor, {bool pendiente = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontStyle: pendiente ? FontStyle.italic : FontStyle.normal,
                color: pendiente ? const Color(0xFFD97706) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivoAdjunto(int idPedido, Map<String, dynamic> detalle) {
    final numeroPedido = detalle['numero_pedido']?.toString() ?? '';
    final descargando = _descargando[idPedido] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Symbols.download,
              size: 20,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guía de envío',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Descarga este archivo para gestionar tu envío',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: descargando
                ? null
                : () => _descargarGuia(idPedido, numeroPedido),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: descargando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Descargar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  String? _ubicacionCompleta(Map<String, dynamic> detalle) {
    final partes = <String>[];
    if (detalle['departamento']?.toString().isNotEmpty == true) {
      partes.add(detalle['departamento'].toString());
    }
    if (detalle['provincia']?.toString().isNotEmpty == true) {
      partes.add(detalle['provincia'].toString());
    }
    if (detalle['distrito']?.toString().isNotEmpty == true) {
      partes.add(detalle['distrito'].toString());
    }
    return partes.isEmpty ? null : partes.join(', ');
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _Paso {
  final String nombre;
  final IconData icono;
  const _Paso(this.nombre, this.icono);
}
