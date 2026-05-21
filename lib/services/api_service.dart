import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final response = await http.get(
      url,
      headers: await _headers(),
    );

    return _processResponse(response);
  }

  static Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    return _processResponse(response);
  }

  static Future<dynamic> put(String endpoint, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final response = await http.put(
      url,
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    return _processResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final response = await http.delete(
      url,
      headers: await _headers(),
    );

    return _processResponse(response);
  }

  static dynamic _processResponse(http.Response response) {
    dynamic data;

    try {
      if (response.body.trim().isEmpty) {
        data = {};
      } else {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      throw Exception('El servidor no regresó JSON válido.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (data is Map<String, dynamic>) {
        final mensaje = data['mensaje'] ??
            data['detalle'] ??
            'Error del servidor. Código ${response.statusCode}.';

        throw Exception(mensaje);
      }

      throw Exception('Error del servidor. Código ${response.statusCode}.');
    }

    return data;
  }
}