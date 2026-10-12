// services/tipo_documento_service.dart

import 'package:dio/dio.dart';
import 'package:xiaoxa/models/tipo_documento_model.dart';
import 'package:xiaoxa/utils/dio_client.dart';

class TipoDocumentoService {
  final Dio _dio = ApiClient.dio;

  /// Obtiene los tipos de documento desde el backend.
  /// GET /api/tipos-documento
  Future<List<TipoDocumentoModel>> obtenerTiposDocumento() async {
    try {
      final response = await _dio.get('/tipos-documento');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data
            .map((e) => TipoDocumentoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('No se pudieron cargar los tipos de documento');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Error ${e.response?.statusCode}';
    }
    return 'Error de conexión: ${e.message}';
  }
}
