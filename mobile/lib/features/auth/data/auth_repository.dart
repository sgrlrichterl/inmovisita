import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/usuario.dart';
import 'auth_remote_data_source.dart';
import 'session_store.dart';

/// Punto unico de verdad de la sesion del usuario.
///
/// Expone [tokenActual] como `TokenProvider` para el `ApiClient`: renueva el
/// token de forma transparente cuando esta proximo a vencer.
class AuthRepository {
  AuthRepository({
    required AppConfig config,
    required SessionStore store,
    AuthRemoteDataSource? remoto,
  })  : _config = config,
        _store = store,
        _remoto = remoto;

  /// Credenciales del usuario de demostracion (solo en `DEMO_MODE`).
  static const String demoEmail = 'asesor@inmovisita.co';
  static const String demoPassword = 'demo1234';

  static const Usuario _usuarioDemo = Usuario(
    uid: 'demo-asesor-001',
    nombre: 'Asesor Demo',
    email: demoEmail,
    rol: RolUsuario.asesor,
  );

  final AppConfig _config;
  final SessionStore _store;
  final AuthRemoteDataSource? _remoto;

  TokensSesion? _tokens;
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  bool get autenticado => _usuario != null;

  Future<Result<Usuario>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const Result<Usuario>.err(
        ValidationFailure('Ingrese correo y contrasena'),
      );
    }

    final remoto = _remoto;
    if (remoto == null || !_config.hasRemoteBackend) {
      if (email.trim().toLowerCase() == demoEmail && password == demoPassword) {
        _usuario = _usuarioDemo;
        return const Result<Usuario>.ok(_usuarioDemo);
      }
      return const Result<Usuario>.err(
        AuthFailure('Modo demostracion: use $demoEmail / $demoPassword'),
      );
    }

    try {
      final tokens = await remoto.iniciarSesion(
        email: email.trim(),
        password: password,
      );
      await _store.guardar(tokens);
      _tokens = tokens;
      _usuario = _desdeTokens(tokens);
      return Result<Usuario>.ok(_usuario!);
    } on UnauthorizedException catch (e) {
      return Result<Usuario>.err(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Result<Usuario>.err(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result<Usuario>.err(
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    }
  }

  /// Recupera la sesion persistida al abrir la aplicacion.
  Future<Usuario?> restaurarSesion() async {
    if (!_config.hasRemoteBackend) {
      return _usuario;
    }
    final guardados = await _store.leer();
    if (guardados == null) return null;
    _tokens = guardados;
    _usuario = _desdeTokens(guardados);
    return _usuario;
  }

  /// Token vigente para el encabezado `Authorization`.
  Future<String?> tokenActual() async {
    final remoto = _remoto;
    final tokens = _tokens;
    if (remoto == null || tokens == null) return null;
    if (!tokens.vencido) return tokens.idToken;
    try {
      final renovado = await remoto.refrescar(tokens);
      _tokens = renovado;
      await _store.guardar(renovado);
      return renovado.idToken;
    } on UnauthorizedException {
      await cerrarSesion();
      return null;
    } on NetworkException {
      // Sin red se devuelve el token actual: la peticion fallara y la
      // operacion permanecera en la cola de salida.
      return tokens.idToken;
    }
  }

  Future<void> cerrarSesion() async {
    _tokens = null;
    _usuario = null;
    await _store.borrar();
  }

  Usuario _desdeTokens(TokensSesion tokens) => Usuario(
        uid: tokens.uid,
        nombre: tokens.nombre.isEmpty ? tokens.email : tokens.nombre,
        email: tokens.email,
        rol: RolUsuario.asesor,
      );
}
