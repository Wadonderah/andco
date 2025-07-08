// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusModelAdapter extends TypeAdapter<BusModel> {
  @override
  final int typeId = 3;

  @override
  BusModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusModel(
      id: fields[0] as String,
      busNumber: fields[1] as String,
      licensePlate: fields[2] as String,
      schoolId: fields[3] as String,
      driverId: fields[4] as String?,
      capacity: fields[5] as int,
      model: fields[6] as String,
      manufacturer: fields[7] as String,
      year: fields[8] as int,
      color: fields[9] as String?,
      status: fields[10] as BusStatus,
      lastMaintenanceDate: fields[11] as DateTime?,
      nextMaintenanceDate: fields[12] as DateTime?,
      currentLatitude: fields[13] as double?,
      currentLongitude: fields[14] as double?,
      lastLocationUpdate: fields[15] as DateTime?,
      features: (fields[16] as List?)?.cast<String>(),
      isActive: fields[17] as bool,
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime,
      metadata: (fields[20] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BusModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.busNumber)
      ..writeByte(2)
      ..write(obj.licensePlate)
      ..writeByte(3)
      ..write(obj.schoolId)
      ..writeByte(4)
      ..write(obj.driverId)
      ..writeByte(5)
      ..write(obj.capacity)
      ..writeByte(6)
      ..write(obj.model)
      ..writeByte(7)
      ..write(obj.manufacturer)
      ..writeByte(8)
      ..write(obj.year)
      ..writeByte(9)
      ..write(obj.color)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.lastMaintenanceDate)
      ..writeByte(12)
      ..write(obj.nextMaintenanceDate)
      ..writeByte(13)
      ..write(obj.currentLatitude)
      ..writeByte(14)
      ..write(obj.currentLongitude)
      ..writeByte(15)
      ..write(obj.lastLocationUpdate)
      ..writeByte(16)
      ..write(obj.features)
      ..writeByte(17)
      ..write(obj.isActive)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BusStatusAdapter extends TypeAdapter<BusStatus> {
  @override
  final int typeId = 4;

  @override
  BusStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BusStatus.active;
      case 1:
        return BusStatus.inactive;
      case 2:
        return BusStatus.inTransit;
      case 3:
        return BusStatus.maintenance;
      case 4:
        return BusStatus.outOfService;
      default:
        return BusStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, BusStatus obj) {
    switch (obj) {
      case BusStatus.active:
        writer.writeByte(0);
        break;
      case BusStatus.inactive:
        writer.writeByte(1);
        break;
      case BusStatus.inTransit:
        writer.writeByte(2);
        break;
      case BusStatus.maintenance:
        writer.writeByte(3);
        break;
      case BusStatus.outOfService:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
