import 'dart:convert';

enum LocationType { none, approximate, precise }

enum LocationSelectionMode { approximate, precise }

class LocationData {
  final LocationType type;
  final String displayAddress;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  const LocationData({
    required this.type,
    required this.displayAddress,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  static const empty = LocationData(
    type: LocationType.none,
    displayAddress: '',
  );

  bool get isEmpty =>
      type == LocationType.none || displayAddress.trim().isEmpty;

  bool get isPrecise => type == LocationType.precise;
  bool get isApproximate => type == LocationType.approximate;

  LocationData copyWith({
    LocationType? type,
    String? displayAddress,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return LocationData(
      type: type ?? this.type,
      displayAddress: displayAddress ?? this.displayAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'displayAddress': displayAddress,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      type: LocationType.values[map['type'] as int? ?? 0],
      displayAddress: map['displayAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LocationData.fromJson(String source) {
    return LocationData.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
