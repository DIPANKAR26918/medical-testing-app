import '../models/medical_test.dart';

List<MedicalTestSearchResult> enforceSingleLetterPrefixResults(
  String query,
  Iterable<MedicalTestSearchResult> results,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.runes.length != 1) {
    return List<MedicalTestSearchResult>.unmodifiable(results);
  }

  return List<MedicalTestSearchResult>.unmodifiable(
    results.where((result) {
      return result.test.displayName.trim().toLowerCase().startsWith(normalized);
    }),
  );
}
