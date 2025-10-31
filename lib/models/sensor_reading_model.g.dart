// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_reading_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorReadingModelAdapter extends TypeAdapter<SensorReadingModel> {
  @override
  final int typeId = 4;

  @override
  SensorReadingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorReadingModel(
      id: fields[0] as String,
      sensorId: fields[1] as String,
      ts: fields[2] as DateTime,
      moisture: fields[3] as double?,
      temperature: fields[4] as double?,
      humidity: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SensorReadingModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sensorId)
      ..writeByte(2)
      ..write(obj.ts)
      ..writeByte(3)
      ..write(obj.moisture)
      ..writeByte(4)
      ..write(obj.temperature)
      ..writeByte(5)
      ..write(obj.humidity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorReadingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
