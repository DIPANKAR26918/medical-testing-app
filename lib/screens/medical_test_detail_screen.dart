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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
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
                  _TestHeader(test: test, style: style),
                  const SizedBox(height: 12),
                  _AtAGlance(test: test, style: style),
                  const SizedBox(height: 12),
                  _MoreDetails(test: test, style: style),
                  const SizedBox(height: 16),
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

class _TestHeader extends StatelessWidget {
  const _TestHeader({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final collectionLabel = test.labVisitRequired
        ? 'Lab visit'
        : test.homeCollectionAvailable
        ? 'Home collection'
        : 'Collection at booking';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 44),
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
                        fontSize: 10.2,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .65,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      test.displayName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (test.hasDifferentOfficialName) ...[
            const SizedBox(height: 8),
            Text(
              'Lab name: ${test.nameSheet}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.8,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Tag(label: test.testTypeLabel, color: style.accent),
                    _Tag(
                      label: collectionLabel,
                      color: test.labVisitRequired
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF15803D),
                    ),
                    if (test.isPopular)
                      const _Tag(
                        label: 'Popular',
                        color: Color(0xFFB45309),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    test.priceLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.2,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AtAGlance extends StatelessWidget {
  const _AtAGlance({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final preparation = test.preparation?.trim();
    final hasPreparation = preparation?.isNotEmpty == true;
    final purpose = test.purpose?.trim();
    final hasPurpose = purpose?.isNotEmpty == true;

    final facts = <_Fact>[
      _Fact(
        'Collection',
        test.labVisitRequired
            ? 'Lab visit required'
            : test.homeCollectionAvailable
            ? 'Home sample collection available'
            : 'Confirm availability while booking',
      ),
      _Fact('Report', test.reportLabel),
      _Fact('Sample', test.sampleLabel),
      _Fact(
        'Preparation',
        hasPreparation ? preparation! : 'No special preparation listed',
      ),
      _Fact(
        'Test type',
        test.parameterCount == null
            ? test.testTypeLabel
            : '${test.parameterCount} parameters',
      ),
      if (test.ageAndGenderLabel != null)
        _Fact('Recommended for', test.ageAndGenderLabel!),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            eyebrow: 'AT A GLANCE',
            title: 'Key booking details',
            accent: style.accent,
          ),
          const SizedBox(height: 12),
          _FactGrid(facts: facts),
          if (!hasPreparation) ...[
            const SizedBox(height: 10),
            const Text(
              'Confirm fasting and medicine instructions while booking.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.3,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (hasPurpose) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE8EDF4)),
            const SizedBox(height: 13),
            const Text(
              'What this test checks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              purpose!,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.4,
                height: 1.48,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var index = 0; index < facts.length; index += 2) {
      final left = facts[index];
      final right = index + 1 < facts.length ? facts[index + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _FactCell(fact: left)),
              Container(width: 1, color: const Color(0xFFE8EDF4)),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _FactCell(fact: right),
              ),
            ],
          ),
        ),
      );

      if (index + 2 < facts.length) {
        rows.add(const Divider(height: 1, color: Color(0xFFE8EDF4)));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.2,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            fact.value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11.8,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreDetails extends StatelessWidget {
  const _MoreDetails({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final hasSampleDetails =
        (test.sampleTypeVolume?.trim().isNotEmpty ?? false) ||
        (test.sampleCollectionNote?.trim().isNotEmpty ?? false) ||
        test.specialHandlingRequired;
    final hasTechnicalDetails =
        (test.testCode?.trim().isNotEmpty ?? false) ||
        (test.bodySystem?.trim().isNotEmpty ?? false);
    final sections = <_DetailSection>[];

    if (hasSampleDetails) {
      sections.add(
        _DetailSection(
          title: 'Sample details',
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
        _DetailSection(
          title: 'Included parameters',
          summary: '${test.includedParameters.length} items',
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
                    color: style.soft.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    parameter,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.4,
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
        _DetailSection(
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
              if (test.bodySystem != null) const SizedBox(height: 11),
              _DetailLine('Catalogue type', test.testTypeLabel),
              const SizedBox(height: 11),
              _DetailLine('Collection', test.collectionLabel),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
            child: Row(
              children: [
                Expanded(
                  child: _SectionTitle(
                    eyebrow: 'OPTIONAL',
                    title: 'More details',
                    accent: style.accent,
                  ),
                ),
                const Text(
                  'Tap to expand',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          for (var index = 0; index < sections.length; index++) ...[
            _DetailTile(section: sections[index]),
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

class _DetailSection {
  const _DetailSection({
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.section});

  final _DetailSection section;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          section.title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          section.summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.2,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: accent,
            fontSize: 9.6,
            fontWeight: FontWeight.w900,
            letterSpacing: .72,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15.2,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
              fontSize: 11.2,
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
              fontSize: 12.3,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: accent, size: 17),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Your doctor’s prescription and the lab’s final instructions take priority.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.3,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
