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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
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
                  const SizedBox(height: 14),
                  _CollectionBanner(test: test, style: style),
                  const SizedBox(height: 18),
                  const _SectionHeading(
                    eyebrow: 'AT A GLANCE',
                    title: 'Everything you need to know',
                  ),
                  const SizedBox(height: 11),
                  _QuickFacts(test: test, style: style),
                  const SizedBox(height: 18),
                  if (test.purpose != null) ...[
                    _DetailSection(
                      icon: Icons.fact_check_outlined,
                      title: 'What this test checks',
                      body: test.purpose!,
                      style: style,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DetailSection(
                    icon: Icons.restaurant_outlined,
                    title: 'Before your test',
                    body:
                        test.preparation ??
                        'No special preparation is listed. Confirm fasting and medicine instructions while booking.',
                    style: style,
                  ),
                  const SizedBox(height: 12),
                  _SampleSection(test: test, style: style),
                  if (test.includedParameters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ParametersSection(test: test, style: style),
                  ],
                  if (test.ageAndGenderLabel != null) ...[
                    const SizedBox(height: 12),
                    _DetailSection(
                      icon: Icons.people_alt_outlined,
                      title: 'Recommended for',
                      body: test.ageAndGenderLabel!,
                      style: style,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _TechnicalDetails(test: test, style: style),
                  const SizedBox(height: 14),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: style.accent.withValues(alpha: .13)),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: .07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -62,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: .055),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MedicalTestIconBadge(test: test, size: 58),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: style.accent,
                              fontSize: 10.5,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _HeroChip(
                                label: test.parameterCount == null
                                    ? test.testTypeLabel
                                    : '${test.parameterCount} parameters',
                                color: style.accent,
                              ),
                              if (test.isPopular)
                                const _HeroChip(
                                  label: 'Popular choice',
                                  color: Color(0xFFB45309),
                                  icon: Icons.local_fire_department_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  test.displayName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    height: 1.14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                if (test.hasDifferentOfficialName) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lab name: ${test.nameSheet}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.3,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 19),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: .78),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Test price',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      test.priceLabel,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final requiresLab = test.labVisitRequired;
    final icon = requiresLab
        ? Icons.apartment_rounded
        : Icons.home_work_outlined;
    final title = requiresLab
        ? 'This test requires a lab visit'
        : test.homeCollectionAvailable
        ? 'Home sample collection available'
        : 'Collection availability is confirmed at booking';
    final subtitle = requiresLab
        ? 'Visit requirements will be confirmed before booking.'
        : 'A trained professional can collect the required sample.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: requiresLab ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: requiresLab
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF15803D),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_rounded, color: style.accent, size: 20),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
      ],
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final facts = [
      _FactData(Icons.science_outlined, 'Sample', test.sampleLabel),
      _FactData(Icons.schedule_rounded, 'Report', test.reportLabel),
      _FactData(
        Icons.format_list_bulleted_rounded,
        'Test type',
        test.parameterCount == null
            ? test.testTypeLabel
            : '${test.parameterCount} parameters',
      ),
      _FactData(
        Icons.badge_outlined,
        'Test code',
        test.testCode ?? 'Confirmed at booking',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final fact in facts)
              SizedBox(
                width: width,
                child: _FactCard(fact: fact, style: style),
              ),
          ],
        );
      },
    );
  }
}

class _FactData {
  const _FactData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact, required this.style});

  final _FactData fact;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: style.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fact.icon, size: 17, color: style.accent),
          ),
          const SizedBox(height: 10),
          Text(
            fact.label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11.6,
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
    required this.style,
  });

  final IconData icon;
  final String title;
  final String body;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return _DetailSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SurfaceHeading(icon: icon, title: title, style: style),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.52,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleSection extends StatelessWidget {
  const _SampleSection({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return _DetailSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SurfaceHeading(
            icon: Icons.water_drop_outlined,
            title: 'Sample & collection',
            style: style,
          ),
          const SizedBox(height: 14),
          _DetailFact(label: 'Sample', value: test.sampleLabel),
          if (test.sampleTypeVolume != null &&
              test.sampleTypeVolume != test.sampleLabel) ...[
            const SizedBox(height: 11),
            _DetailFact(label: 'Volume / type', value: test.sampleTypeVolume!),
          ],
          if (test.sampleCollectionNote != null) ...[
            const SizedBox(height: 11),
            _DetailFact(
              label: 'Collection note',
              value: test.sampleCollectionNote!,
            ),
          ],
          if (test.specialHandlingRequired) ...[
            const SizedBox(height: 11),
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

class _ParametersSection extends StatelessWidget {
  const _ParametersSection({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return _ExpandableSurface(
      icon: Icons.checklist_rounded,
      style: style,
      title: test.parameterCount == null
          ? 'Included parameters'
          : '${test.parameterCount} included parameters',
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final parameter in test.includedParameters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: style.soft.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: style.accent.withValues(alpha: .10)),
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
    );
  }
}

class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return _ExpandableSurface(
      icon: Icons.info_outline_rounded,
      style: style,
      title: 'Test information',
      initiallyExpanded: false,
      child: Column(
        children: [
          if (test.testCode != null) ...[
            _DetailFact(label: 'Test code', value: test.testCode!),
            const SizedBox(height: 11),
          ],
          if (test.bodySystem != null) ...[
            _DetailFact(label: 'Body system', value: test.bodySystem!),
            const SizedBox(height: 11),
          ],
          _DetailFact(label: 'Catalogue type', value: test.testTypeLabel),
          const SizedBox(height: 11),
          _DetailFact(label: 'Collection', value: test.collectionLabel),
        ],
      ),
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: child,
    );
  }
}

class _SurfaceHeading extends StatelessWidget {
  const _SurfaceHeading({
    required this.icon,
    required this.title,
    required this.style,
  });

  final IconData icon;
  final String title;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: style.soft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: style.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandableSurface extends StatelessWidget {
  const _ExpandableSurface({
    required this.icon,
    required this.style,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final MedicalTestCategoryStyle style;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: style.soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: style.accent),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [Align(alignment: Alignment.centerLeft, child: child)],
        ),
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
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          Icon(Icons.health_and_safety_outlined, color: accent, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This information supports booking and does not replace medical advice. Follow your doctor’s prescription and the lab’s final instructions.',
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
