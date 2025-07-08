// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 18;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      schoolId: fields[2] as String?,
      type: fields[3] as NotificationType,
      title: fields[4] as String,
      body: fields[5] as String,
      data: (fields[6] as Map).cast<String, dynamic>(),
      priority: fields[7] as NotificationPriority,
      isRead: fields[8] as bool,
      readAt: fields[9] as DateTime?,
      imageUrl: fields[10] as String?,
      actionUrl: fields[11] as String?,
      expiresAt: fields[12] as DateTime?,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.schoolId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.data)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.readAt)
      ..writeByte(10)
      ..write(obj.imageUrl)
      ..writeByte(11)
      ..write(obj.actionUrl)
      ..writeByte(12)
      ..write(obj.expiresAt)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 19;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.pickupAlert;
      case 1:
        return NotificationType.dropoffAlert;
      case 2:
        return NotificationType.emergencyAlert;
      case 3:
        return NotificationType.paymentStatus;
      case 4:
        return NotificationType.maintenanceAlert;
      case 5:
        return NotificationType.announcement;
      case 6:
        return NotificationType.incident;
      case 7:
        return NotificationType.report;
      case 8:
        return NotificationType.general;
      default:
        return NotificationType.pickupAlert;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.pickupAlert:
        writer.writeByte(0);
        break;
      case NotificationType.dropoffAlert:
        writer.writeByte(1);
        break;
      case NotificationType.emergencyAlert:
        writer.writeByte(2);
        break;
      case NotificationType.paymentStatus:
        writer.writeByte(3);
        break;
      case NotificationType.maintenanceAlert:
        writer.writeByte(4);
        break;
      case NotificationType.announcement:
        writer.writeByte(5);
        break;
      case NotificationType.incident:
        writer.writeByte(6);
        break;
      case NotificationType.report:
        writer.writeByte(7);
        break;
      case NotificationType.general:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationPriorityAdapter extends TypeAdapter<NotificationPriority> {
  @override
  final int typeId = 20;

  @override
  NotificationPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationPriority.low;
      case 1:
        return NotificationPriority.normal;
      case 2:
        return NotificationPriority.high;
      case 3:
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationPriority obj) {
    switch (obj) {
      case NotificationPriority.low:
        writer.writeByte(0);
        break;
      case NotificationPriority.normal:
        writer.writeByte(1);
        break;
      case NotificationPriority.high:
        writer.writeByte(2);
        break;
      case NotificationPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
