// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 5;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      userId: fields[0] as String,
      email: fields[1] as String,
      firstName: fields[2] as String,
      lastName: fields[3] as String,
      phoneNumber: fields[4] as String?,
      avatar: fields[5] as String?,
      isActive: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      tokens: (fields[8] as List).cast<String>(),
      isOnline: fields[9] as bool,
      lastActive: fields[10] as String?,
      about: fields[11] as String?,
      isPublic: fields[12] as bool,
      district: fields[13] as String?,
      province: fields[14] as String?,
      country: fields[15] as String,
      address: fields[16] as String?,
      role: fields[17] as String,
      languagePreference: fields[18] as String?,
      themePreference: fields[19] as String?,
      idNumber: fields[20] as String?,
      gender: fields[21] as String?,
      dateOfBirth: fields[22] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.avatar)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.tokens)
      ..writeByte(9)
      ..write(obj.isOnline)
      ..writeByte(10)
      ..write(obj.lastActive)
      ..writeByte(11)
      ..write(obj.about)
      ..writeByte(12)
      ..write(obj.isPublic)
      ..writeByte(13)
      ..write(obj.district)
      ..writeByte(14)
      ..write(obj.province)
      ..writeByte(15)
      ..write(obj.country)
      ..writeByte(16)
      ..write(obj.address)
      ..writeByte(17)
      ..write(obj.role)
      ..writeByte(18)
      ..write(obj.languagePreference)
      ..writeByte(19)
      ..write(obj.themePreference)
      ..writeByte(20)
      ..write(obj.idNumber)
      ..writeByte(21)
      ..write(obj.gender)
      ..writeByte(22)
      ..write(obj.dateOfBirth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
