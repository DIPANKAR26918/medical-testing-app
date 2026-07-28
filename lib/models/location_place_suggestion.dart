class LocationPlaceSuggestion {
  const LocationPlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    this.distanceMeters,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final double? distanceMeters;

  factory LocationPlaceSuggestion.fromMap(Map<String, dynamic> map) {
    return LocationPlaceSuggestion(
      placeId: map['place_id']?.toString().trim() ?? '',
      primaryText: map['primary_text']?.toString().trim() ?? '',
      secondaryText: map['secondary_text']?.toString().trim() ?? '',
      distanceMeters: _number(map['distance_meters']),
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
