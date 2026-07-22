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
    this.locationSource = 'manual',
    this.provider,
    this.providerPlaceId,
    this.plusCode,
    this.accuracyMeters,
    this.distanceFromDeviceMeters,
    this.validationStatus = 'unverified',
    this.geocodedAt,
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
  final String locationSource;
  final String? provider;
  final String? providerPlaceId;
  final String? plusCode;
  final double? accuracyMeters;
  final double? distanceFromDeviceMeters;
  final String validationStatus;
  final DateTime? geocodedAt;
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
  bool get hasCoordinates => latitude != null && longitude != null;

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
    String? locationSource,
    String? provider,
    String? providerPlaceId,
    String? plusCode,
    double? accuracyMeters,
    double? distanceFromDeviceMeters,
    String? validationStatus,
    DateTime? geocodedAt,
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
      locationSource: locationSource ?? this.locationSource,
      provider: provider ?? this.provider,
      providerPlaceId: providerPlaceId ?? this.providerPlaceId,
      plusCode: plusCode ?? this.plusCode,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      distanceFromDeviceMeters:
          distanceFromDeviceMeters ?? this.distanceFromDeviceMeters,
      validationStatus: validationStatus ?? this.validationStatus,
      geocodedAt: geocodedAt ?? this.geocodedAt,
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
      'location_source': locationSource,
      'provider': _clean(provider),
      'provider_place_id': _clean(providerPlaceId),
      'plus_code': _clean(plusCode),
      'accuracy_meters': accuracyMeters,
      'distance_from_device_meters': distanceFromDeviceMeters,
      'validation_status': validationStatus,
      'geocoded_at': geocodedAt?.toUtc().toIso8601String(),
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
      'locationSource': locationSource,
      'provider': provider,
      'providerPlaceId': providerPlaceId,
      'plusCode': plusCode,
      'accuracyMeters': accuracyMeters,
      'distanceFromDeviceMeters': distanceFromDeviceMeters,
      'validationStatus': validationStatus,
      'geocodedAt': geocodedAt?.toIso8601String(),
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
      locationSource:
          _clean(map['locationSource'] ?? map['location_source']) ?? 'manual',
      provider: _clean(map['provider']),
      providerPlaceId:
          _clean(map['providerPlaceId'] ?? map['provider_place_id']),
      plusCode: _clean(map['plusCode'] ?? map['plus_code']),
      accuracyMeters:
          _number(map['accuracyMeters'] ?? map['accuracy_meters']),
      distanceFromDeviceMeters: _number(
        map['distanceFromDeviceMeters'] ?? map['distance_from_device_meters'],
      ),
      validationStatus:
          _clean(map['validationStatus'] ?? map['validation_status']) ??
          'unverified',
      geocodedAt: DateTime.tryParse(
        (map['geocodedAt'] ?? map['geocoded_at'])?.toString() ?? '',
      ),
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
