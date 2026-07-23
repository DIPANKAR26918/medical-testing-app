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
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
              sliver: SliverList.list(
                children: [
                  _Hero(test: test, style: style),
                  const SizedBox(height: 12),
                  _Essentials(test: test, style: style),
                  const SizedBox(height: 12),
                  _MoreInformation(test: test, style: style),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.accent.withValues(alpha: .13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MedicalTestIconBadge(test: test, size: 48),
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
                        _Chip(label: test.testTypeLabel, color: style.accent),
                        if (test.isPopular)
                          const _Chip(
                            label: 'Popular',
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
          const SizedBox(height: 18),
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
            const SizedBox(height: 7),
            Text(
              'Lab name: ${test.nameSheet}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.2,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 17),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: .72),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Price',
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
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

class _Essentials extends StatelessWidget {
  const _Essentials({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final preparation = test.preparation?.trim();
    final hasPreparation = preparation?.isNotEmpty == true;
    final facts = <_Fact>[
      _Fact(
        test.labVisitRequired
            ? Icons.apartment_rounded
            : Icons.home_work_outlined,
        'Collection',
        test.labVisitRequired
            ? 'Lab visit required'
            : test.homeCollectionAvailable
            ? 'Home sample collection available'
            : 'Confirm at booking',
      ),
      _Fact(Icons.science_outlined, 'Sample', test.sampleLabel),
      _Fact(Icons.schedule_rounded, 'Report', test.reportLabel),
      _Fact(
        Icons.format_list_bulleted_rounded,
        'Test type',
        test.parameterCount == null
            ? test.testTypeLabel
            : '${test.parameterCount} parameters',
      ),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            icon: Icons.fact_check_outlined,
            title: 'Everything you need to know',
            style: style,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final fact in facts)
                    SizedBox(
                      width: width,
                      child: _FactTile(fact: fact, style: style),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.restaurant_outlined,
            title: 'Preparation',
            value: hasPreparation
                ? preparation!
                : 'No special preparation listed.',
            support: hasPreparation
                ? null
                : 'Confirm fasting and medicine instructions while booking.',
            style: style,
          ),
          if (test.ageAndGenderLabel != null) ...[
            const SizedBox(height: 13),
            _SummaryRow(
              icon: Icons.people_alt_outlined,
              title: 'Recommended for',
              value: test.ageAndGenderLabel!,
              style: style,
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact, required this.style});

  final _Fact fact;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: fact.icon, style: style, size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact.value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11.8,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.style,
    this.support,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? support;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBox(icon: icon, style: style),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.5,
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (support != null) ...[
                const SizedBox(height: 3),
                Text(
                  support!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreInformation extends StatelessWidget {
  const _MoreInformation({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final purpose = test.purpose?.trim();
    final hasPurpose = purpose?.isNotEmpty == true;
    final hasSampleDetails =
        (test.sampleTypeVolume?.trim().isNotEmpty ?? false) ||
        (test.sampleCollectionNote?.trim().isNotEmpty ?? false) ||
        test.specialHandlingRequired;
    final hasTechnicalDetails =
        (test.testCode?.trim().isNotEmpty ?? false) ||
        (test.bodySystem?.trim().isNotEmpty ?? false);
    final sections = <_InfoSection>[];

    if (hasPurpose) {
      sections.add(
        _InfoSection(
          icon: Icons.biotech_outlined,
          title: 'What this test checks',
          summary: purpose!,
          child: Text(
            purpose,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12.7,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (hasSampleDetails) {
      sections.add(
        _InfoSection(
          icon: Icons.water_drop_outlined,
          title: 'Sample & collection',
          summary:
              test.sampleTypeVolume ??
              test.sampleCollectionNote ??
              'Special handling required',
          child: Column(
            children: [
              if (test.sampleTypeVolume != null)
                _DetailLine('Volume / type', test.sampleTypeVolume!),
              if (test.sampleTypeVolume != null &&
                  (test.sampleCollectionNote != null ||
                      test.specialHandlingRequired))
                const SizedBox(height: 11),
              if (test.sampleCollectionNote != null)
                _DetailLine('Collection note', test.sampleCollectionNote!),
              if (test.sampleCollectionNote != null &&
                  test.specialHandlingRequired)
                const SizedBox(height: 11),
              if (test.specialHandlingRequired)
                const _DetailLine(
                  'Handling',
                  'Special sample handling is required for this test.',
                ),
            ],
          ),
        ),
      );
    }

    if (test.includedParameters.isNotEmpty) {
      sections.add(
        _InfoSection(
          icon: Icons.checklist_rounded,
          title: 'Included parameters',
          summary: '${test.includedParameters.length} items listed',
          child: Wrap(
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
                    color: style.soft.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: style.accent.withValues(alpha: .10),
                    ),
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
        ),
      );
    }

    if (hasTechnicalDetails) {
      sections.add(
        _InfoSection(
          icon: Icons.info_outline_rounded,
          title: 'Technical information',
          summary: test.testCode == null
              ? test.bodySystem!
              : 'Code ${test.testCode}',
          child: Column(
            children: [
              if (test.testCode != null)
                _DetailLine('Test code', test.testCode!),
              if (test.testCode != null && test.bodySystem != null)
                const SizedBox(height: 11),
              if (test.bodySystem != null)
                _DetailLine('Body system', test.bodySystem!),
            ],
          ),
        ),
      );
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _Heading(
              icon: Icons.subject_rounded,
              title: 'More information',
              style: style,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          for (var index = 0; index < sections.length; index++) ...[
            _InfoTile(section: sections[index], style: style),
            if (index != sections.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFE8EDF4),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.summary,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String summary;
  final Widget child;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.section, required this.style});

  final _InfoSection section;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: _IconBox(icon: section.icon, style: style),
        title: Text(
          section.title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          section.summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.3,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Align(alignment: Alignment.centerLeft, child: section.child),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

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

class _Heading extends StatelessWidget {
  const _Heading({
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
        _IconBox(icon: icon, style: style),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.style, this.size = 34});

  final IconData icon;
  final MedicalTestCategoryStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.soft,
        borderRadius: BorderRadius.circular(size < 34 ? 10 : 11),
      ),
      child: Icon(icon, size: size < 34 ? 16 : 18, color: style.accent),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.3,
              height: 1.4,
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
              fontSize: 12.4,
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: accent, size: 19),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Use these details for booking guidance. Your doctor’s prescription and the lab’s final instructions take priority.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 11.7,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
