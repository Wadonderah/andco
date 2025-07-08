import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'trip_model.dart';

part 'checkin_model.g.dart';

@HiveType(typeId: 12)
class CheckinModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final String childId;

  @HiveField(3)
  final String childName;

  @HiveField(4)
  final String stopId;

  @HiveField(5)
  final String driverId;

  @HiveField(6)
  final String busId;

  @HiveField(7)
  final String routeId;

  @HiveField(8)
  final CheckinMethod method;

  @HiveField(9)
  final String? photoUrl;

  @HiveField(10)
  final DateTime timestamp;

  @HiveField(11)
  final LocationData? location;

  @HiveField(12)
  final CheckinStatus status;

  @HiveField(13)
  final String? notes;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final Map<String, dynamic>? metadata;

  CheckinModel({
    required this.id,
    required this.tripId,
    required this.childId,
    required this.childName,
    required this.stopId,
    required this.driverId,
    required this.busId,
    required this.routeId,
    required this.method,
    this.photoUrl,
    required this.timestamp,
    this.location,
    this.status = CheckinStatus.confirmed,
    this.notes,
    required this.createdAt,
    this.metadata,
  });

  factory CheckinModel.fromMap(Map<String, dynamic> map) {
    return CheckinModel(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      stopId: map['stopId'] ?? '',
      driverId: map['driverId'] ?? '',
      busId: map['busId'] ?? '',
      routeId: map['routeId'] ?? '',
      method: CheckinMethod.values.firstWhere(
        (e) => e.toString() == 'CheckinMethod.${map['method']}',
        orElse: () => CheckinMethod.manual,
      ),
      photoUrl: map['photoUrl'],
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      location: map['location'] != null 
          ? LocationData.fromMap(Map<String, dynamic>.from(map['location']))
          : null,
      status: CheckinStatus.values.firstWhere(
        (e) => e.toString() == 'CheckinStatus.${map['status']}',
        orElse: () => CheckinStatus.confirmed,
      ),
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'childId': childId,
      'childName': childName,
      'stopId': stopId,
      'driverId': driverId,
      'busId': busId,
      'routeId': routeId,
      'method': method.toString().split('.').last,
      'photoUrl': photoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location?.toMap(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  CheckinModel copyWith({
    String? id,
    String? tripId,
    String? childId,
    String? childName,
    String? stopId,
    String? driverId,
    String? busId,
    String? routeId,
    CheckinMethod? method,
    String? photoUrl,
    DateTime? timestamp,
    LocationData? location,
    CheckinStatus? status,
    String? notes,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return CheckinModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      stopId: stopId ?? this.stopId,
      driverId: driverId ?? this.driverId,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      method: method ?? this.method,
      photoUrl: photoUrl ?? this.photoUrl,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasLocation => location != null;
  bool get isConfirmed => status == CheckinStatus.confirmed;
  bool get isPending => status == CheckinStatus.pending;
  bool get isCancelled => status == CheckinStatus.cancelled;

  String get methodDisplayName {
    switch (method) {
      case CheckinMethod.manual:
        return 'Manual';
      case CheckinMethod.qr:
        return 'QR Code';
      case CheckinMethod.faceId:
        return 'Face ID';
      case CheckinMethod.nfc:
        return 'NFC';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CheckinStatus.confirmed:
        return 'Confirmed';
      case CheckinStatus.pending:
        return 'Pending';
      case CheckinStatus.cancelled:
        return 'Cancelled';
    }
  }
}

@HiveType(typeId: 13)
enum CheckinMethod {
  @HiveField(0)
  manual,

  @HiveField(1)
  qr,

  @HiveField(2)
  faceId,

  @HiveField(3)
  nfc,
}

@HiveType(typeId: 14)
enum CheckinStatus {
  @HiveField(0)
  confirmed,

  @HiveField(1)
  pending,

  @HiveField(2)
  cancelled,
}
