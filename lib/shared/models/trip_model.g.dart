// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 8;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel(
      id: fields[0] as String,
      busId: fields[1] as String,
      routeId: fields[2] as String,
      driverId: fields[3] as String,
      busNumber: fields[4] as String,
      routeName: fields[5] as String,
      type: fields[6] as TripType,
      status: fields[7] as TripStatus,
      childrenIds: (fields[8] as List).cast<String>(),
      checkedInChildren: (fields[9] as List).cast<String>(),
      startTime: fields[10] as DateTime,
      endTime: fields[11] as DateTime?,
      currentLocation: fields[12] as LocationData?,
      locationHistory: (fields[13] as List?)?.cast<LocationData>(),
      estimatedDuration: fields[14] as int?,
      actualDistance: fields[15] as double?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      metadata: (fields[18] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.busId)
      ..writeByte(2)
      ..write(obj.routeId)
      ..writeByte(3)
      ..write(obj.driverId)
      ..writeByte(4)
      ..write(obj.busNumber)
      ..writeByte(5)
      ..write(obj.routeName)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.childrenIds)
      ..writeByte(9)
      ..write(obj.checkedInChildren)
      ..writeByte(10)
      ..write(obj.startTime)
      ..writeByte(11)
      ..write(obj.endTime)
      ..writeByte(12)
      ..write(obj.currentLocation)
      ..writeByte(13)
      ..write(obj.locationHistory)
      ..writeByte(14)
      ..write(obj.estimatedDuration)
      ..writeByte(15)
      ..write(obj.actualDistance)
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
      other is TripModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationDataAdapter extends TypeAdapter<LocationData> {
  @override
  final int typeId = 9;

  @override
  LocationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationData(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timestamp: fields[2] as DateTime,
      accuracy: fields[3] as double?,
      speed: fields[4] as double?,
      heading: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.speed)
      ..writeByte(5)
      ..write(obj.heading);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TripTypeAdapter extends TypeAdapter<TripType> {
  @override
  final int typeId = 10;

  @override
  TripType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TripType.pickup;
      case 1:
        return TripType.dropoff;
      default:
        return TripType.pickup;
    }
  }

  @override
  void write(BinaryWriter writer, TripType obj) {
    switch (obj) {
      case TripType.pickup:
        writer.writeByte(0);
        break;
      case TripType.dropoff:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TripStatusAdapter extends TypeAdapter<TripStatus> {
  @override
  final int typeId = 11;

  @override
  TripStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TripStatus.active;
      case 1:
        return TripStatus.completed;
      case 2:
        return TripStatus.cancelled;
      case 3:
        return TripStatus.paused;
      default:
        return TripStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, TripStatus obj) {
    switch (obj) {
      case TripStatus.active:
        writer.writeByte(0);
        break;
      case TripStatus.completed:
        writer.writeByte(1);
        break;
      case TripStatus.cancelled:
        writer.writeByte(2);
        break;
      case TripStatus.paused:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
