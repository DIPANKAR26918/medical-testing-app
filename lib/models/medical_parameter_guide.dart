class MedicalParameterGuide {
  const MedicalParameterGuide({
    required this.displayName,
    required this.whatItIs,
    required this.whyItMatters,
    required this.howToReadIt,
    required this.sourceLabel,
    required this.sourceUrl,
  });

  final String displayName;
  final String whatItIs;
  final String whyItMatters;
  final String howToReadIt;
  final String sourceLabel;
  final String sourceUrl;

  factory MedicalParameterGuide.fromJson(Map<String, dynamic> json) {
    return MedicalParameterGuide(
      displayName: _requiredText(json, 'display_name'),
      whatItIs: _requiredText(json, 'what_it_is'),
      whyItMatters: _requiredText(json, 'why_it_matters'),
      howToReadIt: _requiredText(json, 'how_to_read_it'),
      sourceLabel: _requiredText(json, 'source_label'),
      sourceUrl: _requiredText(json, 'source_url'),
    );
  }

  static String _requiredText(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw FormatException('Parameter guide is missing $key.');
    }
    return value;
  }
}
