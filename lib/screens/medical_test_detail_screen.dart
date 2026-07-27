import 'package:flutter/material.dart';

import '../models/medical_parameter_guide.dart';
import '../models/medical_test.dart';
import '../services/medical_parameter_guide_service.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

typedef MedicalParameterGuideLoader =
    Future<MedicalParameterGuide?> Function(String parameter);

abstract final class _DetailPalette {
  static const background = Color(0xFFF7F9FC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const primaryTint = Color(0xFFF5F8FF);
  static const ink = Color(0xFF0F172A);
  static const text = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const weak = Color(0xFF94A3B8);
  static const border = Color(0xFFE1E8F2);
  static const divider = Color(0xFFEBF0F6);
}

class MedicalTestDetailScreen extends StatelessWidget {
  const MedicalTestDetailScreen({
    required this.test,
    this.parameterGuideLoader,
    super.key,
  });

  final MedicalTest test;
  final MedicalParameterGuideLoader? parameterGuideLoader;

  @override
  Widget build(BuildContext context) {
    final hasGuidance = _hasText(test.purpose) || _hasText(test.preparation);
    final hasMoreInformation = _hasMoreInformation(test);

    return Scaffold(
      backgroundColor: _DetailPalette.background,
      appBar: AppBar(
        backgroundColor: _DetailPalette.background,
        foregroundColor: _DetailPalette.ink,
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
              _TestSummaryCard(test: test),
              if (hasGuidance) ...[
                const SizedBox(height: 12),
                _GuidanceCard(test: test),
              ],
              if (hasMoreInformation) ...[
                const SizedBox(height: 12),
                _MoreInformationCard(
                  test: test,
                  onParameterTap: (parameter) =>
                      _showParameterGuide(context, parameter),
                ),
              ],
              const SizedBox(height: 16),
              const _ClinicalNote(),
            ],
          ),
        ),
      ),
    );
  }

  void _showParameterGuide(BuildContext context, String parameter) {
    final guideFuture =
        parameterGuideLoader?.call(parameter) ??
        MedicalParameterGuideService.shared.fetchGuide(parameter);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _DetailPalette.surface,
      barrierColor: Colors.black.withValues(alpha: .34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ParameterGuideSheet(
        parameter: parameter,
        testName: test.displayName,
        guideFuture: guideFuture,
      ),
    );
  }
}

bool _hasText(String? value) => value?.trim().isNotEmpty == true;

bool _hasMoreInformation(MedicalTest test) {
  return test.ageAndGenderLabel != null ||
      _hasText(test.sampleCollectionNote) ||
      test.specialHandlingRequired ||
      test.includedParameters.isNotEmpty ||
      _hasText(test.testCode) ||
      _hasText(test.bodySystem);
}

class _TestSummaryCard extends StatelessWidget {
  const _TestSummaryCard({required this.test});

  final MedicalTest test;

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
              _UnifiedTestBadge(test: test),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryPill(category: test.category),
                    const SizedBox(height: 8),
                    Text(
                      test.displayName,
                      style: const TextStyle(
                        color: _DetailPalette.ink,
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    if (test.hasDifferentOfficialName) ...[
                      const SizedBox(height: 5),
                      Text(
                        test.nameSheet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DetailPalette.muted,
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
          _EssentialsGrid(test: test),
        ],
      ),
    );
  }
}

class _UnifiedTestBadge extends StatelessWidget {
  const _UnifiedTestBadge({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    final icon = medicalTestCategoryStyle(test.category).icon;
    final badge = Material(
      color: Colors.transparent,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _DetailPalette.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _DetailPalette.primary.withValues(alpha: .10),
          ),
        ),
        child: Icon(icon, color: _DetailPalette.primary, size: 25),
      ),
    );

    if (test.id.isEmpty) return badge;
    return Hero(tag: medicalTestHeroTag(test), child: badge);
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _DetailPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _DetailPalette.primary,
          fontSize: 10.8,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    final collection = test.labVisitRequired
        ? 'Lab visit'
        : test.homeCollectionAvailable
        ? 'Home collection'
        : 'Confirm at booking';

    final facts = [
      _EssentialFactData(
        icon: Icons.currency_rupee_rounded,
        label: 'Price',
        value: test.priceLabel,
        emphasize: true,
      ),
      _EssentialFactData(
        icon: Icons.schedule_outlined,
        label: 'Report time',
        value: test.reportLabel,
      ),
      _EssentialFactData(
        icon: test.labVisitRequired
            ? Icons.local_hospital_outlined
            : Icons.home_outlined,
        label: 'Collection',
        value: collection,
      ),
      _EssentialFactData(
        icon: Icons.water_drop_outlined,
        label: 'Sample',
        value: test.sampleLabel,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final fact in facts)
              SizedBox(
                width: itemWidth,
                height: 86,
                child: _EssentialFact(fact: fact),
              ),
          ],
        );
      },
    );
  }
}

class _EssentialFactData {
  const _EssentialFactData({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
}

class _EssentialFact extends StatelessWidget {
  const _EssentialFact({required this.fact});

  final _EssentialFactData fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DetailPalette.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DetailPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(fact.icon, color: _DetailPalette.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fact.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DetailPalette.muted,
                    fontSize: 10.8,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fact.emphasize ? _DetailPalette.ink : _DetailPalette.text,
              fontSize: fact.emphasize ? 16 : 12.6,
              height: 1.3,
              fontWeight: fact.emphasize ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.test});

  final MedicalTest test;

  @override
  Widget build(BuildContext context) {
    final purpose = test.purpose?.trim();
    final preparation = test.preparation?.trim();
    final hasPurpose = purpose?.isNotEmpty == true;
    final hasPreparation = preparation?.isNotEmpty == true;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'About this test'),
          const SizedBox(height: 14),
          if (hasPurpose)
            _GuidanceRow(
              icon: Icons.biotech_outlined,
              title: 'What it checks',
              body: purpose!,
            ),
          if (hasPurpose && hasPreparation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: _DetailPalette.divider),
            ),
          if (hasPreparation)
            _GuidanceRow(
              icon: Icons.fact_check_outlined,
              title: 'Preparation',
              body: preparation!,
            ),
        ],
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _DetailPalette.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _DetailPalette.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _DetailPalette.ink,
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: _DetailPalette.muted,
                  fontSize: 12.8,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreInformationCard extends StatelessWidget {
  const _MoreInformationCard({
    required this.test,
    required this.onParameterTap,
  });

  final MedicalTest test;
  final ValueChanged<String> onParameterTap;

  @override
  Widget build(BuildContext context) {
    final sections = <_DetailSection>[];
    final hasSampleNotes =
        _hasText(test.sampleCollectionNote) || test.specialHandlingRequired;
    final hasTechnicalDetails =
        _hasText(test.testCode) || _hasText(test.bodySystem);

    if (test.ageAndGenderLabel != null) {
      sections.add(
        _DetailSection(
          icon: Icons.person_outline_rounded,
          title: 'Recommended for',
          summary: test.ageAndGenderLabel!,
          child: Text(test.ageAndGenderLabel!, style: _detailBodyStyle),
        ),
      );
    }

    if (hasSampleNotes) {
      sections.add(
        _DetailSection(
          icon: Icons.science_outlined,
          title: 'Collection notes',
          summary: test.specialHandlingRequired
              ? 'Special handling required'
              : 'Instructions for this sample',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasText(test.sampleCollectionNote))
                Text(
                  test.sampleCollectionNote!.trim(),
                  style: _detailBodyStyle,
                ),
              if (_hasText(test.sampleCollectionNote) &&
                  test.specialHandlingRequired)
                const SizedBox(height: 10),
              if (test.specialHandlingRequired)
                const Text(
                  'The lab will use special handling for this sample.',
                  style: _detailBodyStyle,
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
            onParameterTap: onParameterTap,
          ),
        ),
      );
    }

    if (hasTechnicalDetails) {
      sections.add(
        _DetailSection(
          icon: Icons.description_outlined,
          title: 'Technical information',
          summary: 'Catalogue and body-system details',
          child: Column(
            children: [
              if (_hasText(test.testCode))
                _DetailLine('Test code', test.testCode!.trim()),
              if (_hasText(test.testCode) && _hasText(test.bodySystem))
                const SizedBox(height: 12),
              if (_hasText(test.bodySystem))
                _DetailLine('Body system', test.bodySystem!.trim()),
              if (_hasText(test.bodySystem)) const SizedBox(height: 12),
              _DetailLine('Test type', test.testTypeLabel),
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
            child: _SectionHeading(title: 'More information'),
          ),
          const Divider(height: 1, color: _DetailPalette.divider),
          for (var index = 0; index < sections.length; index++) ...[
            _DetailTile(section: sections[index]),
            if (index != sections.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: _DetailPalette.divider,
              ),
          ],
        ],
      ),
    );
  }
}

const TextStyle _detailBodyStyle = TextStyle(
  color: _DetailPalette.muted,
  fontSize: 12.7,
  height: 1.5,
  fontWeight: FontWeight.w500,
);

class _ParameterList extends StatelessWidget {
  const _ParameterList({
    required this.parameters,
    required this.onParameterTap,
  });

  final List<String> parameters;
  final ValueChanged<String> onParameterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < parameters.length; index++) ...[
          Semantics(
            button: true,
            label: 'Learn about ${parameters[index]}',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('parameter-${parameters[index]}'),
                onTap: () => onParameterTap(parameters[index]),
                borderRadius: BorderRadius.circular(12),
                splashColor: _DetailPalette.primarySoft,
                highlightColor: _DetailPalette.primaryTint,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 21,
                          height: 21,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _DetailPalette.primarySoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: _DetailPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            parameters[index],
                            style: _detailBodyStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: _DetailPalette.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (index != parameters.length - 1)
            const Divider(height: 1, color: _DetailPalette.divider),
        ],
      ],
    );
  }
}

class _ParameterGuideSheet extends StatelessWidget {
  const _ParameterGuideSheet({
    required this.parameter,
    required this.testName,
    required this.guideFuture,
  });

  final String parameter;
  final String testName;
  final Future<MedicalParameterGuide?> guideFuture;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * .78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: FutureBuilder<MedicalParameterGuide?>(
        future: guideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _ParameterGuideLoading(parameter: parameter);
          }

          return _ParameterGuideContent(
            parameter: parameter,
            testName: testName,
            guide: snapshot.data,
            loadFailed: snapshot.hasError,
          );
        },
      ),
    );
  }
}

class _ParameterGuideLoading extends StatelessWidget {
  const _ParameterGuideLoading({required this.parameter});

  final String parameter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this parameter',
            style: TextStyle(
              color: _DetailPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            parameter,
            style: const TextStyle(
              color: _DetailPalette.ink,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: CircularProgressIndicator(
              color: _DetailPalette.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Loading source-backed medical information…',
              style: _detailBodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterGuideContent extends StatelessWidget {
  const _ParameterGuideContent({
    required this.parameter,
    required this.testName,
    required this.guide,
    required this.loadFailed,
  });

  final String parameter;
  final String testName;
  final MedicalParameterGuide? guide;
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    final reviewedGuide = guide;
    final displayName = reviewedGuide?.displayName ?? parameter;
    final statusMessage = loadFailed
        ? 'The source-backed explanation could not be loaded right now.'
        : 'A source-backed explanation for this parameter is being prepared.';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        22,
        6,
        22,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this parameter',
            style: TextStyle(
              color: _DetailPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            displayName,
            style: const TextStyle(
              color: _DetailPalette.ink,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Included in $testName',
            style: const TextStyle(
              color: _DetailPalette.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          if (reviewedGuide != null) ...[
            _GuidePoint(title: 'What it is', body: reviewedGuide.whatItIs),
            const SizedBox(height: 16),
            _GuidePoint(
              title: 'Why this test checks it',
              body: reviewedGuide.whyItMatters,
            ),
            const SizedBox(height: 16),
            _GuidePoint(
              title: 'What to remember',
              body: reviewedGuide.howToReadIt,
            ),
          ] else ...[
            _GuidePoint(
              title: 'What it is',
              body:
                  '$parameter is one of the measurements included in this test. '
                  'Its exact meaning can depend on the sample and lab method.',
            ),
            const SizedBox(height: 16),
            _GuidePoint(
              title: 'Why this test checks it',
              body:
                  'The lab assesses it together with the other parameters in '
                  '$testName to understand the overall pattern.',
            ),
            const SizedBox(height: 16),
            _GuidePoint(title: 'What to remember', body: statusMessage),
          ],
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DetailPalette.primaryTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DetailPalette.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 18,
                  color: _DetailPalette.primary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reference ranges vary by lab. One parameter alone cannot '
                    'diagnose a condition—read it with your full report and a '
                    'qualified clinician.',
                    style: TextStyle(
                      color: _DetailPalette.text,
                      fontSize: 11.6,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (reviewedGuide != null) ...[
            const SizedBox(height: 14),
            Text(
              'Medical source: ${reviewedGuide.sourceLabel}',
              style: const TextStyle(
                color: _DetailPalette.weak,
                fontSize: 10.8,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: _DetailPalette.primary,
            shape: BoxShape.circle,
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
                  color: _DetailPalette.ink,
                  fontSize: 13.2,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: _DetailPalette.text,
                  fontSize: 12.4,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: _DetailPalette.primarySoft,
        highlightColor: _DetailPalette.primaryTint,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        childrenPadding: const EdgeInsets.fromLTRB(48, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: _DetailPalette.primary,
        collapsedIconColor: _DetailPalette.weak,
        leading: Icon(section.icon, size: 19, color: _DetailPalette.primary),
        title: Text(
          section.title,
          style: const TextStyle(
            color: _DetailPalette.ink,
            fontSize: 13.2,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          section.summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _DetailPalette.muted,
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
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _DetailPalette.ink,
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
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
          width: 86,
          child: Text(
            label,
            style: const TextStyle(
              color: _DetailPalette.weak,
              fontSize: 10.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: _detailBodyStyle)),
      ],
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
        color: _DetailPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DetailPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ClinicalNote extends StatelessWidget {
  const _ClinicalNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _DetailPalette.primary,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your prescription and the lab’s final instructions take priority.',
              style: TextStyle(
                color: _DetailPalette.muted,
                fontSize: 11.2,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
