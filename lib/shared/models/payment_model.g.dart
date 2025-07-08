// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 15;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      schoolId: fields[2] as String,
      amount: fields[3] as double,
      currency: fields[4] as String,
      status: fields[5] as PaymentStatus,
      paymentMethod: fields[6] as PaymentMethod,
      stripePaymentIntentId: fields[7] as String?,
      mpesaReceiptNumber: fields[8] as String?,
      phoneNumber: fields[9] as String?,
      checkoutRequestId: fields[10] as String?,
      description: fields[11] as String,
      completedAt: fields[12] as DateTime?,
      failedAt: fields[13] as DateTime?,
      cancelledAt: fields[14] as DateTime?,
      failureReason: fields[15] as String?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      metadata: (fields[18] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.schoolId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.stripePaymentIntentId)
      ..writeByte(8)
      ..write(obj.mpesaReceiptNumber)
      ..writeByte(9)
      ..write(obj.phoneNumber)
      ..writeByte(10)
      ..write(obj.checkoutRequestId)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.failedAt)
      ..writeByte(14)
      ..write(obj.cancelledAt)
      ..writeByte(15)
      ..write(obj.failureReason)
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
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 16;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.pending;
      case 1:
        return PaymentStatus.completed;
      case 2:
        return PaymentStatus.failed;
      case 3:
        return PaymentStatus.cancelled;
      case 4:
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.pending:
        writer.writeByte(0);
        break;
      case PaymentStatus.completed:
        writer.writeByte(1);
        break;
      case PaymentStatus.failed:
        writer.writeByte(2);
        break;
      case PaymentStatus.cancelled:
        writer.writeByte(3);
        break;
      case PaymentStatus.refunded:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 17;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.stripe;
      case 1:
        return PaymentMethod.mpesa;
      case 2:
        return PaymentMethod.bank;
      case 3:
        return PaymentMethod.cash;
      default:
        return PaymentMethod.stripe;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.stripe:
        writer.writeByte(0);
        break;
      case PaymentMethod.mpesa:
        writer.writeByte(1);
        break;
      case PaymentMethod.bank:
        writer.writeByte(2);
        break;
      case PaymentMethod.cash:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
