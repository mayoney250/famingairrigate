import 'package:hive/hive.dart';

/// Represents a pending write operation that needs to sync to Firebase.
@HiveType(typeId: 20)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String collection; // e.g., 'sensorData', 'irrigationLogs'

  @HiveField(2)
  late String operation; // 'create', 'update', 'delete'

  @HiveField(3)
  late Map<String, dynamic> data; // Document data

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late int retryCount;

  @HiveField(6)
  late String status; // 'pending', 'uploading', 'failed', 'completed'

  @HiveField(7)
  String? error;

  @HiveField(8)
  DateTime? lastRetryAt;

  @HiveField(9)
  String? userId; // Track which user this sync is for

  SyncQueueItem({
    required this.id,
    required this.collection,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
    this.error,
    this.lastRetryAt,
    this.userId,
  });

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCompleted => status == 'completed';

  /// Check if enough time has passed to retry
  bool shouldRetry({int maxRetries = 5}) {
    if (status != 'failed' || retryCount >= maxRetries) return false;
    if (lastRetryAt == null) return true;

    // Exponential backoff: 5s * 2^retryCount seconds
    final backoffSeconds = 5 * (1 << retryCount);
    return DateTime.now().difference(lastRetryAt!).inSeconds >= backoffSeconds;
  }
}
