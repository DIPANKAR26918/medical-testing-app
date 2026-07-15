import 'dart:convert';

enum LocationType { none, approximate, precise, manual }

enum LocationSelectionMode { approximate, precise }

class LocationData {
  const LocationData({
    required this.type,
    required this.displayAddress,
    this.id,
    this.label = 'Home',
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.locality,
    this.city,
    this.state,
    this.postalCode,
    this.countryCode = 'IN',
    this.recipientName,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.serviceabilityStatus = 'unverified',
    this.isDefault = false,
    this.updatedAt,
  });

  final String? id;
  final LocationType type;
  final String label;
  final String displayAddress;
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? locality;
  final String? city;
  final String? state;
  final String? postalCode;
  final String countryCode;
  final String? recipientName;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final String serviceabilityStatus;
  final bool isDefault;
  final DateTime? updatedAt;

  static const empty = LocationData(
    type: LocationType.none,
    displayAddress: '',
  );

  bool get isEmpty =>
      type == LocationType.none || displayAddress.trim().isEmpty;
  bool get isPrecise => type == LocationType.precise;
  bool get isApproximate => type == LocationType.approximate;
  bool get isManual => type == LocationType.manual;

  String get serviceabilityLabel {
    switch (serviceabilityStatus) {
      case 'serviceable':
        return 'Home collection available';
      case 'limited':
        return 'Limited slots in this area';
      case 'unavailable':
        return 'Home collection unavailable';
      default:
        return 'Slots checked at booking';
    }
  }

  LocationData copyWith({
    String? id,
    LocationType? type,
    String? label,
    String? displayAddress,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? locality,
    String? city,
    String? state,
    String? postalCode,
    String? countryCode,
    String? recipientName,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    String? serviceabilityStatus,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return LocationData(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      displayAddress: displayAddress ?? this.displayAddress,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceabilityStatus:
          serviceabilityStatus ?? this.serviceabilityStatus,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDatabaseMap(String userId) {
    return <String, dynamic>{
      'user_id': userId,
      'label': label.trim().isEmpty ? 'Home' : label.trim(),
      'location_type': type.name,
      'display_address': displayAddress.trim(),
      'address_line1': _clean(addressLine1),
      'address_line2': _clean(addressLine2),
      'landmark': _clean(landmark),
      'locality': _clean(locality),
      'city': _clean(city),
      'state': _clean(state),
      'postal_code': _clean(postalCode),
      'country_code': countryCode.trim().isEmpty ? 'IN' : countryCode.trim(),
      'recipient_name': _clean(recipientName),
      'phone_number': _clean(phoneNumber),
      'latitude': latitude,
      'longitude': longitude,
      'serviceability_status': serviceabilityStatus,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'label': label,
      'displayAddress': displayAddress,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'landmark': landmark,
      'locality': locality,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'countryCode': countryCode,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'serviceabilityStatus': serviceabilityStatus,
      'isDefault': isDefault,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] ?? map['location_type'];
    return LocationData(
      id: _clean(map['id']),
      type: _parseType(rawType),
      label: _clean(map['label']) ?? 'Home',
      displayAddress:
          _clean(map['displayAddress'] ?? map['display_address']) ?? '',
      addressLine1: _clean(map['addressLine1'] ?? map['address_line1']),
      addressLine2: _clean(map['addressLine2'] ?? map['address_line2']),
      landmark: _clean(map['landmark']),
      locality: _clean(map['locality']),
      city: _clean(map['city']),
      state: _clean(map['state']),
      postalCode: _clean(map['postalCode'] ?? map['postal_code']),
      countryCode:
          _clean(map['countryCode'] ?? map['country_code']) ?? 'IN',
      recipientName:
          _clean(map['recipientName'] ?? map['recipient_name']),
      phoneNumber: _clean(map['phoneNumber'] ?? map['phone_number']),
      latitude: _number(map['latitude']),
      longitude: _number(map['longitude']),
      serviceabilityStatus:
          _clean(
            map['serviceabilityStatus'] ?? map['serviceability_status'],
          ) ??
          'unverified',
      isDefault: map['isDefault'] == true || map['is_default'] == true,
      updatedAt: DateTime.tryParse(
        (map['updatedAt'] ?? map['updated_at'])?.toString() ?? '',
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LocationData.fromJson(String source) {
    return LocationData.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  static LocationType _parseType(dynamic value) {
    if (value is int && value >= 0 && value < LocationType.values.length) {
      return LocationType.values[value];
    }
    final text = value?.toString().trim().toLowerCase();
    return LocationType.values.firstWhere(
      (type) => type.name == text,
      orElse: () => text == null ? LocationType.none : LocationType.precise,
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
