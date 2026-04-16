import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Vérifier l'état initial
    await _checkConnectivity();

    // Écouter les changements de connectivité
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _checkConnectivity();
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((result) => 
        result != ConnectivityResult.none
      );

      // Vérifier réellement la connectivité en tentant une connexion
      if (hasConnection) {
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 3));
          _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (e) {
          _isConnected = false;
        }
      } else {
        _isConnected = false;
      }

      _connectionController.add(_isConnected);
    } catch (e) {
      debugPrint('Erreur vérification connectivité: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}

