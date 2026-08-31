import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/exceptions.dart';

/// Credenciales vigentes de la sesion.
class TokensSesion {
  const TokensSesion({
    required this.idToken,
    required this.refreshToken,
    required this.uid,
    required this.email,
    required this.nombre,
    required this.expiraEnMs,
  });

  factory TokensSesion.fromJson(Map<String, dynamic> json, {String? previoUid}) {
    final expiresIn =
        int.tryParse((json['expiresIn'] ?? '3600').toString()) ?? 3600;
    return TokensSesion(
      idToken: (json['idToken'] ?? json['id_token'] ?? '') as String,
      refreshToken:
          (json['refreshToken'] ?? json['refresh_token'] ?? '') as String,
      uid: (json['localId'] ?? json['user_id'] ?? previoUid ?? '') as String,
      email: (json['email'] ?? '') as String,
      nombre: (json['displayName'] ?? '') as String,
      expiraEnMs: DateTime.now().millisecondsSinceEpoch + expiresIn * 1000,
    );
  }

  factory TokensSesion.fromMap(Map<String, String> map) {
    return TokensSesion(
      idToken: map['idToken'] ?? '',
      refreshToken: map['refreshToken'] ?? '',
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      expiraEnMs: int.tryParse(map['expiraEnMs'] ?? '0') ?? 0,
    );
  }

  final String idToken;
  final String refreshToken;
  final String uid;
  final String email;
  final String nombre;
  final int expiraEnMs;

  /// Se considera vencido 5 minutos antes para evitar carreras con el reloj.
  bool get vencido =>
      DateTime.now().millisecondsSinceEpoch >=
      (expiraEnMs - const Duration(minutes: 5).inMilliseconds);

  Map<String, String> toMap() => <String, String>{
        'idToken': idToken,
        'refreshToken': refreshToken,
        'uid': uid,
        'email': email,
        'nombre': nombre,
        'expiraEnMs': '$expiraEnMs',
      };

  TokensSesion copyWithPerfil({String? nombre, String? email}) => TokensSesion(
        idToken: idToken,
        refreshToken: refreshToken,
        uid: uid,
        email: email ?? this.email,
        nombre: nombre ?? this.nombre,
        expiraEnMs: expiraEnMs,
      );
}

/// Autenticacion contra Firebase Identity Platform mediante su API REST.
///
/// Se usa la API REST en lugar del SDK nativo para que la aplicacion compile y
/// se ejecute sin archivos de configuracion propios de cada plataforma
/// (`google-services.json` / `GoogleService-Info.plist`), lo que simplifica la
/// evaluacion del proyecto y las pruebas automatizadas.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  static const String _identityBase =
      'https://identitytoolkit.googleapis.com/v1';
  static const String _secureTokenBase = 'https://securetoken.googleapis.com/v1';

  final String apiKey;
  final Duration timeout;
  final http.Client _http;

  Future<TokensSesion> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final json = await _post(
      Uri.parse('$_identityBase/accounts:signInWithPassword?key=$apiKey'),
      <String, dynamic>{
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    return TokensSesion.fromJson(json);
  }

  Future<TokensSesion> refrescar(TokensSesion actual) async {
    final json = await _post(
      Uri.parse('$_secureTokenBase/token?key=$apiKey'),
      <String, dynamic>{
        'grant_type': 'refresh_token',
        'refresh_token': actual.refreshToken,
      },
    );
    final renovado = TokensSesion.fromJson(json, previoUid: actual.uid);
    return renovado.copyWithPerfil(nombre: actual.nombre, email: actual.email);
  }

  void close() => _http.close();

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> body) async {
    final http.Response respuesta;
    try {
      respuesta = await _http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    final decoded = jsonDecode(respuesta.body);
    final json =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (respuesta.statusCode >= 400) {
      final error = json['error'];
      final mensaje = error is Map<String, dynamic>
          ? (error['message'] ?? 'ERROR_DESCONOCIDO').toString()
          : 'ERROR_DESCONOCIDO';
      if (respuesta.statusCode == 400 || respuesta.statusCode == 401) {
        throw UnauthorizedException(_traducir(mensaje));
      }
      throw ServerException(_traducir(mensaje), statusCode: respuesta.statusCode);
    }
    return json;
  }

  /// Traduce los codigos de Identity Platform a mensajes para el usuario.
  static String _traducir(String codigo) => switch (codigo) {
        'EMAIL_NOT_FOUND' => 'El correo no esta registrado',
        'INVALID_PASSWORD' => 'Contrasena incorrecta',
        'INVALID_LOGIN_CREDENTIALS' => 'Correo o contrasena incorrectos',
        'USER_DISABLED' => 'La cuenta fue deshabilitada',
        'TOO_MANY_ATTEMPTS_TRY_LATER' =>
          'Demasiados intentos, intente mas tarde',
        'TOKEN_EXPIRED' => 'La sesion expiro, inicie sesion nuevamente',
        _ => codigo,
      };
}
