// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final int typeId = 5;

  @override
  RouteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteModel(
      id: fields[0] as String,
      name: fields[1] as String,
      schoolId: fields[2] as String,
      busId: fields[3] as String?,
      stops: (fields[4] as List).cast<RouteStop>(),
      type: fields[5] as RouteType,
      startTime: fields[6] as DateTime,
      endTime: fields[7] as DateTime,
      estimatedDuration: fields[8] as int,
      distance: fields[9] as double,
      isActive: fields[10] as bool,
      activeDays: (fields[11] as List?)?.cast<String>(),
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      metadata: (fields[14] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.schoolId)
      ..writeByte(3)
      ..write(obj.busId)
      ..writeByte(4)
      ..write(obj.stops)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.estimatedDuration)
      ..writeByte(9)
      ..write(obj.distance)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.activeDays)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteStopAdapter extends TypeAdapter<RouteStop> {
  @override
  final int typeId = 6;

  @override
  RouteStop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteStop(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      address: fields[4] as String,
      order: fields[5] as int,
      scheduledTime: fields[6] as DateTime,
      estimatedWaitTime: fields[7] as int,
      childrenIds: (fields[8] as List?)?.cast<String>(),
      isActive: fields[9] as bool,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, RouteStop obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.scheduledTime)
      ..writeByte(7)
      ..write(obj.estimatedWaitTime)
      ..writeByte(8)
      ..write(obj.childrenIds)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteStopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteTypeAdapter extends TypeAdapter<RouteType> {
  @override
  final int typeId = 7;

  @override
  RouteType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RouteType.pickup;
      case 1:
        return RouteType.dropoff;
      case 2:
        return RouteType.roundTrip;
      default:
        return RouteType.pickup;
    }
  }

  @override
  void write(BinaryWriter writer, RouteType obj) {
    switch (obj) {
      case RouteType.pickup:
        writer.writeByte(0);
        break;
      case RouteType.dropoff:
        writer.writeByte(1);
        break;
      case RouteType.roundTrip:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
