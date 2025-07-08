import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'route_model.g.dart';

@HiveType(typeId: 5)
class RouteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String schoolId;

  @HiveField(3)
  final String? busId;

  @HiveField(4)
  final List<RouteStop> stops;

  @HiveField(5)
  final RouteType type;

  @HiveField(6)
  final DateTime startTime;

  @HiveField(7)
  final DateTime endTime;

  @HiveField(8)
  final int estimatedDuration; // in minutes

  @HiveField(9)
  final double distance; // in kilometers

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final List<String>? activeDays; // Monday, Tuesday, etc.

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  @HiveField(14)
  final Map<String, dynamic>? metadata;

  RouteModel({
    required this.id,
    required this.name,
    required this.schoolId,
    this.busId,
    required this.stops,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.estimatedDuration,
    required this.distance,
    this.isActive = true,
    this.activeDays,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      schoolId: map['schoolId'] ?? '',
      busId: map['busId'],
      stops: (map['stops'] as List<dynamic>?)
          ?.map((stop) => RouteStop.fromMap(Map<String, dynamic>.from(stop)))
          .toList() ?? [],
      type: RouteType.values.firstWhere(
        (e) => e.toString() == 'RouteType.${map['type']}',
        orElse: () => RouteType.pickup,
      ),
      startTime: map['startTime'] is Timestamp 
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.parse(map['startTime']),
      endTime: map['endTime'] is Timestamp 
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.parse(map['endTime']),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      distance: (map['distance'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      activeDays: map['activeDays'] != null ? List<String>.from(map['activeDays']) : null,
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
      'name': name,
      'schoolId': schoolId,
      'busId': busId,
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'type': type.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'estimatedDuration': estimatedDuration,
      'distance': distance,
      'isActive': isActive,
      'activeDays': activeDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  RouteModel copyWith({
    String? id,
    String? name,
    String? schoolId,
    String? busId,
    List<RouteStop>? stops,
    RouteType? type,
    DateTime? startTime,
    DateTime? endTime,
    int? estimatedDuration,
    double? distance,
    bool? isActive,
    List<String>? activeDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      busId: busId ?? this.busId,
      stops: stops ?? this.stops,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      distance: distance ?? this.distance,
      isActive: isActive ?? this.isActive,
      activeDays: activeDays ?? this.activeDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasBusAssigned => busId != null;
  int get stopCount => stops.length;
  bool get isActiveToday {
    if (activeDays == null) return true;
    final today = DateTime.now().weekday;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return activeDays!.contains(dayNames[today - 1]);
  }

  String get typeDisplayName {
    switch (type) {
      case RouteType.pickup:
        return 'Pickup Route';
      case RouteType.dropoff:
        return 'Drop-off Route';
      case RouteType.roundTrip:
        return 'Round Trip';
    }
  }
}

@HiveType(typeId: 6)
class RouteStop extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String address;

  @HiveField(5)
  final int order;

  @HiveField(6)
  final DateTime scheduledTime;

  @HiveField(7)
  final int estimatedWaitTime; // in minutes

  @HiveField(8)
  final List<String>? childrenIds;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final Map<String, dynamic>? metadata;

  RouteStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.order,
    required this.scheduledTime,
    this.estimatedWaitTime = 2,
    this.childrenIds,
    this.isActive = true,
    this.metadata,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      order: map['order'] ?? 0,
      scheduledTime: map['scheduledTime'] is Timestamp 
          ? (map['scheduledTime'] as Timestamp).toDate()
          : DateTime.parse(map['scheduledTime']),
      estimatedWaitTime: map['estimatedWaitTime'] ?? 2,
      childrenIds: map['childrenIds'] != null ? List<String>.from(map['childrenIds']) : null,
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'order': order,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'estimatedWaitTime': estimatedWaitTime,
      'childrenIds': childrenIds,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get hasChildren => childrenIds != null && childrenIds!.isNotEmpty;
  int get childrenCount => childrenIds?.length ?? 0;
}

@HiveType(typeId: 7)
enum RouteType {
  @HiveField(0)
  pickup,

  @HiveField(1)
  dropoff,

  @HiveField(2)
  roundTrip,
}
