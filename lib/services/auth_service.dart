import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/storage_service.dart';

class AuthService {
  static const String tokenKey = 'token';
  static const String usuarioKey = 'usuario';

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
      data = Map<String, dynamic>.from(jsonDecode(response.body));
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

    if (token == null || token.toString().trim().isEmpty) {
      throw Exception('El servidor no regresó token.');
    }

    if (usuario == null || usuario is! Map || usuario['id'] == null) {
      throw Exception('El servidor no regresó usuario.id.');
    }

    final usuarioMap = Map<String, dynamic>.from(usuario);

    await guardarSesion(
      token: token.toString(),
      usuario: usuarioMap,
    );

    return {
      'token': token.toString(),
      'usuario': usuarioMap,
    };
  }

  static Future<void> guardarSesion({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    await StorageService.setItem(tokenKey, token);
    await StorageService.setItem(usuarioKey, jsonEncode(usuario));
  }

  static Future<void> logout() async {
    await StorageService.removeItem(tokenKey);
    await StorageService.removeItem(usuarioKey);
  }

  static Future<bool> haySesionActiva() async {
    final token = await getToken();

    return token != null && token.trim().isNotEmpty;
  }

  static Future<bool> isLoggedIn() async {
    return await haySesionActiva();
  }

  static Future<Map<String, dynamic>?> getUsuario() async {
    final usuarioString = await StorageService.getItem(usuarioKey);

    if (usuarioString == null || usuarioString.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(usuarioString);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getToken() async {
    return await StorageService.getItem(tokenKey);
  }
}