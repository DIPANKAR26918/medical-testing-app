import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collection address sheet exposes only the two supported entry paths', () {
    final sheet = File(
      'lib/widgets/location_selector_sheet_v5.dart',
    ).readAsStringSync();

    expect(_occurrences(sheet, ": 'Use current location',"), 1);
    expect(_occurrences(sheet, "title: 'Enter address manually'"), 1);
    expect(sheet, isNot(contains('Search area or landmark')));
    expect(sheet, isNot(contains('openLocationMapPicker')));
    expect(sheet, isNot(contains('location_map_picker_screen')));
    expect(
      sheet,
      contains('Location permission is requested only after you tap'),
    );
  });

  test('current location continues through editable address confirmation', () {
    final sheet = File(
      'lib/widgets/location_selector_sheet_v5.dart',
    ).readAsStringSync();
    final form = File(
      'lib/screens/manual_collection_address_screen.dart',
    ).readAsStringSync();

    expect(sheet, contains('requestPermission()'));
    expect(sheet, contains('reverseGeocodeCoordinates('));
    expect(
      sheet,
      contains('openManualCollectionAddressScreen(\n'
          '        context,\n'
          '        initialLocation: readable,'),
    );
    expect(form, contains('Confirm collection address'));
    expect(form, contains('Current area detected'));
    expect(form, isNot(contains('Exact collection pin')));
  });

  test('opening the home card never requests location automatically', () {
    final card = File('lib/widgets/location_card.dart').readAsStringSync();

    expect(card, contains('loadSavedLocation()'));
    expect(card, isNot(contains('resolveDevicePosition(')));
    expect(card, isNot(contains('requestPermission(')));
    expect(card, isNot(contains('beginInitialLocationBootstrap(')));
  });

  test('Google Maps client and provider search are removed', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final iosDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(pubspec, isNot(contains('google_maps_flutter')));
    expect(androidManifest, isNot(contains('com.google.android.geo.API_KEY')));
    expect(androidBuild, isNot(contains('MAPS_API_KEY')));
    expect(iosDelegate, isNot(contains('GoogleMaps')));
    expect(iosInfo, isNot(contains('GoogleMapsAPIKey')));
    expect(
      File('lib/screens/location_map_picker_screen.dart').existsSync(),
      isFalse,
    );
    expect(
      File('supabase/functions/location-intelligence/index.ts').existsSync(),
      isFalse,
    );
  });

  test('saved-address ownership and default-selection contract is preserved', () {
    final service =
        File('lib/services/location_service.dart').readAsStringSync();

    expect(service, contains(".from('collection_addresses')"));
    expect(service, contains(".eq('user_id', userId)"));
    expect(service, contains("'set_default_collection_address'"));
    expect(service, contains("'delete_collection_address'"));
    expect(service, contains("String source = 'gps'"));
  });
}

int _occurrences(String source, String value) {
  return value.allMatches(source).length;
}
