import '../models/location_data.dart';

final RegExp _plusCodePattern = RegExp(
  r'\b[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}\b',
  caseSensitive: false,
);

String stripLocationCodes(String value) {
  final parts = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(',')
      .map((part) => part.replaceAll(_plusCodePattern, '').trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  return parts.join(', ');
}

String locationDisplayTitle(LocationData location) {
  final addressLine = stripLocationCodes(location.addressLine1 ?? '');
  if (_isUseful(addressLine)) return addressLine.split(',').first.trim();

  final landmark = stripLocationCodes(location.landmark ?? '');
  if (_isUseful(landmark)) return landmark;

  final locality = stripLocationCodes(location.locality ?? '');
  if (_isUseful(locality)) return locality;

  final city = stripLocationCodes(location.city ?? '');
  if (_isUseful(city)) return city;

  final readable = locationReadableAddress(location);
  return readable.isEmpty
      ? 'Choose collection address'
      : readable.split(',').first.trim();
}

String locationReadableAddress(LocationData location) {
  final direct = stripLocationCodes(location.displayAddress);
  if (_isUseful(direct) && direct.toLowerCase() != 'pinned location') {
    return direct;
  }

  return _uniqueJoin([
    stripLocationCodes(location.landmark ?? ''),
    stripLocationCodes(location.locality ?? ''),
    stripLocationCodes(location.city ?? ''),
    stripLocationCodes(location.state ?? ''),
    stripLocationCodes(location.postalCode ?? ''),
  ]);
}

String landmarkPhrase(String value) {
  final clean = stripLocationCodes(value);
  if (clean.isEmpty) return '';
  final lower = clean.toLowerCase();
  const prefixes = [
    'near ',
    'beside ',
    'opposite ',
    'inside ',
    'behind ',
    'in front of ',
    'down the road from ',
    'around the corner from ',
  ];
  if (prefixes.any(lower.startsWith)) return clean;
  return 'Near $clean';
}

String _uniqueJoin(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in values) {
    final value = raw.trim();
    if (!_isUseful(value)) continue;
    final key = value.toLowerCase();
    if (seen.add(key)) result.add(value);
  }
  return result.join(', ');
}

bool _isUseful(String value) {
  final clean = value.trim();
  if (clean.isEmpty || _plusCodePattern.hasMatch(clean)) return false;
  return !RegExp(r'^[-+]?\d+(?:\.\d+)?\s*[,/]\s*[-+]?\d+(?:\.\d+)?$')
      .hasMatch(clean);
}
