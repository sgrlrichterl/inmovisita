import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';

/// Firma de la funcion que entrega el token de acceso vigente.
typedef TokenProvider = Future<String?> Function();

/// Cliente HTTP de la API REST desplegada en Cloud Functions.
///
/// Responsabilidades:
/// * anteponer la URL base y el prefijo de version (`/v1`);
/// * inyectar el token JWT en la cabecera `Authorization`;
/// * traducir codigos de estado y errores de socket a excepciones tipadas;
/// * aplicar un timeout uniforme a todas las peticiones.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenProvider tokenProvider;
  final Duration timeout;
  final http.Client _http;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    return _send(() async => _http.get(uri, headers: await _headers()));
  }

  Future<Map<String, dynamic>> post(String path, Object body) async {
    final uri = _uri(path, null);
    return _send(
      () async => _http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  void close() => _http.close();

  Uri _uri(String path, Map<String, String>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw NetworkException('La peticion supero ${timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw UnauthorizedException(_extractMessage(response.body));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(
        _extractMessage(response.body),
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  String _extractMessage(String body) {
    if (body.isEmpty) {
      return 'Respuesta vacia del servidor';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } on FormatException {
      // El cuerpo no era JSON: se devuelve tal cual, recortado.
    }
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }
}
