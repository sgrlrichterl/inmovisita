import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraccion sobre el estado de la red.
///
/// Se define como interfaz para poder sustituirla por un doble de prueba en
/// los tests del motor de sincronizacion.
abstract interface class ConnectivityService {
  /// `true` si el dispositivo declara tener alguna interfaz de red activa.
  Future<bool> get isOnline;

  /// Emite `true` cuando el dispositivo recupera conectividad.
  Stream<bool> get onStatusChange;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
