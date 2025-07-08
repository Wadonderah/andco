// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckinModelAdapter extends TypeAdapter<CheckinModel> {
  @override
  final int typeId = 12;

  @override
  CheckinModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckinModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      childId: fields[2] as String,
      childName: fields[3] as String,
      stopId: fields[4] as String,
      driverId: fields[5] as String,
      busId: fields[6] as String,
      routeId: fields[7] as String,
      method: fields[8] as CheckinMethod,
      photoUrl: fields[9] as String?,
      timestamp: fields[10] as DateTime,
      location: fields[11] as LocationData?,
      status: fields[12] as CheckinStatus,
      notes: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CheckinModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.childId)
      ..writeByte(3)
      ..write(obj.childName)
      ..writeByte(4)
      ..write(obj.stopId)
      ..writeByte(5)
      ..write(obj.driverId)
      ..writeByte(6)
      ..write(obj.busId)
      ..writeByte(7)
      ..write(obj.routeId)
      ..writeByte(8)
      ..write(obj.method)
      ..writeByte(9)
      ..write(obj.photoUrl)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CheckinMethodAdapter extends TypeAdapter<CheckinMethod> {
  @override
  final int typeId = 13;

  @override
  CheckinMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CheckinMethod.manual;
      case 1:
        return CheckinMethod.qr;
      case 2:
        return CheckinMethod.faceId;
      case 3:
        return CheckinMethod.nfc;
      default:
        return CheckinMethod.manual;
    }
  }

  @override
  void write(BinaryWriter writer, CheckinMethod obj) {
    switch (obj) {
      case CheckinMethod.manual:
        writer.writeByte(0);
        break;
      case CheckinMethod.qr:
        writer.writeByte(1);
        break;
      case CheckinMethod.faceId:
        writer.writeByte(2);
        break;
      case CheckinMethod.nfc:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CheckinStatusAdapter extends TypeAdapter<CheckinStatus> {
  @override
  final int typeId = 14;

  @override
  CheckinStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CheckinStatus.confirmed;
      case 1:
        return CheckinStatus.pending;
      case 2:
        return CheckinStatus.cancelled;
      default:
        return CheckinStatus.confirmed;
    }
  }

  @override
  void write(BinaryWriter writer, CheckinStatus obj) {
    switch (obj) {
      case CheckinStatus.confirmed:
        writer.writeByte(0);
        break;
      case CheckinStatus.pending:
        writer.writeByte(1);
        break;
      case CheckinStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
