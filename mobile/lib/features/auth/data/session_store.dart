import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_remote_data_source.dart';

/// Almacenamiento cifrado de la sesion.
///
/// Usa `EncryptedSharedPreferences` en Android (respaldado por Android
/// Keystore) y el Keychain en iOS con accesibilidad
/// `first_unlock_this_device`, de modo que los tokens nunca se escriben en
/// texto plano ni salen del dispositivo en copias de seguridad.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String _claves = 'inmovisita_sesion';

  final FlutterSecureStorage _storage;

  Future<void> guardar(TokensSesion tokens) async {
    final mapa = tokens.toMap();
    for (final entrada in mapa.entries) {
      await _storage.write(
        key: '${_claves}_${entrada.key}',
        value: entrada.value,
      );
    }
  }

  Future<TokensSesion?> leer() async {
    final mapa = <String, String>{};
    for (final clave in const <String>[
      'idToken',
      'refreshToken',
      'uid',
      'email',
      'nombre',
      'expiraEnMs',
    ]) {
      final valor = await _storage.read(key: '${_claves}_$clave');
      if (valor != null) {
        mapa[clave] = valor;
      }
    }
    if (mapa['refreshToken'] == null || mapa['refreshToken']!.isEmpty) {
      return null;
    }
    return TokensSesion.fromMap(mapa);
  }

  Future<void> borrar() async {
    for (final clave in const <String>[
      'idToken',
      'refreshToken',
      'uid',
      'email',
      'nombre',
      'expiraEnMs',
    ]) {
      await _storage.delete(key: '${_claves}_$clave');
    }
  }
}
