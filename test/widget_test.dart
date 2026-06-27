import 'package:flutter_test/flutter_test.dart';

import 'package:medical_diagnostic_app/models/location_data.dart';

void main() {
  test('LocationData round-trips through JSON', () {
    final location = LocationData(
      type: LocationType.precise,
      displayAddress: '123 Main Street',
      latitude: 12.34,
      longitude: 56.78,
      updatedAt: DateTime.utc(2024, 1, 1),
    );

    final restored = LocationData.fromJson(location.toJson());

    expect(restored.displayAddress, '123 Main Street');
    expect(restored.latitude, 12.34);
    expect(restored.longitude, 56.78);
    expect(restored.isPrecise, isTrue);
  });
}
