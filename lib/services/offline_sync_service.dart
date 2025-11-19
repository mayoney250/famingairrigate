import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/sync_queue_item_model.dart';

/// Service to manage offline sync queue and background uploads
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  Box<SyncQueueItem>? _syncBox;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  
  int _successfulSyncs = 0;
  int _totalSyncAttempts = 0;

  /// Initialize the sync service
  Future<void> initialize() async {
    try {
      _syncBox = await Hive.openBox<SyncQueueItem>('syncQueue');
      dev.log('✅ OfflineSyncService initialized');
      
      // Monitor connectivity changes
      _setupConnectivityListener();
      
      // Start periodic sync (check every 10 seconds if online)
      _startPeriodicSync();
      
      // Try to sync any pending items immediately
      await processPendingQueue();
    } catch (e) {
      dev.log('❌ Error initializing OfflineSyncService: $e');
    }
  }

  /// Enqueue an operation for later sync
  Future<void> enqueueOperation({
    required String collection,
    required String operation, // 'create', 'update', 'delete'
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final item = SyncQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${collection}_${operation}',
        collection: collection,
        operation: operation,
        data: data,
        createdAt: DateTime.now(),
        status: 'pending',
        userId: userId,
      );

      await _syncBox?.add(item);
      _totalSyncAttempts++;
      
      dev.log('📋 Enqueued $operation for $collection (Total pending: ${_syncBox?.length ?? 0})');
      
      // Try to sync immediately if online
      await processPendingQueue();
    } catch (e) {
      dev.log('❌ Error enqueueing operation: $e');
    }
  }

  /// Process the sync queue
  Future<void> processPendingQueue() async {
    if (_syncBox == null || _syncBox!.isEmpty) {
      return;
    }

    final isOnline = await _isOnline();
    if (!isOnline) {
      dev.log('📴 Offline: Skipping sync, will retry when online');
      return;
    }

    dev.log('🔄 Processing sync queue (${_syncBox!.length} items)');

    final items = _syncBox!.values.where((i) => i.isPending || i.shouldRetry()).toList();
    
    for (final item in items) {
      try {
        await _syncItem(item);
      } catch (e) {
        dev.log('❌ Error syncing item ${item.id}: $e');
      }
    }

    _logSyncMetrics();
  }

  /// Sync a single item
  Future<void> _syncItem(SyncQueueItem item) async {
    try {
      item.status = 'uploading';
      item.lastRetryAt = DateTime.now();
      item.retryCount++;
      await item.save();

      final collection = _firestore.collection(item.collection);

      switch (item.operation) {
        case 'create':
          await collection.add(item.data);
          break;
        case 'update':
          final docId = item.data['id'] ?? item.data['docId'];
          if (docId != null) {
            await collection.doc(docId).update(item.data);
          }
          break;
        case 'delete':
          final docId = item.data['id'] ?? item.data['docId'];
          if (docId != null) {
            await collection.doc(docId).delete();
          }
          break;
      }

      // Mark as completed
      item.status = 'completed';
      item.error = null;
      await item.save();
      
      _successfulSyncs++;
      dev.log('✅ Synced ${item.operation} to ${ item.collection}');
    } catch (e) {
      item.status = 'failed';
      item.error = e.toString();
      await item.save();
      
      dev.log('❌ Failed to sync ${item.operation} to ${item.collection}: $e');
      
      // Remove after 5 failed attempts
      if (item.retryCount >= 5) {
        await item.delete();
        dev.log('🗑️ Deleted item after 5 failed attempts: ${item.id}');
      }
    }
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;

      if (isOnline) {
        dev.log('🌐 Connected to internet - processing sync queue');
        processPendingQueue();
      } else {
        dev.log('📴 Lost internet connection');
      }
    });
  }

  /// Start periodic sync every 10 seconds
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      processPendingQueue();
    });
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
    } catch (e) {
      return false;
    }
  }

  /// Get sync metrics
  Map<String, dynamic> getSyncMetrics() {
    final queue = _syncBox?.values.toList() ?? [];
    final pending = queue.where((i) => i.isPending).length;
    final failed = queue.where((i) => i.isFailed).length;
    final completed = queue.where((i) => i.isCompleted).length;
    
    final successRate = _totalSyncAttempts > 0
        ? (_successfulSyncs / _totalSyncAttempts * 100).toStringAsFixed(1)
        : 'N/A';

    return {
      'pendingCount': pending,
      'failedCount': failed,
      'completedCount': completed,
      'totalInQueue': queue.length,
      'successfulSyncs': _successfulSyncs,
      'totalAttempts': _totalSyncAttempts,
      'successRate': '$successRate%',
    };
  }

  /// Log sync metrics
  void _logSyncMetrics() {
    final metrics = getSyncMetrics();
    dev.log('📊 Sync Metrics: $metrics');
  }

  /// Clear completed items from queue
  Future<void> clearCompletedItems() async {
    if (_syncBox == null) return;
    
    final completed = _syncBox!.values
        .where((i) => i.isCompleted)
        .toList();
    
    for (final item in completed) {
      await item.delete();
    }
    
    dev.log('🗑️ Cleared ${completed.length} completed items from sync queue');
  }

  /// Get pending items count
  int getPendingCount() {
    return _syncBox?.values.where((i) => i.isPending).length ?? 0;
  }

  /// Dispose and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
