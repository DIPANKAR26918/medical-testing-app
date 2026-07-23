import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

bool shouldOpenPrescriptionReview(String rawStatus) {
  return rawStatus
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_') ==
      'awaiting_user_approval';
}

/// Focused approval journey for tests mapped from a prescription.
///
/// The previous implementation mixed tracking, prescription preview, test
/// selection, and confirmation on one order-details page. This screen gives
/// the one decision that matters its own hierarchy and sticky price summary.
class PrescriptionReviewScreen extends StatefulWidget {
  const PrescriptionReviewScreen({required this.order, super.key});

  final Order order;

  @override
  State<PrescriptionReviewScreen> createState() =>
      _PrescriptionReviewScreenState();
}

class _PrescriptionReviewScreenState extends State<PrescriptionReviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<List<PrescriptionOrderTest>>? _testsFuture;
  Future<String>? _prescriptionUrlFuture;
  List<PrescriptionOrderTest> _recommendations = const [];
  Set<String> _selectedIds = <String>{};
  bool _confirming = false;

  double get _selectedTotal => _recommendations
      .where((item) => _selectedIds.contains(item.test.id))
      .fold<double>(0, (total, item) => total + (item.test.mrp ?? 0));

  bool get _allSelected =>
      _recommendations.isNotEmpty &&
      _selectedIds.length == _recommendations.length;

  @override
  void initState() {
    super.initState();
    _loadPrescriptionUrl();
    _loadRecommendations();
  }

  void _loadPrescriptionUrl() {
    final path = widget.order.prescriptionImagePath.trim();
    if (path.isEmpty) return;

    _prescriptionUrlFuture = _storageService.createSignedUrl(
      path,
      expiresInSeconds: 3600,
    );
  }

  void _loadRecommendations() {
    final future = _firestoreService.fetchPrescriptionTests(
      widget.order.orderId,
    );

    setState(() {
      _testsFuture = future;
      _recommendations = const [];
      _selectedIds = <String>{};
    });

    future.then((items) {
      if (!mounted || _testsFuture != future) return;

      final selected = items
          .where((item) => item.selectedByUser)
          .map((item) => item.test.id)
          .toSet();

      setState(() {
        _recommendations = items;
        _selectedIds = selected.isEmpty
            ? items.map((item) => item.test.id).toSet()
            : selected;
      });
    });
  }

  void _toggleTest(String testId, bool selected) {
    if (_confirming) return;

    setState(() {
      if (selected) {
        _selectedIds.add(testId);
      } else {
        _selectedIds.remove(testId);
      }
    });
  }

  void _toggleAll() {
    if (_confirming || _recommendations.isEmpty) return;

    setState(() {
      if (_allSelected) {
        _selectedIds = <String>{};
      } else {
        _selectedIds = _recommendations.map((item) => item.test.id).toSet();
      }
    });
  }

  Future<void> _requestConfirmation() async {
    if (_confirming) return;

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Select at least one test to continue.'),
          ),
        );
      return;
    }

    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PrescriptionFlowTheme.surface,
      barrierColor: Colors.black.withValues(alpha: .38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ConfirmationSheet(
        selectedCount: _selectedIds.length,
        selectedTotal: _selectedTotal,
        address: widget.order.patientLocationAddress,
      ),
    );

    if (approved == true) await _confirmBooking();
  }

  Future<void> _confirmBooking() async {
    setState(() => _confirming = true);

    try {
      final confirmedOrder = await _firestoreService.confirmPrescriptionBooking(
        widget.order.orderId,
        _selectedIds,
      );

      if (!mounted) return;

      final openBooking = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _BookingConfirmedSheet(order: confirmedOrder),
      );

      if (!mounted) return;

      if (openBooking == true) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/order-details', arguments: confirmedOrder);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: const {'tabIndex': 1},
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _confirming = false);

      final message = error.toString().replaceFirst('Exception: ', '').trim();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message.isEmpty
                  ? 'Booking could not be confirmed. Please try again.'
                  : message,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testsFuture = _testsFuture;

    return Scaffold(
      backgroundColor: PrescriptionFlowTheme.background,
      appBar: AppBar(
        backgroundColor: PrescriptionFlowTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton.filledTonal(
            onPressed: _confirming ? null : () => Navigator.maybePop(context),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: PrescriptionFlowTheme.surface,
              foregroundColor: PrescriptionFlowTheme.ink,
              side: const BorderSide(color: PrescriptionFlowTheme.outline),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review your tests',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Final step before booking',
              style: TextStyle(
                color: PrescriptionFlowTheme.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showReviewHelp(context),
            tooltip: 'How review works',
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: testsFuture == null
            ? const _ReviewLoadingBody()
            : FutureBuilder<List<PrescriptionOrderTest>>(
                future: testsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _ReviewLoadingBody();
                  }

                  if (snapshot.hasError) {
                    return _ReviewErrorBody(onRetry: _loadRecommendations);
                  }

                  final recommendations = snapshot.data ?? const [];
                  if (recommendations.isEmpty) {
                    return _ReviewEmptyBody(onRetry: _loadRecommendations);
                  }

                  return _ReviewContent(
                    order: widget.order,
                    recommendations: recommendations,
                    selectedIds: _selectedIds,
                    prescriptionUrlFuture: _prescriptionUrlFuture,
                    allSelected: _allSelected,
                    confirming: _confirming,
                    onToggleAll: _toggleAll,
                    onChanged: _toggleTest,
                  );
                },
              ),
      ),
      bottomNavigationBar: _ReviewBottomBar(
        selectedCount: _selectedIds.length,
        selectedTotal: _selectedTotal,
        enabled: _recommendations.isNotEmpty,
        confirming: _confirming,
        onConfirm: _requestConfirmation,
      ),
    );
  }

  void _showReviewHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PrescriptionFlowTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ReviewHelpSheet(),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.order,
    required this.recommendations,
    required this.selectedIds,
    required this.prescriptionUrlFuture,
    required this.allSelected,
    required this.confirming,
    required this.onToggleAll,
    required this.onChanged,
  });

  final Order order;
  final List<PrescriptionOrderTest> recommendations;
  final Set<String> selectedIds;
  final Future<String>? prescriptionUrlFuture;
  final bool allSelected;
  final bool confirming;
  final VoidCallback onToggleAll;
  final void Function(String id, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 144),
      children: [
        const _ApprovalProgress(),
        const SizedBox(height: 18),
        _ReadyHero(
          selectedCount: selectedIds.length,
          totalCount: recommendations.length,
        ),
        const SizedBox(height: 14),
        _SourceSummaryCard(
          order: order,
          prescriptionUrlFuture: prescriptionUrlFuture,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prescribed tests',
                    style: TextStyle(
                      color: PrescriptionFlowTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap a card or checkbox to include or remove a test.',
                    style: TextStyle(
                      color: PrescriptionFlowTheme.text,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: confirming ? null : onToggleAll,
              child: Text(allSelected ? 'Clear all' : 'Select all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < recommendations.length; index++) ...[
          _ReviewTestCard(
            recommendation: recommendations[index],
            selected: selectedIds.contains(recommendations[index].test.id),
            enabled: !confirming,
            onChanged: (selected) =>
                onChanged(recommendations[index].test.id, selected),
          ),
          if (index != recommendations.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        const _ClinicalNotice(),
      ],
    );
  }
}

class _ApprovalProgress extends StatelessWidget {
  const _ApprovalProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PrescriptionFlowTheme.card(radius: 18, shadow: false),
      child: const Row(
        children: [
          _ProgressPill(
            icon: Icons.check_rounded,
            label: 'Uploaded',
            completed: true,
          ),
          Expanded(
            child: Divider(
              indent: 8,
              endIndent: 8,
              color: PrescriptionFlowTheme.primary,
              thickness: 2,
            ),
          ),
          _ProgressPill(
            icon: Icons.check_rounded,
            label: 'Reviewed',
            completed: true,
          ),
          Expanded(
            child: Divider(
              indent: 8,
              endIndent: 8,
              color: PrescriptionFlowTheme.primary,
              thickness: 2,
            ),
          ),
          _ProgressPill(
            icon: Icons.tune_rounded,
            label: 'Confirm',
            active: true,
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.icon,
    required this.label,
    this.completed = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: completed
                ? PrescriptionFlowTheme.primary
                : PrescriptionFlowTheme.primaryContainer,
            shape: BoxShape.circle,
            border: active
                ? Border.all(color: PrescriptionFlowTheme.primary)
                : null,
          ),
          child: Icon(
            icon,
            color: completed ? Colors.white : PrescriptionFlowTheme.primary,
            size: 17,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: completed || active
                ? PrescriptionFlowTheme.ink
                : PrescriptionFlowTheme.muted,
            fontSize: 10.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReadyHero extends StatelessWidget {
  const _ReadyHero({required this.selectedCount, required this.totalCount});

  final int selectedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: PrescriptionFlowTheme.card(
        color: PrescriptionFlowTheme.primaryContainer,
        borderColor: PrescriptionFlowTheme.primaryOutline,
        shadow: false,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: PrescriptionFlowTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your test list is ready',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Review each item. Only selected tests will move to booking.',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.text,
                    fontSize: 12,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$selectedCount of $totalCount selected',
                    style: const TextStyle(
                      color: PrescriptionFlowTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
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

class _SourceSummaryCard extends StatelessWidget {
  const _SourceSummaryCard({
    required this.order,
    required this.prescriptionUrlFuture,
  });

  final Order order;
  final Future<String>? prescriptionUrlFuture;

  @override
  Widget build(BuildContext context) {
    final address = order.patientLocationAddress?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PrescriptionFlowTheme.card(radius: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrescriptionThumbnail(future: prescriptionUrlFuture),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: PrescriptionFlowTheme.success,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Mapped from your prescription',
                        style: TextStyle(
                          color: PrescriptionFlowTheme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (address != null && address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: PrescriptionFlowTheme.muted,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PrescriptionFlowTheme.text,
                            fontSize: 11.2,
                            height: 1.38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionThumbnail extends StatelessWidget {
  const _PrescriptionThumbnail({required this.future});

  final Future<String>? future;

  @override
  Widget build(BuildContext context) {
    if (future == null) return const _ThumbnailFallback();

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 72,
            height: 80,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final url = snapshot.data;
        if (snapshot.hasError || url == null || url.isEmpty) {
          return const _ThumbnailFallback();
        }

        return Semantics(
          button: true,
          label: 'View prescription',
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _NetworkPrescriptionViewer(imageUrl: url),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ThumbnailFallback(),
                    ),
                    const Positioned(
                      right: 5,
                      bottom: 5,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Color(0xB8000000),
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 80,
      decoration: BoxDecoration(
        color: PrescriptionFlowTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PrescriptionFlowTheme.outline),
      ),
      child: const Icon(
        Icons.description_outlined,
        color: PrescriptionFlowTheme.primary,
      ),
    );
  }
}

class _ReviewTestCard extends StatelessWidget {
  const _ReviewTestCard({
    required this.recommendation,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final PrescriptionOrderTest recommendation;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final test = recommendation.test;
    final categoryStyle = medicalTestCategoryStyle(test.category);

    return Semantics(
      checked: selected,
      button: true,
      label: '${test.displayName}, ${test.priceLabel}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled ? () => onChanged(!selected) : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: PrescriptionFlowTheme.card(
              color: selected
                  ? categoryStyle.soft.withValues(alpha: .45)
                  : PrescriptionFlowTheme.surface,
              borderColor: selected
                  ? categoryStyle.accent
                  : PrescriptionFlowTheme.outline,
              radius: 20,
              shadow: selected,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: MedicalTestArtwork(
                    test: test,
                    height: 82,
                    borderRadius: 14,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PrescriptionFlowTheme.ink,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (test.hasDifferentOfficialName) ...[
                        const SizedBox(height: 3),
                        Text(
                          test.nameSheet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PrescriptionFlowTheme.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _TestFact(
                            icon: Icons.water_drop_outlined,
                            label: test.sampleLabel,
                          ),
                          _TestFact(
                            icon: Icons.schedule_outlined,
                            label: test.reportLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        test.priceLabel,
                        style: const TextStyle(
                          color: PrescriptionFlowTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Checkbox(
                  value: selected,
                  onChanged: enabled
                      ? (value) => onChanged(value ?? false)
                      : null,
                  activeColor: PrescriptionFlowTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestFact extends StatelessWidget {
  const _TestFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: PrescriptionFlowTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: PrescriptionFlowTheme.muted, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PrescriptionFlowTheme.text,
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNotice extends StatelessWidget {
  const _ClinicalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: PrescriptionFlowTheme.card(
        color: PrescriptionFlowTheme.warningContainer,
        borderColor: const Color(0xFFF1D9AE),
        radius: 18,
        shadow: false,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.medical_information_outlined,
            color: PrescriptionFlowTheme.warning,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Check the mapped list against your doctor’s prescription. Contact support before confirming if anything looks missing or incorrect.',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 11.8,
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

class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({
    required this.selectedCount,
    required this.selectedTotal,
    required this.enabled,
    required this.confirming,
    required this.onConfirm,
  });

  final int selectedCount;
  final double selectedTotal;
  final bool enabled;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PrescriptionFlowTheme.outline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1710213D),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCount == 0
                        ? 'No tests selected'
                        : AppHelpers.formatCurrency(selectedTotal),
                    style: const TextStyle(
                      color: PrescriptionFlowTheme.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedCount == 1
                        ? '1 test selected'
                        : '$selectedCount tests selected',
                    style: const TextStyle(
                      color: PrescriptionFlowTheme.text,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: enabled && selectedCount > 0 && !confirming
                    ? onConfirm
                    : null,
                icon: confirming
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(confirming ? 'Confirming…' : 'Review booking'),
                style: PrescriptionFlowTheme.filledButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({
    required this.selectedCount,
    required this.selectedTotal,
    required this.address,
  });

  final int selectedCount;
  final double selectedTotal;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final cleanAddress = address?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm this booking?',
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Check the summary once more. Collection will be arranged for the selected tests.',
            style: TextStyle(
              color: PrescriptionFlowTheme.text,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: PrescriptionFlowTheme.card(radius: 20, shadow: false),
            child: Column(
              children: [
                _ConfirmationRow(
                  label: 'Selected tests',
                  value: '$selectedCount',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _ConfirmationRow(
                  label: 'Estimated total',
                  value: AppHelpers.formatCurrency(selectedTotal),
                  emphasize: true,
                ),
                if (cleanAddress != null && cleanAddress.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _ConfirmationRow(
                    label: 'Collection address',
                    value: cleanAddress,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Confirm selected tests'),
              style: PrescriptionFlowTheme.filledButtonStyle(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go back and edit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: PrescriptionFlowTheme.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: emphasize ? 16 : 12.5,
              height: 1.4,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingConfirmedSheet extends StatelessWidget {
  const _BookingConfirmedSheet({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: PrescriptionFlowTheme.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: PrescriptionFlowTheme.success,
                size: 43,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Booking confirmed',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.45,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${order.testList.length} tests are confirmed. We will now arrange home sample collection.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PrescriptionFlowTheme.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: PrescriptionFlowTheme.filledButtonStyle(),
                child: const Text('View booking'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back to bookings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewHelpSheet extends StatelessWidget {
  const _ReviewHelpSheet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 2, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How prescription review works',
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
          SizedBox(height: 18),
          _HelpRow(
            icon: Icons.manage_search_rounded,
            title: 'Tests are mapped, not added freely',
            description:
                'The team matches names visible in the prescription to the catalogue.',
          ),
          SizedBox(height: 15),
          _HelpRow(
            icon: Icons.tune_rounded,
            title: 'You make the final choice',
            description:
                'Uncheck a test if you do not want it in this booking.',
          ),
          SizedBox(height: 15),
          _HelpRow(
            icon: Icons.support_agent_rounded,
            title: 'Ask before confirming',
            description:
                'Contact support if the list does not match the doctor’s prescription.',
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: PrescriptionFlowTheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: PrescriptionFlowTheme.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.text,
                  fontSize: 12,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewLoadingBody extends StatelessWidget {
  const _ReviewLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
      children: const [
        _LoadingBlock(height: 78),
        SizedBox(height: 14),
        _LoadingBlock(height: 128),
        SizedBox(height: 14),
        _LoadingBlock(height: 104),
        SizedBox(height: 24),
        _LoadingBlock(height: 26, widthFactor: .52),
        SizedBox(height: 12),
        _LoadingBlock(height: 132),
        SizedBox(height: 10),
        _LoadingBlock(height: 132),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height, this.widthFactor = 1});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: PrescriptionFlowTheme.outline,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ReviewErrorBody extends StatelessWidget {
  const _ReviewErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReviewStateBody(
      icon: Icons.cloud_off_outlined,
      title: 'The reviewed tests could not load',
      description: 'Check your connection and try again. Your review is saved.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class _ReviewEmptyBody extends StatelessWidget {
  const _ReviewEmptyBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReviewStateBody(
      icon: Icons.hourglass_empty_rounded,
      title: 'No mapped tests found yet',
      description: 'The review may still be syncing. Refresh in a moment.',
      actionLabel: 'Refresh',
      onAction: onRetry,
    );
  }
}

class _ReviewStateBody extends StatelessWidget {
  const _ReviewStateBody({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: PrescriptionFlowTheme.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: PrescriptionFlowTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: PrescriptionFlowTheme.primary,
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PrescriptionFlowTheme.text,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkPrescriptionViewer extends StatelessWidget {
  const _NetworkPrescriptionViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(80),
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const CircularProgressIndicator(
                        color: Colors.white,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .58),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
