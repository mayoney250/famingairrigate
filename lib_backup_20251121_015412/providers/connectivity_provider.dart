import 'dart:async';
import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provider to monitor network connectivity and sync status
class ConnectivityProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  StreamSubscription<ConnectivityResult>? _subscription;

  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  bool get hasUnsyncedData => _pendingSyncCount > 0;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check current connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(result);
      notifyListeners();

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        final wasOnline = _isOnline;
        _isOnline = _isConnected(result);
        
        if (_isOnline && !wasOnline) {
          dev.log('🌐 Device came online - syncing pending data');
        } else if (!_isOnline && wasOnline) {
          dev.log('📴 Device went offline - using cached data');
        }
        
        notifyListeners();
      });

      dev.log('✅ ConnectivityProvider initialized (online: $_isOnline)');
    } catch (e) {
      dev.log('❌ Error initializing ConnectivityProvider: $e');
    }
  }

  /// Update pending sync count
  void updatePendingSyncCount(int count) {
    if (_pendingSyncCount != count) {
      _pendingSyncCount = count;
      notifyListeners();
    }
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
