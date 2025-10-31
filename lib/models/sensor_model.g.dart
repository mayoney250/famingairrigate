// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorModelAdapter extends TypeAdapter<SensorModel> {
  @override
  final int typeId = 3;

  @override
  SensorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorModel(
      id: fields[0] as String,
      farmId: fields[1] as String,
      displayName: fields[2] as String?,
      type: fields[3] as String,
      hardwareId: fields[4] as String,
      pairing: (fields[5] as Map).cast<String, dynamic>(),
      status: fields[6] as String,
      lastSeenAt: fields[7] as DateTime?,
      assignedZoneId: fields[8] as String?,
      battery: fields[9] as double?,
      installNote: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SensorModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmId)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.hardwareId)
      ..writeByte(5)
      ..write(obj.pairing)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastSeenAt)
      ..writeByte(8)
      ..write(obj.assignedZoneId)
      ..writeByte(9)
      ..write(obj.battery)
      ..writeByte(10)
      ..write(obj.installNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
