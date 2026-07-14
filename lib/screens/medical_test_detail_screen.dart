import 'package:flutter/material.dart';

import '../models/medical_test.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

class MedicalTestDetailScreen extends StatelessWidget {
  const MedicalTestDetailScreen({required this.test, super.key});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: const Text('Test details'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              sliver: SliverList.list(
                children: [
                  _DetailHero(test: test, style: style),
                  const SizedBox(height: 16),
                  _QuickFacts(test: test),
                  const SizedBox(height: 16),
                  if (test.purpose != null) ...[
                    _DetailSection(
                      icon: Icons.fact_check_outlined,
                      title: 'What this test checks',
                      body: test.purpose!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DetailSection(
                    icon: Icons.restaurant_outlined,
                    title: 'Preparation',
                    body:
                        test.preparation ??
                        'No preparation instruction is listed. Confirm fasting or medicine instructions when booking.',
                  ),
                  const SizedBox(height: 12),
                  _SampleSection(test: test),
                  if (test.includedParameters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ParametersSection(test: test),
                  ],
                  if (test.ageAndGenderLabel != null) ...[
                    const SizedBox(height: 12),
                    _DetailSection(
                      icon: Icons.people_alt_outlined,
                      title: 'Recommended for',
                      body: test.ageAndGenderLabel!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _TechnicalDetails(test: test),
                  const SizedBox(height: 12),
                  _MedicalNote(accent: style.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: style.accent.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeroChip(
                      label: test.category,
                      color: style.accent,
                      background: Colors.white.withValues(alpha: .72),
                    ),
                    if (test.isPopular)
                      const _HeroChip(
                        label: 'Popular',
                        color: Color(0xFF15803D),
                        background: Color(0xFFECFDF3),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            test.displayName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          if (test.hasDifferentOfficialName) ...[
            const SizedBox(height: 8),
            Text(
              test.nameSheet,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  test.priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      test.labVisitRequired
                          ? Icons.apartment_rounded
                          : Icons.home_work_outlined,
                      color: style.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      test.collectionLabel,
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FactCard(
            icon: Icons.science_outlined,
            label: 'Sample',
            value: test.sampleLabel,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _FactCard(
            icon: Icons.schedule_rounded,
            label: 'Report',
            value: test.reportLabel,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _FactCard(
            icon: Icons.format_list_bulleted_rounded,
            label: 'Type',
            value: test.parameterCount == null
                ? test.testTypeLabel
                : '${test.parameterCount} parameters',
          ),
        ),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF2563EB)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11.4,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleSection extends StatelessWidget {
  const _SampleSection({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 20,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 9),
              Text(
                'Sample & collection',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailFact(label: 'Sample', value: test.sampleLabel),
          if (test.sampleTypeVolume != null &&
              test.sampleTypeVolume != test.sampleLabel) ...[
            const SizedBox(height: 10),
            _DetailFact(label: 'Volume / type', value: test.sampleTypeVolume!),
          ],
          if (test.sampleCollectionNote != null) ...[
            const SizedBox(height: 10),
            _DetailFact(
              label: 'Collection note',
              value: test.sampleCollectionNote!,
            ),
          ],
          if (test.specialHandlingRequired) ...[
            const SizedBox(height: 10),
            const _DetailFact(
              label: 'Handling',
              value: 'Special sample handling is required for this test.',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailFact extends StatelessWidget {
  const _DetailFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParametersSection extends StatelessWidget {
  const _ParametersSection({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            test.parameterCount == null
                ? 'Included parameters'
                : '${test.parameterCount} included parameters',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final parameter in test.includedParameters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Text(
                    parameter,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test information',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (test.testCode != null) ...[
            _DetailFact(label: 'Test code', value: test.testCode!),
            const SizedBox(height: 10),
          ],
          if (test.bodySystem != null) ...[
            _DetailFact(label: 'Body system', value: test.bodySystem!),
            const SizedBox(height: 10),
          ],
          _DetailFact(label: 'Catalogue type', value: test.testTypeLabel),
          const SizedBox(height: 10),
          _DetailFact(label: 'Collection', value: test.collectionLabel),
        ],
      ),
    );
  }
}

class _MedicalNote extends StatelessWidget {
  const _MedicalNote({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: accent, size: 19),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Test information is for booking guidance, not diagnosis. Follow your doctor’s prescription and the lab’s final instructions.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
