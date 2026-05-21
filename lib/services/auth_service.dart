import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre_usuario': username.trim(),
        'contrasena': password.trim(),
      }),
    );

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('El servidor no regresó una respuesta JSON válida.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mensaje = data['mensaje'] ??
          data['detalle'] ??
          'No se pudo iniciar sesión. Código ${response.statusCode}.';

      throw Exception(mensaje);
    }

    if (data['status'] != 'ok') {
      final mensaje = data['mensaje'] ?? 'No se pudo iniciar sesión.';
      throw Exception(mensaje);
    }

    final token = data['token'];
    final usuario = data['usuario'];

    if (token == null || token.toString().isEmpty) {
      throw Exception('El servidor no regresó token.');
    }

    if (usuario == null || usuario['id'] == null) {
      throw Exception('El servidor no regresó usuario.id.');
    }

    await StorageService.setItem('token', token.toString());
    await StorageService.setItem('usuario', jsonEncode(usuario));

    return {
      'token': token,
      'usuario': usuario,
    };
  }

  static Future<void> logout() async {
    await StorageService.removeItem('token');
    await StorageService.removeItem('usuario');
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getItem('token');

    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getUsuario() async {
    final usuarioString = await StorageService.getItem('usuario');

    if (usuarioString == null || usuarioString.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(usuarioString);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getToken() async {
    return await StorageService.getItem('token');
  }
}