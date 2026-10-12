import 'package:dio/dio.dart';
import 'package:xiaoxa/services/auth_service.dart';
import 'package:xiaoxa/utils/dio_client.dart';

class CheckoutService {
  final Dio _dio = ApiClient.dio;
  final AuthService _authService = AuthService();

  Future<void> _ensureToken() async {
    final token = await _authService.getStoredToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> crearPreferencia({
    required int idTipoDocumento,
    required String numeroDocumento,
    required String telefono,
    required int idTipoEntrega,
    String? departamento,
    String? provincia,
    String? distrito,
    String? codigoCupon,
  }) async {
    try {
      await _ensureToken();

      final response = await _dio.post(
        '/checkout/crear-preferencia',
        data: {
          'id_tipo_documento': idTipoDocumento,
          'numero_documento': numeroDocumento,
          'telefono': telefono,
          'id_tipo_entrega': idTipoEntrega,
          'departamento': idTipoEntrega == 2 ? departamento : null,
          'provincia': idTipoEntrega == 2 ? provincia : null,
          'distrito': idTipoEntrega == 2 ? distrito : null,
          'codigo_cupon': codigoCupon,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(response.data['message'] ?? 'Error al crear preferencia');
    } on DioException catch (e) {
      if (e.response?.data?['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> consultarEstado(String referencia) async {
    try {
      await _ensureToken();

      final response = await _dio.get('/checkout/estado/$referencia');

      if (response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception('Error al consultar el estado');
    } on DioException catch (e) {
      if (e.response?.data?['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}
