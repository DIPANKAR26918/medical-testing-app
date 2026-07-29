import 'package:flutter/material.dart';

import '../../models/medical_test.dart';
import '../../services/personalized_test_recommendation_service.dart';
import '../medical_test_catalog/medical_test_catalog_widgets.dart';
import 'home_constants.dart';

class HomePersonalizedRecommendations extends StatelessWidget {
  const HomePersonalizedRecommendations({
    required this.isLoading,
    required this.onTestTap,
    required this.onClearActivity,
    this.recommendations,
    this.onCompleteProfile,
    super.key,
  });

  final PersonalizedTestRecommendations? recommendations;
  final bool isLoading;
  final ValueChanged<MedicalTest> onTestTap;
  final VoidCallback onClearActivity;
  final VoidCallback? onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _PersonalizedSkeleton();

    final data = recommendations;
    if (data == null) return const SizedBox.shrink();

    if (data.isEmpty) {
      return data.profileNeedsDetails
          ? _ProfileSetupCard(onTap: onCompleteProfile)
          : const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('home-personalized-recommendations'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          onHowItWorks: () => _showHowItWorks(context),
        ),
        if (data.fromActivity.isNotEmpty) ...[
          const SizedBox(height: 17),
          _RailHeading(
            icon: Icons.history_rounded,
            title: 'Based on what you viewed',
            subtitle: 'Private to this device',
            accent: HomeColors.primary,
            actionLabel: 'Clear',
            onAction: onClearActivity,
          ),
          const SizedBox(height: 10),
          _RecommendationRail(
            recommendations: data.fromActivity,
            onTestTap: onTestTap,
          ),
        ],
        if (data.preventive.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _RailHeading(
            icon: Icons.health_and_safety_outlined,
            title: 'Preventive checks for you',
            subtitle: 'Age + gender screening guidance',
            accent: HomeColors.mint,
          ),
          const SizedBox(height: 10),
          _RecommendationRail(
            recommendations: data.preventive,
            onTestTap: onTestTap,
          ),
          const SizedBox(height: 10),
          const _ClinicalGuardrail(),
        ],
      ],
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How recommendations work',
                style: TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16),
              _PrivacyPoint(
                icon: Icons.phonelink_lock_rounded,
                title: 'Your viewing activity stays here',
                body:
                    'Only test IDs, view counts and the last-viewed time are '
                    'kept on this device for up to 90 days. Search text is not '
                    'saved for recommendations.',
              ),
              SizedBox(height: 16),
              _PrivacyPoint(
                icon: Icons.fact_check_outlined,
                title: 'Preventive, not predictive',
                body:
                    'Age and gender are used only to match public Indian '
                    'screening guidance. This does not predict disease or '
                    'replace advice from a clinician.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.onHowItWorks});

  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Picked for you',
                style: TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 22,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.42,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Useful next steps, with a clear reason for every suggestion.',
                style: TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 11.6,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: onHowItWorks,
          icon: const Icon(Icons.info_outline_rounded, size: 16),
          label: const Text('Why these?'),
          style: TextButton.styleFrom(
            foregroundColor: HomeColors.primary,
            backgroundColor: HomeColors.primarySoft,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RailHeading extends StatelessWidget {
  const _RailHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 14.2,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 10.7,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: HomeColors.textSecondary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _RecommendationRail extends StatelessWidget {
  const _RecommendationRail({
    required this.recommendations,
    required this.onTestTap,
  });

  final List<PersonalizedTestRecommendation> recommendations;
  final ValueChanged<MedicalTest> onTestTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: recommendations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return _RecommendationCard(
            key: ValueKey(
              'personalized-${recommendation.source.name}-'
              '${recommendation.test.id}',
            ),
            recommendation: recommendation,
            onTap: () => onTestTap(recommendation.test),
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
    super.key,
  });

  final PersonalizedTestRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final test = recommendation.test;
    final preventive =
        recommendation.source == PersonalizedRecommendationSource.preventive;
    final accent = preventive ? HomeColors.mint : HomeColors.primary;
    final soft = preventive ? HomeColors.mintSoft : HomeColors.primarySoft;

    return Semantics(
      button: true,
      label:
          '${test.displayName}. ${recommendation.reason} '
          '${test.priceSemanticsLabel}.',
      child: SizedBox(
        width: 276,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HomeColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D111C3B),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          recommendation.badgeLabel,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9.8,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MedicalTestIconBadge(
                        test: test,
                        size: 42,
                        useHero: false,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          test.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeColors.textPrimary,
                            fontSize: 14.2,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      recommendation.reason,
                      maxLines: preventive ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.textSecondary,
                        fontSize: 10.7,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Divider(height: 15, color: HomeColors.borderLight),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: HomeColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          test.reportLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeColors.textSecondary,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MedicalTestPrice(
                        test: test,
                        showMrpLabel: false,
                        mrpFontSize: 9,
                        priceFontSize: 13.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicalGuardrail extends StatelessWidget {
  const _ClinicalGuardrail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: HomeColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: HomeColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: HomeColors.textMuted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Screening reminder only — not a diagnosis. Symptoms, pregnancy, '
              'medicines and family history may change what a clinician advises.',
              style: TextStyle(
                color: HomeColors.textSecondary,
                fontSize: 10.4,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupCard extends StatelessWidget {
  const _ProfileSetupCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('personalized-profile-setup'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F8FF), Color(0xFFEDF7F4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: HomeColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make recommendations relevant',
                  style: TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 14.2,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add age and gender in Profile for preventive screening '
                  'reminders.',
                  style: TextStyle(
                    color: HomeColors.textSecondary,
                    fontSize: 10.8,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              tooltip: 'Open profile',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: HomeColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: HomeColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: HomeColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: HomeColors.textPrimary,
                  fontSize: 13.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 11.2,
                  height: 1.45,
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

class _PersonalizedSkeleton extends StatelessWidget {
  const _PersonalizedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('personalized-loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 142,
          height: 20,
          decoration: BoxDecoration(
            color: HomeColors.borderLight,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) {
              return Container(
                width: 276,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HomeColors.borderLight),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
