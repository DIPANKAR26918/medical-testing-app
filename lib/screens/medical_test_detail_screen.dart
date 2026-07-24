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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
          child: Column(
            children: [
              _TestOverview(test: test, style: style),
              const SizedBox(height: 12),
              _BookingEssentials(test: test, accent: style.accent),
              if (_hasText(test.purpose)) ...[
                const SizedBox(height: 12),
                _TextSection(
                  icon: Icons.biotech_outlined,
                  title: 'What this test checks',
                  body: test.purpose!.trim(),
                ),
              ],
              const SizedBox(height: 12),
              _PreparationSection(test: test, accent: style.accent),
              if (_hasMoreDetails(test)) ...[
                const SizedBox(height: 12),
                _AdditionalDetails(test: test, style: style),
              ],
              const SizedBox(height: 16),
              _MedicalNote(accent: style.accent),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasText(String? value) => value?.trim().isNotEmpty == true;

bool _hasMoreDetails(MedicalTest test) {
  return _hasText(test.sampleTypeVolume) ||
      _hasText(test.sampleCollectionNote) ||
      test.specialHandlingRequired ||
      test.includedParameters.isNotEmpty ||
      _hasText(test.testCode) ||
      _hasText(test.bodySystem) ||
      test.ageAndGenderLabel != null;
}

class _TestOverview extends StatelessWidget {
  const _TestOverview({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryLabel(
                      category: test.category,
                      accent: style.accent,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      test.displayName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                    if (test.hasDifferentOfficialName) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lab name: ${test.nameSheet}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _OverviewMeta(
                  label: 'Price',
                  value: test.priceLabel,
                  valueStyle: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: const Color(0xFFE7ECF2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OverviewMeta(
                  label: 'Test type',
                  value: test.parameterCount == null
                      ? test.testTypeLabel
                      : '${test.parameterCount} parameters',
                ),
              ),
            ],
          ),
          if (test.isPopular) ...[
            const SizedBox(height: 14),
            const _PopularNote(),
          ],
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.category, required this.accent});

  final String category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      category,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: accent,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _OverviewMeta extends StatelessWidget {
  const _OverviewMeta({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: valueStyle ??
              const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _PopularNote extends StatelessWidget {
  const _PopularNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.trending_up_rounded,
          size: 16,
          color: Color(0xFFB45309),
        ),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Frequently booked by Testified users',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingEssentials extends StatelessWidget {
  const _BookingEssentials({required this.test, required this.accent});

  final MedicalTest test;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final collection = test.labVisitRequired
        ? 'Lab visit required'
        : test.homeCollectionAvailable
            ? 'Home sample collection available'
            : 'Availability confirmed during booking';

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'Key booking details'),
          const SizedBox(height: 4),
          _InfoRow(
            icon: test.labVisitRequired
                ? Icons.local_hospital_outlined
                : Icons.home_outlined,
            label: 'Collection',
            value: collection,
            accent: accent,
          ),
          const _InsetDivider(),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Report time',
            value: test.reportLabel,
            accent: accent,
          ),
          const _InsetDivider(),
          _InfoRow(
            icon: Icons.water_drop_outlined,
            label: 'Sample',
            value: test.sampleLabel,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
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

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: title, icon: icon),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparationSection extends StatelessWidget {
  const _PreparationSection({required this.test, required this.accent});

  final MedicalTest test;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final preparation = test.preparation?.trim();
    final hasPreparation = preparation?.isNotEmpty == true;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Preparation',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 10),
          Text(
            hasPreparation
                ? preparation!
                : 'No specific preparation is listed. Confirm fasting and medicine instructions while booking.',
            style: TextStyle(
              color: hasPreparation
                  ? const Color(0xFF334155)
                  : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.5,
              fontWeight: hasPreparation ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (!hasPreparation) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Do not change medicines unless your doctor tells you to.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdditionalDetails extends StatelessWidget {
  const _AdditionalDetails({required this.test, required this.style});

  final MedicalTest test;
  final MedicalTestCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    final sections = <_DetailSection>[];
    final hasSampleDetails = _hasText(test.sampleTypeVolume) ||
        _hasText(test.sampleCollectionNote) ||
        test.specialHandlingRequired;
    final hasTechnicalDetails =
        _hasText(test.testCode) || _hasText(test.bodySystem);

    if (test.ageAndGenderLabel != null) {
      sections.add(
        _DetailSection(
          icon: Icons.person_outline_rounded,
          title: 'Recommended for',
          summary: test.ageAndGenderLabel!,
          child: _DetailLine('Recommendation', test.ageAndGenderLabel!),
        ),
      );
    }

    if (hasSampleDetails) {
      sections.add(
        _DetailSection(
          icon: Icons.science_outlined,
          title: 'Sample details',
          summary: test.sampleTypeVolume?.trim() ??
              test.sampleCollectionNote?.trim() ??
              'Special handling required',
          child: Column(
            children: [
              if (_hasText(test.sampleTypeVolume))
                _DetailLine('Volume / type', test.sampleTypeVolume!.trim()),
              if (_hasText(test.sampleTypeVolume) &&
                  (_hasText(test.sampleCollectionNote) ||
                      test.specialHandlingRequired))
                const SizedBox(height: 12),
              if (_hasText(test.sampleCollectionNote))
                _DetailLine(
                  'Collection note',
                  test.sampleCollectionNote!.trim(),
                ),
              if (_hasText(test.sampleCollectionNote) &&
                  test.specialHandlingRequired)
                const SizedBox(height: 12),
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
          icon: Icons.checklist_rounded,
          title: 'Included parameters',
          summary: '${test.includedParameters.length} included',
          child: _ParameterList(
            parameters: test.includedParameters,
            softColor: style.soft,
          ),
        ),
      );
    }

    if (hasTechnicalDetails) {
      sections.add(
        _DetailSection(
          icon: Icons.description_outlined,
          title: 'Technical information',
          summary: _hasText(test.testCode)
              ? 'Code ${test.testCode!.trim()}'
              : test.bodySystem!.trim(),
          child: Column(
            children: [
              if (_hasText(test.testCode))
                _DetailLine('Test code', test.testCode!.trim()),
              if (_hasText(test.testCode) && _hasText(test.bodySystem))
                const SizedBox(height: 12),
              if (_hasText(test.bodySystem))
                _DetailLine('Body system', test.bodySystem!.trim()),
              if (_hasText(test.bodySystem)) const SizedBox(height: 12),
              _DetailLine('Catalogue type', test.testTypeLabel),
            ],
          ),
        ),
      );
    }

    return _Surface(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _SectionHeading(title: 'More details'),
          ),
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          for (var index = 0; index < sections.length; index++) ...[
            _DetailTile(section: sections[index]),
            if (index != sections.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFE7ECF2),
              ),
          ],
        ],
      ),
    );
  }
}

class _ParameterList extends StatelessWidget {
  const _ParameterList({
    required this.parameters,
    required this.softColor,
  });

  final List<String> parameters;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < parameters.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: softColor.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parameters[index],
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (index != parameters.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DetailSection {
  const _DetailSection({
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.section});

  final _DetailSection section;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          section.icon,
          size: 20,
          color: const Color(0xFF64748B),
        ),
        title: Text(
          section.title,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13.5,
            height: 1.25,
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
            height: 1.35,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: const Color(0xFF475569)),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10.8,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 48,
      color: Color(0xFFE7ECF2),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
