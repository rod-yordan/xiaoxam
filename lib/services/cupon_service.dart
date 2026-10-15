// services/cupon_service.dart
import 'package:dio/dio.dart';
import 'package:xiaoxa/models/cupon_model.dart';
import 'package:xiaoxa/services/auth_service.dart';
import 'package:xiaoxa/utils/dio_client.dart';

class CuponService {
  final Dio _dio = ApiClient.dio;
  final AuthService _authService = AuthService();

  /// Adjunta el token si existe. Si no hay sesión, quita el header
  /// para no arrastrar tokens de llamadas previas.
  Future<void> _ensureToken() async {
    try {
      final token = await _authService.getStoredToken();
      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        _dio.options.headers.remove('Authorization');
      }
    } catch (_) {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Obtiene los cupones disponibles.
  /// - Si el usuario está logueado → solo los que NO ha usado
  /// - Si NO está logueado → todos los activos
  /// GET /api/cupones
  Future<List<CuponModel>> cuponesDisponibles() async {
    try {
      await _ensureToken();

      final response = await _dio.get('/cupones');

      if (response.data['success'] == true) {
        final List<dynamic> lista = response.data['data'] ?? [];
        return lista.map((e) => CuponModel.fromJson(e)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Aplica un cupón al carrito (requiere sesión).
  /// POST /api/carrito/cupon/aplicar
  Future<Map<String, dynamic>> aplicarCupon(String codigo) async {
    try {
      await _ensureToken();

      final response = await _dio.post(
        '/carrito/cupon/aplicar',
        data: {'codigo_cupon': codigo},
      );

      if (response.data['success'] == true) {
        return {
          'id_cupon': response.data['id_cupon'],
          'codigo': response.data['codigo'],
          'descuento': (response.data['descuento'] as num).toDouble(),
          'subtotal': (response.data['subtotal'] as num).toDouble(),
          'nuevo_total': (response.data['nuevo_total'] as num).toDouble(),
        };
      }

      throw response.data['message'] ?? 'No se pudo aplicar el cupón';
    } on DioException catch (e) {
      // Si el backend devuelve un mensaje en 400/404, lo usamos
      if (e.response?.data?['message'] != null) {
        throw e.response!.data['message'].toString();
      }
      throw _handleError(e);
    }
  }

  /// Quita el cupón aplicado (requiere sesión).
  /// DELETE /api/carrito/cupon/quitar
  Future<void> quitarCupon() async {
    try {
      await _ensureToken();

      await _dio.delete('/carrito/cupon/quitar');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return error.response?.data?['message'] ?? 'Error del servidor';
      default:
        return 'Error de conexión: ${error.message}';
    }
  }
}
