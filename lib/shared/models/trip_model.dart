import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 8)
class TripModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String busId;

  @HiveField(2)
  final String routeId;

  @HiveField(3)
  final String driverId;

  @HiveField(4)
  final String busNumber;

  @HiveField(5)
  final String routeName;

  @HiveField(6)
  final TripType type;

  @HiveField(7)
  final TripStatus status;

  @HiveField(8)
  final List<String> childrenIds;

  @HiveField(9)
  final List<String> checkedInChildren;

  @HiveField(10)
  final DateTime startTime;

  @HiveField(11)
  final DateTime? endTime;

  @HiveField(12)
  final LocationData? currentLocation;

  @HiveField(13)
  final List<LocationData>? locationHistory;

  @HiveField(14)
  final int? estimatedDuration; // in minutes

  @HiveField(15)
  final double? actualDistance; // in kilometers

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final Map<String, dynamic>? metadata;

  TripModel({
    required this.id,
    required this.busId,
    required this.routeId,
    required this.driverId,
    required this.busNumber,
    required this.routeName,
    required this.type,
    this.status = TripStatus.active,
    required this.childrenIds,
    this.checkedInChildren = const [],
    required this.startTime,
    this.endTime,
    this.currentLocation,
    this.locationHistory,
    this.estimatedDuration,
    this.actualDistance,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] ?? '',
      busId: map['busId'] ?? '',
      routeId: map['routeId'] ?? '',
      driverId: map['driverId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeName: map['routeName'] ?? '',
      type: TripType.values.firstWhere(
        (e) => e.toString() == 'TripType.${map['type']}',
        orElse: () => TripType.pickup,
      ),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${map['status']}',
        orElse: () => TripStatus.active,
      ),
      childrenIds: map['childrenIds'] != null ? List<String>.from(map['childrenIds']) : [],
      checkedInChildren: map['checkedInChildren'] != null ? List<String>.from(map['checkedInChildren']) : [],
      startTime: map['startTime'] is Timestamp 
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.parse(map['startTime']),
      endTime: map['endTime'] is Timestamp 
          ? (map['endTime'] as Timestamp).toDate()
          : map['endTime'] != null 
              ? DateTime.parse(map['endTime'])
              : null,
      currentLocation: map['currentLocation'] != null 
          ? LocationData.fromMap(Map<String, dynamic>.from(map['currentLocation']))
          : null,
      locationHistory: map['locationHistory'] != null 
          ? (map['locationHistory'] as List<dynamic>)
              .map((location) => LocationData.fromMap(Map<String, dynamic>.from(location)))
              .toList()
          : null,
      estimatedDuration: map['estimatedDuration'],
      actualDistance: map['actualDistance']?.toDouble(),
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
      'busId': busId,
      'routeId': routeId,
      'driverId': driverId,
      'busNumber': busNumber,
      'routeName': routeName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'childrenIds': childrenIds,
      'checkedInChildren': checkedInChildren,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'currentLocation': currentLocation?.toMap(),
      'locationHistory': locationHistory?.map((location) => location.toMap()).toList(),
      'estimatedDuration': estimatedDuration,
      'actualDistance': actualDistance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  TripModel copyWith({
    String? id,
    String? busId,
    String? routeId,
    String? driverId,
    String? busNumber,
    String? routeName,
    TripType? type,
    TripStatus? status,
    List<String>? childrenIds,
    List<String>? checkedInChildren,
    DateTime? startTime,
    DateTime? endTime,
    LocationData? currentLocation,
    List<LocationData>? locationHistory,
    int? estimatedDuration,
    double? actualDistance,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TripModel(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      busNumber: busNumber ?? this.busNumber,
      routeName: routeName ?? this.routeName,
      type: type ?? this.type,
      status: status ?? this.status,
      childrenIds: childrenIds ?? this.childrenIds,
      checkedInChildren: checkedInChildren ?? this.checkedInChildren,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentLocation: currentLocation ?? this.currentLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDistance: actualDistance ?? this.actualDistance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActive => status == TripStatus.active;
  bool get isCompleted => status == TripStatus.completed;
  bool get isCancelled => status == TripStatus.cancelled;
  
  int get totalChildren => childrenIds.length;
  int get checkedInCount => checkedInChildren.length;
  int get remainingChildren => totalChildren - checkedInCount;
  
  double get completionPercentage => totalChildren > 0 ? (checkedInCount / totalChildren) * 100 : 0;
  
  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  String get statusDisplayName {
    switch (status) {
      case TripStatus.active:
        return 'Active';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.paused:
        return 'Paused';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case TripType.pickup:
        return 'Pickup';
      case TripType.dropoff:
        return 'Drop-off';
    }
  }
}

@HiveType(typeId: 9)
class LocationData extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double? accuracy;

  @HiveField(4)
  final double? speed;

  @HiveField(5)
  final double? heading;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      accuracy: map['accuracy']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
    };
  }
}

@HiveType(typeId: 10)
enum TripType {
  @HiveField(0)
  pickup,

  @HiveField(1)
  dropoff,
}

@HiveType(typeId: 11)
enum TripStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  completed,

  @HiveField(2)
  cancelled,

  @HiveField(3)
  paused,
}
