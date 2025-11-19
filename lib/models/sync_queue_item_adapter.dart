import 'package:hive/hive.dart';
import 'sync_queue_item_model.dart';

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  // Type id implemented via the getter below - remove duplicate field

  @override
  SyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItem(
      id: fields[0] as String,
      collection: fields[1] as String,
      operation: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] as int? ?? 0,
      status: fields[6] as String? ?? 'pending',
      error: fields[7] as String?,
      lastRetryAt: fields[8] as DateTime?,
      userId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeByte(10);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.collection);
    writer.writeByte(2);
    writer.write(obj.operation);
    writer.writeByte(3);
    writer.write(obj.data);
    writer.writeByte(4);
    writer.write(obj.createdAt);
    writer.writeByte(5);
    writer.write(obj.retryCount);
    writer.writeByte(6);
    writer.write(obj.status);
    writer.writeByte(7);
    writer.write(obj.error);
    writer.writeByte(8);
    writer.write(obj.lastRetryAt);
    writer.writeByte(9);
    writer.write(obj.userId);
  }

  @override
  int get typeId => 20;
}
