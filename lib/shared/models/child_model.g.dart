// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChildModelAdapter extends TypeAdapter<ChildModel> {
  @override
  final int typeId = 2;

  @override
  ChildModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChildModel(
      id: fields[0] as String,
      name: fields[1] as String,
      parentId: fields[2] as String,
      schoolId: fields[3] as String,
      grade: fields[4] as String,
      className: fields[5] as String,
      photoUrl: fields[6] as String?,
      dateOfBirth: fields[7] as DateTime,
      medicalInfo: fields[8] as String?,
      emergencyContact: fields[9] as String?,
      emergencyContactPhone: fields[10] as String?,
      busId: fields[11] as String?,
      routeId: fields[12] as String?,
      pickupStopId: fields[13] as String?,
      dropoffStopId: fields[14] as String?,
      isActive: fields[15] as bool,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      metadata: (fields[18] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChildModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.schoolId)
      ..writeByte(4)
      ..write(obj.grade)
      ..writeByte(5)
      ..write(obj.className)
      ..writeByte(6)
      ..write(obj.photoUrl)
      ..writeByte(7)
      ..write(obj.dateOfBirth)
      ..writeByte(8)
      ..write(obj.medicalInfo)
      ..writeByte(9)
      ..write(obj.emergencyContact)
      ..writeByte(10)
      ..write(obj.emergencyContactPhone)
      ..writeByte(11)
      ..write(obj.busId)
      ..writeByte(12)
      ..write(obj.routeId)
      ..writeByte(13)
      ..write(obj.pickupStopId)
      ..writeByte(14)
      ..write(obj.dropoffStopId)
      ..writeByte(15)
      ..write(obj.isActive)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
