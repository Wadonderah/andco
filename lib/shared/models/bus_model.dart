import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'bus_model.g.dart';

@HiveType(typeId: 3)
class BusModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String busNumber;

  @HiveField(2)
  final String licensePlate;

  @HiveField(3)
  final String schoolId;

  @HiveField(4)
  final String? driverId;

  @HiveField(5)
  final int capacity;

  @HiveField(6)
  final String model;

  @HiveField(7)
  final String manufacturer;

  @HiveField(8)
  final int year;

  @HiveField(9)
  final String? color;

  @HiveField(10)
  final BusStatus status;

  @HiveField(11)
  final DateTime? lastMaintenanceDate;

  @HiveField(12)
  final DateTime? nextMaintenanceDate;

  @HiveField(13)
  final double? currentLatitude;

  @HiveField(14)
  final double? currentLongitude;

  @HiveField(15)
  final DateTime? lastLocationUpdate;

  @HiveField(16)
  final List<String>? features;

  @HiveField(17)
  final bool isActive;

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
  final DateTime updatedAt;

  @HiveField(20)
  final Map<String, dynamic>? metadata;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.licensePlate,
    required this.schoolId,
    this.driverId,
    required this.capacity,
    required this.model,
    required this.manufacturer,
    required this.year,
    this.color,
    this.status = BusStatus.inactive,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.features,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] ?? '',
      busNumber: map['busNumber'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      schoolId: map['schoolId'] ?? '',
      driverId: map['driverId'],
      capacity: map['capacity'] ?? 0,
      model: map['model'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'],
      status: BusStatus.values.firstWhere(
        (e) => e.toString() == 'BusStatus.${map['status']}',
        orElse: () => BusStatus.inactive,
      ),
      lastMaintenanceDate: map['lastMaintenanceDate'] is Timestamp 
          ? (map['lastMaintenanceDate'] as Timestamp).toDate()
          : map['lastMaintenanceDate'] != null 
              ? DateTime.parse(map['lastMaintenanceDate'])
              : null,
      nextMaintenanceDate: map['nextMaintenanceDate'] is Timestamp 
          ? (map['nextMaintenanceDate'] as Timestamp).toDate()
          : map['nextMaintenanceDate'] != null 
              ? DateTime.parse(map['nextMaintenanceDate'])
              : null,
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),
      lastLocationUpdate: map['lastLocationUpdate'] is Timestamp 
          ? (map['lastLocationUpdate'] as Timestamp).toDate()
          : map['lastLocationUpdate'] != null 
              ? DateTime.parse(map['lastLocationUpdate'])
              : null,
      features: map['features'] != null ? List<String>.from(map['features']) : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busNumber': busNumber,
      'licensePlate': licensePlate,
      'schoolId': schoolId,
      'driverId': driverId,
      'capacity': capacity,
      'model': model,
      'manufacturer': manufacturer,
      'year': year,
      'color': color,
      'status': status.toString().split('.').last,
      'lastMaintenanceDate': lastMaintenanceDate != null 
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'nextMaintenanceDate': nextMaintenanceDate != null 
          ? Timestamp.fromDate(nextMaintenanceDate!)
          : null,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'lastLocationUpdate': lastLocationUpdate != null 
          ? Timestamp.fromDate(lastLocationUpdate!)
          : null,
      'features': features,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  BusModel copyWith({
    String? id,
    String? busNumber,
    String? licensePlate,
    String? schoolId,
    String? driverId,
    int? capacity,
    String? model,
    String? manufacturer,
    int? year,
    String? color,
    BusStatus? status,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    List<String>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BusModel(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      schoolId: schoolId ?? this.schoolId,
      driverId: driverId ?? this.driverId,
      capacity: capacity ?? this.capacity,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      year: year ?? this.year,
      color: color ?? this.color,
      status: status ?? this.status,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasDriver => driverId != null;
  bool get hasLocation => currentLatitude != null && currentLongitude != null;
  bool get isOperational => status == BusStatus.active || status == BusStatus.inTransit;
  bool get needsMaintenance => nextMaintenanceDate != null && 
      DateTime.now().isAfter(nextMaintenanceDate!);

  String get statusDisplayName {
    switch (status) {
      case BusStatus.active:
        return 'Active';
      case BusStatus.inactive:
        return 'Inactive';
      case BusStatus.inTransit:
        return 'In Transit';
      case BusStatus.maintenance:
        return 'Under Maintenance';
      case BusStatus.outOfService:
        return 'Out of Service';
    }
  }
}

@HiveType(typeId: 4)
enum BusStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  inactive,

  @HiveField(2)
  inTransit,

  @HiveField(3)
  maintenance,

  @HiveField(4)
  outOfService,
}
