import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xiaoxa/providers/auth_provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/models/tipo_documento_model.dart';
import 'package:xiaoxa/services/tipo_documento_service.dart';
import 'package:xiaoxa/services/checkout_service.dart';
import 'package:material_symbols_icons/symbols.dart';

class InformacionCompra extends StatefulWidget {
  const InformacionCompra({super.key});

  @override
  State<InformacionCompra> createState() => _InformacionCompraState();
}

class _InformacionCompraState extends State<InformacionCompra>
    with WidgetsBindingObserver {
  static const double _headerHeight = 62;

  final TextEditingController _numeroDocumentoController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  final TextEditingController _distritoController = TextEditingController();

  final TipoDocumentoService _tipoDocumentoService = TipoDocumentoService();
  final CheckoutService _checkoutService = CheckoutService();

  List<TipoDocumentoModel> _tiposDocumento = [];
  TipoDocumentoModel? _tipoDocumentoSeleccionado;

  int _tipoEntrega = 1;
  bool _isLoading = true;

  int? _idCupon;
  String? _codigoCupon;
  double _descuento = 0;

  // Estado del pago
  bool _esperandoPago = false;
  String? _referenciaActual;
  Timer? _pollingTimer;
  int _intentos = 0;
  static const int _maxIntentos = 60;

  // Al volver a la app
  bool _volviendoAApp = false;
  int _intentosAlVolver = 0;
  static const int _maxIntentosAlVolver = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leerCuponDeExtra();
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _numeroDocumentoController.dispose();
    _telefonoController.dispose();
    _departamentoController.dispose();
    _provinciaController.dispose();
    _distritoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _esperandoPago &&
        _referenciaActual != null) {
      setState(() {
        _volviendoAApp = true;
        _intentosAlVolver = 0;
      });
      _verificarEstadoPago();
    }
  }

  void _leerCuponDeExtra() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _idCupon = extra['id_cupon'] as int?;
      _codigoCupon = extra['codigo_cupon'] as String?;
      _descuento = (extra['descuento'] as num?)?.toDouble() ?? 0;
      setState(() {});
    }
  }

  bool get _isFormValid {
    if (_tipoDocumentoSeleccionado == null) return false;
    if (_numeroDocumentoController.text.trim().isEmpty) return false;
    if (_telefonoController.text.trim().isEmpty) return false;

    if (_tipoEntrega == 2) {
      if (_departamentoController.text.trim().isEmpty) return false;
      if (_provinciaController.text.trim().isEmpty) return false;
      if (_distritoController.text.trim().isEmpty) return false;
    }

    return true;
  }

  Future<void> _cargarDatosIniciales() async {
    await _cargarTiposDocumento();
    _cargarDatosUsuario();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _cargarDatosUsuario() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _numeroDocumentoController.text = auth.numeroDocumento ?? '';
    _telefonoController.text = auth.telefono ?? '';

    if (auth.idTipoDocumento != null && _tiposDocumento.isNotEmpty) {
      try {
        _tipoDocumentoSeleccionado = _tiposDocumento.firstWhere(
          (t) => t.id == auth.idTipoDocumento,
        );
      } catch (_) {
        _tipoDocumentoSeleccionado = null;
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _cargarTiposDocumento() async {
    try {
      final tipos = await _tipoDocumentoService.obtenerTiposDocumento();
      if (mounted) {
        setState(() => _tiposDocumento = tipos);
      }
    } catch (e) {
      debugPrint('Error al cargar tipos de documento: $e');
      if (mounted) {
        setState(() => _tiposDocumento = []);
      }
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.black));
  }

  Future<void> _continuarConPago() async {
    if (!_isFormValid) return;
    if (_esperandoPago) return;

    _intentos = 0;
    _volviendoAApp = false;
    _intentosAlVolver = 0;

    setState(() => _esperandoPago = true);

    try {
      final resultado = await _checkoutService.crearPreferencia(
        idTipoDocumento: _tipoDocumentoSeleccionado!.id,
        numeroDocumento: _numeroDocumentoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        idTipoEntrega: _tipoEntrega,
        departamento: _tipoEntrega == 2
            ? _departamentoController.text.trim()
            : null,
        provincia: _tipoEntrega == 2 ? _provinciaController.text.trim() : null,
        distrito: _tipoEntrega == 2 ? _distritoController.text.trim() : null,
        codigoCupon: _codigoCupon,
      );

      _referenciaActual = resultado['referencia'] as String;
      final initPoint = resultado['init_point'] as String;

      final uri = Uri.parse(initPoint);
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) {
        throw Exception('No se pudo abrir MercadoPago');
      }

      _iniciarPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _esperandoPago = false);
      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _iniciarPolling() {
    _intentos = 0;
    _volviendoAApp = false;
    _intentosAlVolver = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _verificarEstadoPago();
    });
  }

  Future<void> _verificarEstadoPago() async {
    if (_referenciaActual == null) return;

    if (!_volviendoAApp && _intentos >= _maxIntentos) {
      _detenerPolling();
      if (!mounted) return;
      setState(() {
        _esperandoPago = false;
        _referenciaActual = null;
      });
      _mostrarMensaje('El pago tardó demasiado. Intenta nuevamente.');
      return;
    }

    if (!_volviendoAApp) _intentos++;

    try {
      final estado = await _checkoutService.consultarEstado(_referenciaActual!);
      if (!mounted) return;

      final estadoStr = estado['estado'] as String?;

      // ✅ Pago completado
      if (estadoStr == 'completado') {
        _detenerPolling();

        await Provider.of<CarritoProvider>(
          context,
          listen: false,
        ).cargarCarrito(context);

        if (!mounted) return;
        setState(() {
          _esperandoPago = false;
          _volviendoAApp = false;
          _intentosAlVolver = 0;
          _referenciaActual = null;
        });

        context.go(
          '/compraExitosa',
          extra: {
            'numeroPedido': estado['numero_pedido'],
            'totalPedido': estado['total_pedido'],
            'estadoPedido': estado['estado_pedido'],
          },
        );
        return;
      }

      // ❌ Checkout expiró
      if (estadoStr == 'no_encontrado') {
        _detenerPolling();
        if (!mounted) return;
        setState(() {
          _esperandoPago = false;
          _volviendoAApp = false;
          _intentosAlVolver = 0;
          _referenciaActual = null;
        });
        _mostrarMensaje('El pago expiró. Intenta nuevamente.');
        return;
      }

      // ⏳ Pendiente al volver
      if (estadoStr == 'pendiente' && _volviendoAApp) {
        _intentosAlVolver++;

        if (_intentosAlVolver >= _maxIntentosAlVolver) {
          _detenerPolling();
          if (!mounted) return;
          setState(() {
            _esperandoPago = false;
            _volviendoAApp = false;
            _intentosAlVolver = 0;
            _referenciaActual = null;
          });
          _mostrarMensaje(
            'Operación cancelada. Puedes intentar el pago nuevamente.',
          );
          return;
        }
      }
    } catch (_) {
      // Ignorar errores de red en polling
    }
  }

  void _detenerPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _cancelarEspera() {
    _detenerPolling();
    setState(() {
      _esperandoPago = false;
      _volviendoAApp = false;
      _intentosAlVolver = 0;
      _referenciaActual = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Barra superior
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _headerHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/'),
                                child: const Icon(
                                  Symbols.arrow_back,
                                  size: 24,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Información de compra',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Datos personales',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildDropdown(
                                  'Tipo de documento',
                                  _tiposDocumento,
                                  _tipoDocumentoSeleccionado,
                                  (v) => setState(
                                    () => _tipoDocumentoSeleccionado = v,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  'Número de documento',
                                  'Ingresa tu número de documento',
                                  _numeroDocumentoController,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  'Teléfono',
                                  'Ingresa tu teléfono',
                                  _telefonoController,
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Datos de entrega',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildRadioOption('Retiro en tienda', 1),
                                const SizedBox(height: 4),
                                _buildRadioOption('Envío a provincia', 2),
                                const SizedBox(height: 20),

                                if (_tipoEntrega == 2) ...[
                                  _buildTextField(
                                    'Departamento',
                                    'Ingresa el departamento',
                                    _departamentoController,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    'Provincia',
                                    'Ingresa la provincia',
                                    _provinciaController,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    'Distrito',
                                    'Ingresa el distrito',
                                    _distritoController,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Symbols.info,
                                          size: 20,
                                          color: Colors.grey.shade700,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Cuando su pedido haya sido revisado, podrá ver la fecha y dirección de entrega en la lista de sus pedidos.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),

                // Footer
                if (!_isLoading) _buildFooter(),
              ],
            ),

            // Overlay de espera de pago
            if (_esperandoPago) _buildOverlayEsperando(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayEsperando() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFED1C24),
                  ),
                ),
                const SizedBox(height: 20),

                // Título cambia según el estado
                Text(
                  _volviendoAApp
                      ? 'Procesando pago...'
                      : 'Redirigiendo a MercadoPago',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtítulo cambia según el estado
                Text(
                  _volviendoAApp
                      ? 'Estamos verificando tu pago. No cierres la app.'
                      : 'Completa el pago en el navegador. Esto puede tardar unos segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                // Botón "Cancelar" solo se muestra en el estado inicial
                if (!_volviendoAApp) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _cancelarEspera,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Consumer<CarritoProvider>(
            builder: (ctx, cp, _) {
              final subtotal = cp.total;
              final total = (subtotal - _descuento)
                  .clamp(0, double.infinity)
                  .toDouble();

              return Row(
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
              );
            },
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isFormValid && !_esperandoPago
                  ? _continuarConPago
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? Colors.black
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Continuar con el pago',
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

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: ctrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.black54),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<TipoDocumentoModel> items,
    TipoDocumentoModel? value,
    ValueChanged<TipoDocumentoModel?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TipoDocumentoModel>(
              value: value,
              isExpanded: true,
              hint: Text(
                items.isEmpty ? 'Cargando...' : 'Selecciona una opción',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: items
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: items.isNotEmpty ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String title, int value) {
    final selected = _tipoEntrega == value;
    return InkWell(
      onTap: () => setState(() {
        _tipoEntrega = value;
        if (value == 1) {
          _departamentoController.clear();
          _provinciaController.clear();
          _distritoController.clear();
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
