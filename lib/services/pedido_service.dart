import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:xiaoxa/utils/dio_client.dart';

class PedidoService {
  final Dio _dio = ApiClient.dio;

  Future<List<dynamic>> obtenerMisPedidos() async {
    try {
      final response = await _dio.get('/mis-pedidos');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(response.data['message'] ?? 'Error al cargar pedidos');
    } on DioException catch (e) {
      if (e.response?.data?['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetallePedido(int idPedido) async {
    try {
      final response = await _dio.get('/pedidos/$idPedido');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(
        response.data['message'] ?? 'Error al cargar detalle del pedido',
      );
    } on DioException catch (e) {
      if (e.response?.data?['message'] != null) {
        throw Exception(e.response?.data['message']);
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  Future<({List<int> bytes, String extension})> descargarGuia(
    int idPedido,
  ) async {
    try {
      final response = await _dio.get(
        '/pedidos/$idPedido/descargar',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al descargar la guía');
      }

      final data = response.data;
      List<int> bytes;
      if (data is List<int>) {
        bytes = data;
      } else if (data is Uint8List) {
        bytes = data;
      } else if (data is List) {
        bytes = data.cast<int>();
      } else {
        throw Exception('Formato de archivo desconocido');
      }

      String extension = 'pdf';
      final headers = response.headers;
      final disposition =
          headers.value('content-disposition') ??
          headers.value('Content-Disposition');

      if (disposition != null) {
        final match = RegExp(
          r'filename\*?=(?:UTF-8'
          ')?"?([^";]+)"?',
          caseSensitive: false,
        ).firstMatch(disposition);

        if (match != null) {
          final filename = match.group(1)!;
          final dot = filename.lastIndexOf('.');
          if (dot != -1 && dot < filename.length - 1) {
            extension = filename.substring(dot + 1).toLowerCase();
          }
        }
      }

      return (bytes: bytes, extension: extension);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}
