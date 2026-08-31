/// Configuracion de entorno de la aplicacion.
///
/// Los valores se inyectan en tiempo de compilacion con `--dart-define`, de
/// modo que ninguna llave ni endpoint queda escrito en el codigo fuente:
///
/// ```bash
/// flutter run \
///   --dart-define=API_BASE_URL=https://us-central1-inmovisita.cloudfunctions.net/api \
///   --dart-define=FIREBASE_API_KEY=xxxx
/// ```
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.firebaseApiKey,
    required this.demoMode,
    this.syncIntervalSeconds = 120,
    this.maxSyncRetries = 5,
  });

  /// Construye la configuracion a partir de las variables de compilacion.
  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
    return const AppConfig(
      apiBaseUrl: baseUrl,
      firebaseApiKey: apiKey,
      demoMode: demo,
    );
  }

  /// URL base de la API REST desplegada en Cloud Functions.
  final String apiBaseUrl;

  /// Llave web de Firebase Identity Platform (autenticacion via REST).
  final String firebaseApiKey;

  /// Cuando es `true` la app funciona con datos sembrados localmente y sin
  /// backend. Permite evaluar la aplicacion sin credenciales de nube.
  final bool demoMode;

  /// Periodo del sincronizador en segundo plano.
  final int syncIntervalSeconds;

  /// Numero maximo de reintentos por operacion antes de marcarla como fallida.
  final int maxSyncRetries;

  bool get hasRemoteBackend =>
      !demoMode && apiBaseUrl.isNotEmpty && firebaseApiKey.isNotEmpty;
}
