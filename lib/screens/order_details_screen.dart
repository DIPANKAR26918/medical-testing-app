import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

const Color _pageBackground = PrescriptionFlowTheme.background;
const Color _surface = PrescriptionFlowTheme.surface;

const Color _ink = PrescriptionFlowTheme.ink;
const Color _text = PrescriptionFlowTheme.text;
const Color _muted = PrescriptionFlowTheme.muted;

const Color _primary = PrescriptionFlowTheme.primary;
const Color _primarySoft = PrescriptionFlowTheme.primaryContainer;

const Color _success = PrescriptionFlowTheme.success;
const Color _successSoft = PrescriptionFlowTheme.successContainer;
const Color _successLine = Color(0xFF9BD3AE);

const Color _danger = PrescriptionFlowTheme.danger;
const Color _border = PrescriptionFlowTheme.outline;
const Color _futureLine = Color(0xFFDCE4EE);

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({required this.order, super.key});

  final Order order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<String>? _signedUrlFuture;
  Future<List<PrescriptionOrderTest>>? _prescriptionTestsFuture;
  late Order _currentOrder;
  Set<String> _selectedTestIds = <String>{};
  int _recommendationCount = 0;
  bool _confirming = false;

  Order get order => _currentOrder;
  bool get _isAwaitingApproval =>
      _normalizeStatus(order.status) == 'awaiting_user_approval';

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _preparePrescriptionUrl();
    _preparePrescriptionTests();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    _currentOrder = widget.order;

    if (oldWidget.order.prescriptionImagePath !=
        widget.order.prescriptionImagePath) {
      _preparePrescriptionUrl();
    }

    if (oldWidget.order.status != widget.order.status ||
        oldWidget.order.orderId != widget.order.orderId) {
      _preparePrescriptionTests();
    }
  }

  void _preparePrescriptionUrl() {
    final path = order.prescriptionImagePath.trim();

    if (path.isEmpty) {
      _signedUrlFuture = null;
      return;
    }

    _signedUrlFuture = _storageService.createSignedUrl(
      path,
      expiresInSeconds: 3600,
    );
  }

  void _preparePrescriptionTests() {
    if (!_isAwaitingApproval) {
      _prescriptionTestsFuture = null;
      _selectedTestIds = <String>{};
      _recommendationCount = 0;
      return;
    }

    final future = _firestoreService.fetchPrescriptionTests(order.orderId);
    _prescriptionTestsFuture = future;
    future.then((tests) {
      if (!mounted || _prescriptionTestsFuture != future) return;
      setState(() {
        _recommendationCount = tests.length;
        _selectedTestIds = tests
            .where((item) => item.selectedByUser)
            .map((item) => item.test.id)
            .toSet();
        if (_selectedTestIds.isEmpty) {
          _selectedTestIds = tests.map((item) => item.test.id).toSet();
        }
      });
    });
  }

  void _toggleTest(String testId, bool selected) {
    if (_confirming) return;
    setState(() {
      if (selected) {
        _selectedTestIds.add(testId);
      } else {
        _selectedTestIds.remove(testId);
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_confirming) return;
    if (_selectedTestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one test to confirm the booking.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _confirming = true);
    try {
      final confirmed = await _firestoreService.confirmPrescriptionBooking(
        order.orderId,
        _selectedTestIds,
      );
      if (!mounted) return;
      setState(() {
        _currentOrder = confirmed;
        _confirming = false;
        _prescriptionTestsFuture = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed. We’ll arrange sample collection.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAllUpdates() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrackingUpdatesScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(order.status);
    final stageTimes = _buildStageTimes(order);
    final stageEvents = _buildStageEvents(order);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton.filledTonal(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: _surface,
              foregroundColor: _ink,
              side: const BorderSide(color: _border),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order details',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Request #${order.orderId}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            _isAwaitingApproval ? 132 : 44,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompactTrackingCard(
                presentation: presentation,
                stageTimes: stageTimes,
                orderId: order.orderId,
                onSeeAllUpdates: _openAllUpdates,
              ),
              const SizedBox(height: 26),

              if (_signedUrlFuture != null) ...[
                _PrescriptionPreview(
                  signedUrlFuture: _signedUrlFuture!,
                  heroTag:
                      'prescription-${order.orderId}-${order.createdAt.microsecondsSinceEpoch}',
                ),
                const SizedBox(height: 24),
              ],

              if (_isAwaitingApproval && _prescriptionTestsFuture != null)
                FutureBuilder<List<PrescriptionOrderTest>>(
                  future: _prescriptionTestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _ApprovalLoadingCard();
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return _ApprovalErrorCard(
                        onRetry: () => setState(_preparePrescriptionTests),
                      );
                    }
                    return _PrescriptionApprovalSection(
                      recommendations: snapshot.data!,
                      selectedIds: _selectedTestIds,
                      onChanged: _toggleTest,
                    );
                  },
                )
              else
                _TestListSection(
                  tests: order.testList,
                  price: order.price,
                  status: order.status,
                ),

              if (order.patientLocationAddress?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 20),
                _CollectionAddressSection(order: order),
              ],

              if (stageEvents.isNotEmpty) const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isAwaitingApproval
          ? _ApprovalBottomBar(
              selectedCount: _selectedTestIds.length,
              totalCount: _recommendationCount,
              confirming: _confirming,
              onConfirm: _confirmBooking,
            )
          : null,
    );
  }
}

/// Compact Flipkart-style tracker.
///
/// Only the current stage and next stage are shown here.
/// The complete timeline opens on another screen.
class _CompactTrackingCard extends StatelessWidget {
  const _CompactTrackingCard({
    required this.presentation,
    required this.stageTimes,
    required this.orderId,
    required this.onSeeAllUpdates,
  });

  final _OrderStatusPresentation presentation;
  final Map<int, DateTime> stageTimes;
  final String orderId;
  final VoidCallback onSeeAllUpdates;

  @override
  Widget build(BuildContext context) {
    final currentIndex = presentation.stageIndex.clamp(
      0,
      _trackingStages.length - 1,
    );

    final isLastStage = currentIndex == _trackingStages.length - 1;

    final firstIndex = isLastStage ? _trackingStages.length - 2 : currentIndex;

    final secondIndex = isLastStage
        ? _trackingStages.length - 1
        : currentIndex + 1;

    final firstState = isLastStage
        ? _CompactStepState.completed
        : _CompactStepState.current;

    final secondState = isLastStage
        ? _CompactStepState.current
        : _CompactStepState.future;

    final firstTime = stageTimes[firstIndex];
    final secondTime = stageTimes[secondIndex];
    final currentStage = _trackingStages[currentIndex];
    final statusColor = presentation.isCancelled ? _danger : _success;
    final statusContainer = presentation.isCancelled
        ? const Color(0xFFFFECEB)
        : _successSoft;

    return Semantics(
      container: true,
      label:
          'Request $orderId. ${presentation.title}. Step ${currentIndex + 1} of ${_trackingStages.length}.',
      child: Container(
        width: double.infinity,
        decoration: _surfaceDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: statusContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          presentation.isCancelled
                              ? Icons.cancel_outlined
                              : currentStage.icon,
                          color: statusColor,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'CURRENT STATUS',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primarySoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'STEP ${currentIndex + 1} OF ${_trackingStages.length}',
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              presentation.title,
                              style: TextStyle(
                                color: presentation.isCancelled
                                    ? _danger
                                    : _ink,
                                fontSize: 18.5,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    presentation.description,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 13,
                      height: 1.48,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
                    decoration: BoxDecoration(
                      color: PrescriptionFlowTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CompactStage(
                            stage: _trackingStages[firstIndex],
                            state: firstState,
                            time: firstTime,
                            isCancelled: presentation.isCancelled,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: _border,
                        ),
                        Expanded(
                          child: _CompactStage(
                            stage: _trackingStages[secondIndex],
                            state: secondState,
                            time: secondTime,
                            isCancelled: presentation.isCancelled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSeeAllUpdates,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, color: _primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View full timeline',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 13.5,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CompactStepState { completed, current, future }

class _CompactStage extends StatelessWidget {
  const _CompactStage({
    required this.stage,
    required this.state,
    required this.time,
    required this.isCancelled,
  });

  final _TrackingStage stage;
  final _CompactStepState state;
  final DateTime? time;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _CompactStepState.current;
    final isCompleted = state == _CompactStepState.completed;

    final titleColor = isCurrent
        ? isCancelled
              ? _danger
              : _success
        : isCompleted
        ? _ink
        : _muted;

    final stateLabel = isCurrent
        ? 'NOW'
        : isCompleted
        ? 'DONE'
        : 'NEXT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stateLabel,
          style: TextStyle(
            color: isCurrent ? titleColor : _muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.65,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            if (isCurrent)
              _ActiveRippleMarker(color: isCancelled ? _danger : _success)
            else if (isCompleted)
              const _CompletedMarker()
            else
              const _FutureMarker(),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stage.shortTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11.8,
                  height: 1.2,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isCurrent
              ? time == null
                    ? 'In progress'
                    : _formatCompactDateTime(time!)
              : isCompleted
              ? time == null
                    ? 'Completed'
                    : _formatCompactDateTime(time!)
              : 'Starts next',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _muted,
            fontSize: 9.9,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Separate full tracking page.
///
/// This timeline is deliberately not placed inside a card.
class TrackingUpdatesScreen extends StatelessWidget {
  const TrackingUpdatesScreen({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(order.status);
    final stageTimes = _buildStageTimes(order);
    final stageEvents = _buildStageEvents(order);
    final currentIndex = presentation.stageIndex.clamp(
      0,
      _trackingStages.length - 1,
    );

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton.filledTonal(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: _surface,
              foregroundColor: _ink,
              side: const BorderSide(color: _border),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking updates',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Request #${order.orderId}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 44),
          children: [
            _TrackingSummaryCard(
              presentation: presentation,
              currentIndex: currentIndex,
              updatedAt: stageTimes[currentIndex] ?? order.createdAt,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              decoration: _surfaceDecoration(radius: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TimelineSectionHeader(),
                  const SizedBox(height: 22),
                  ...List.generate(_trackingStages.length, (index) {
                    final stage = _trackingStages[index];
                    final currentStage = presentation.stageIndex;

                    return _FullTimelineRow(
                      stage: stage,
                      stepNumber: index + 1,
                      isCompleted: index < currentStage,
                      isCurrent: index == currentStage,
                      isLast: index == _trackingStages.length - 1,
                      time: stageTimes[index],
                      events: stageEvents[index] ?? const [],
                      isCancelled:
                          presentation.isCancelled && index == currentStage,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TrackingNotificationCard(
              currentIndex: currentIndex,
              isCancelled: presentation.isCancelled,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingSummaryCard extends StatelessWidget {
  const _TrackingSummaryCard({
    required this.presentation,
    required this.currentIndex,
    required this.updatedAt,
  });

  final _OrderStatusPresentation presentation;
  final int currentIndex;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final stage = _trackingStages[currentIndex];
    final accent = presentation.isCancelled ? _danger : _success;
    final accentContainer = presentation.isCancelled
        ? const Color(0xFFFFECEB)
        : _successSoft;
    final progress = (currentIndex + 1) / _trackingStages.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accentContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  presentation.isCancelled ? Icons.cancel_outlined : stage.icon,
                  color: accent,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        presentation.isCancelled
                            ? 'CANCELLED'
                            : 'CURRENT • STEP ${currentIndex + 1} OF ${_trackingStages.length}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      presentation.title,
                      style: TextStyle(
                        color: presentation.isCancelled ? _danger : _ink,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            presentation.description,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: accent,
              backgroundColor: _futureLine,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(Icons.update_rounded, color: _muted, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Updated ${_formatDateTime(updatedAt)}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w600,
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

class _TimelineSectionHeader extends StatelessWidget {
  const _TimelineSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _TimelineHeaderIcon(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your booking journey',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Every important update, in one place',
                style: TextStyle(
                  color: _text,
                  fontSize: 11.8,
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

class _TimelineHeaderIcon extends StatelessWidget {
  const _TimelineHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.route_outlined, color: _primary, size: 21),
    );
  }
}

class _TrackingNotificationCard extends StatelessWidget {
  const _TrackingNotificationCard({
    required this.currentIndex,
    required this.isCancelled,
  });

  final int currentIndex;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final isComplete = currentIndex == _trackingStages.length - 1;
    final nextStage = isComplete ? null : _trackingStages[currentIndex + 1];
    final title = isCancelled
        ? 'Need help with this request?'
        : isComplete
        ? 'Your journey is complete'
        : 'No need to keep checking';
    final description = isCancelled
        ? 'Contact support if you need help with the cancellation.'
        : isComplete
        ? 'Your report is available from the Reports tab.'
        : 'We’ll notify you when ${nextStage!.title.toLowerCase()} starts.';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: PrescriptionFlowTheme.card(
        color: _primarySoft,
        borderColor: PrescriptionFlowTheme.primaryOutline,
        radius: 20,
        shadow: false,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: _primary,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 11.7,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
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

class _FullTimelineRow extends StatelessWidget {
  const _FullTimelineRow({
    required this.stage,
    required this.stepNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.time,
    required this.events,
    required this.isCancelled,
  });

  final _TrackingStage stage;
  final int stepNumber;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final DateTime? time;
  final List<_TrackingEvent> events;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final titleColor = isCurrent
        ? isCancelled
              ? _danger
              : _success
        : isCompleted
        ? _ink
        : _text;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (isCompleted)
                  const _CompletedMarker()
                else if (isCurrent)
                  _ActiveRippleMarker(color: isCancelled ? _danger : _success)
                else
                  _NumberedFutureMarker(number: stepNumber),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? _successLine : _futureLine,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 18),
              child: Container(
                padding: isCurrent
                    ? const EdgeInsets.fromLTRB(13, 12, 13, 12)
                    : const EdgeInsets.fromLTRB(2, 1, 2, 2),
                decoration: isCurrent
                    ? BoxDecoration(
                        color: isCancelled
                            ? const Color(0xFFFFF4F3)
                            : _successSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCancelled
                              ? const Color(0xFFFBCBC7)
                              : const Color(0xFFBFE5CA),
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            stage.title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              height: 1.26,
                              fontWeight: isCurrent
                                  ? FontWeight.w900
                                  : isCompleted
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCancelled ? _danger : _success,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isCancelled ? 'CANCELLED' : 'CURRENT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isCompleted || isCurrent) ...[
                      if (events.isNotEmpty)
                        ...events.map(
                          (event) => _TimelineEventView(event: event),
                        )
                      else ...[
                        const SizedBox(height: 7),
                        Text(
                          stage.description,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 12.3,
                            height: 1.43,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _formatDateTime(time!),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10.8,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        stage.futureDescription,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.8,
                          height: 1.42,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEventView extends StatelessWidget {
  const _TimelineEventView({required this.event});

  final _TrackingEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.message.isNotEmpty)
            Text(
              event.message,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                height: 1.46,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (event.time != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDateTime(event.time!),
              style: const TextStyle(
                color: _muted,
                fontSize: 11.4,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated green wave/ripple marker for the running stage.
class _ActiveRippleMarker extends StatefulWidget {
  const _ActiveRippleMarker({this.color = _success});

  final Color color;

  @override
  State<_ActiveRippleMarker> createState() => _ActiveRippleMarkerState();
}

class _ActiveRippleMarkerState extends State<_ActiveRippleMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _waveScale;
  late final Animation<double> _waveOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      // একবার wave + শেষে ছোট pause
      duration: const Duration(milliseconds: 2100),
    )..repeat();

    /*
      0%–72% সময়ের মধ্যে wave expand এবং disappear করবে।
      বাকি 28% সময় কোনো wave থাকবে না।
      এরপর পরের cycle শুরু হবে।
    */
    final waveCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );

    _waveScale = Tween<double>(begin: 0.55, end: 1.30).animate(waveCurve);

    _waveOpacity = Tween<double>(begin: 0.28, end: 0.0).animate(waveCurve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!disableAnimations)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Wave শেষ হওয়ার পর pause phase-এ invisible থাকবে
                final isPausePhase = _controller.value > 0.72;

                if (isPausePhase) {
                  return const SizedBox.shrink();
                }

                return Transform.scale(
                  scale: _waveScale.value,
                  child: Opacity(
                    opacity: _waveOpacity.value,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Main running dot
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.20),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedMarker extends StatelessWidget {
  const _CompletedMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      decoration: const BoxDecoration(color: _success, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
    );
  }
}

class _FutureMarker extends StatelessWidget {
  const _FutureMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD2DAE5), width: 1.6),
      ),
    );
  }
}

class _NumberedFutureMarker extends StatelessWidget {
  const _NumberedFutureMarker({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: _muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrescriptionPreview extends StatelessWidget {
  const _PrescriptionPreview({
    required this.signedUrlFuture,
    required this.heroTag,
  });

  final Future<String> signedUrlFuture;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Your prescription'),
        const SizedBox(height: 12),

        FutureBuilder<String>(
          future: signedUrlFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _PrescriptionLoadingCard();
            }

            if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const _PrescriptionErrorCard();
            }

            final imageUrl = snapshot.data!;

            return Semantics(
              button: true,
              label: 'Open uploaded prescription preview',
              child: Container(
                decoration: _surfaceDecoration(radius: 22),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _FullScreenPrescriptionViewer(
                            imageUrl: imageUrl,
                            heroTag: heroTag,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        height: 138,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 112,
                              height: 138,
                              child: Hero(
                                tag: heroTag,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        filterQuality: FilterQuality.high,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }

                                              return const ColoredBox(
                                                color: PrescriptionFlowTheme
                                                    .surfaceMuted,
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: _primary,
                                                          strokeWidth: 2.2,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const _ImageError();
                                            },
                                      ),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.58,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.open_in_full_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(1, 7, 8, 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PrivateFileLabel(),
                                    SizedBox(height: 10),
                                    Text(
                                      'Prescription uploaded',
                                      maxLines: 2,
                                      style: TextStyle(
                                        color: _ink,
                                        fontSize: 14.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Securely stored and visible only to your care team.',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 11.5,
                                        height: 1.38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          'Open preview',
                                          style: TextStyle(
                                            color: _primary,
                                            fontSize: 11.8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: _primary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PrivateFileLabel extends StatelessWidget {
  const _PrivateFileLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, color: _primary, size: 12),
          SizedBox(width: 4),
          Text(
            'PRIVATE FILE',
            style: TextStyle(
              color: _primary,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionLoadingCard extends StatelessWidget {
  const _PrescriptionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      width: double.infinity,
      decoration: _surfaceDecoration(radius: 22),
      child: const Center(
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2.3),
        ),
      ),
    );
  }
}

class _PrescriptionErrorCard extends StatelessWidget {
  const _PrescriptionErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: _surfaceDecoration(radius: 22),
      child: const Column(
        children: [
          Icon(Icons.image_not_supported_outlined, color: _muted, size: 31),
          SizedBox(height: 10),
          Text(
            'Prescription preview unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'The file is safe. Reopen this order to refresh the preview.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _text, fontSize: 12.3, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _pageBackground,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: _muted, size: 34),
      ),
    );
  }
}

class _FullScreenPrescriptionViewer extends StatelessWidget {
  const _FullScreenPrescriptionViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 42,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionApprovalSection extends StatelessWidget {
  const _PrescriptionApprovalSection({
    required this.recommendations,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<PrescriptionOrderTest> recommendations;
  final Set<String> selectedIds;
  final void Function(String testId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedTotal = recommendations
        .where((item) => selectedIds.contains(item.test.id))
        .fold<double>(0, (total, item) => total + (item.test.mrp ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review prescribed tests',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.28,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You stay in control—uncheck anything you do not want.',
                    style: TextStyle(color: _text, fontSize: 12.3, height: 1.4),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${selectedIds.length}/${recommendations.length}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF5DEAA)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF9A6700),
                size: 20,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Prepared from your prescription by a verified review agent. Confirm only after checking every test.',
                  style: TextStyle(
                    color: Color(0xFF6F4B00),
                    fontSize: 11.7,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        if (recommendations.isEmpty)
          const _ApprovalErrorCard()
        else
          for (var index = 0; index < recommendations.length; index++) ...[
            _ApprovalTestCard(
              recommendation: recommendations[index],
              selected: selectedIds.contains(recommendations[index].test.id),
              onChanged: (value) =>
                  onChanged(recommendations[index].test.id, value),
            ),
            if (index != recommendations.length - 1) const SizedBox(height: 9),
          ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: _surfaceDecoration(radius: 18),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected tests total',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Final slots and collection are arranged after confirmation.',
                      style: TextStyle(
                        color: _text,
                        fontSize: 10.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppHelpers.formatCurrency(selectedTotal),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApprovalTestCard extends StatelessWidget {
  const _ApprovalTestCard({
    required this.recommendation,
    required this.selected,
    required this.onChanged,
  });

  final PrescriptionOrderTest recommendation;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final test = recommendation.test;
    final style = medicalTestCategoryStyle(test.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? style.accent : _border,
              width: selected ? 1.4 : 1,
            ),
            color: selected ? style.soft.withValues(alpha: .45) : Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 74,
                child: MedicalTestArtwork(
                  test: test,
                  height: 84,
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
                        color: _ink,
                        fontSize: 13.8,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${test.sampleLabel}  •  ${test.reportLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      test.priceLabel,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalLoadingCard extends StatelessWidget {
  const _ApprovalLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: _surfaceDecoration(radius: 22),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.4),
            SizedBox(height: 12),
            Text(
              'Loading your reviewed test list…',
              style: TextStyle(color: _text, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalErrorCard extends StatelessWidget {
  const _ApprovalErrorCard({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 20),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 30),
          const SizedBox(height: 8),
          const Text(
            'The reviewed tests could not be loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectionAddressSection extends StatelessWidget {
  const _CollectionAddressSection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _surfaceDecoration(radius: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: _primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection address',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  order.patientLocationAddress!,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12.2,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Slot availability is confirmed after booking approval.',
                  style: TextStyle(
                    color: _success,
                    fontSize: 10.8,
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

class _ApprovalBottomBar extends StatelessWidget {
  const _ApprovalBottomBar({
    required this.selectedCount,
    required this.totalCount,
    required this.confirming,
    required this.onConfirm,
  });

  final int selectedCount;
  final int totalCount;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14121B31),
              blurRadius: 22,
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
                    '$selectedCount of $totalCount selected',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'No booking without your approval',
                    style: TextStyle(color: _text, fontSize: 10.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: confirming || selectedCount == 0 ? null : onConfirm,
                icon: confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(confirming ? 'Confirming…' : 'Confirm booking'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestListSection extends StatelessWidget {
  const _TestListSection({
    required this.tests,
    required this.price,
    required this.status,
  });

  final List<String> tests;
  final num price;
  final String status;

  @override
  Widget build(BuildContext context) {
    final hasTests = tests.isNotEmpty;
    final hasPrice = price > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Test list'),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            17,
            hasTests ? 8 : 18,
            17,
            hasTests ? 14 : 18,
          ),
          decoration: _surfaceDecoration(radius: 22),
          child: hasTests
              ? Column(
                  children: [
                    ...List.generate(tests.length, (index) {
                      final test = tests[index];

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: const BoxDecoration(
                                    color: _successSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: _success,
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      test,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 13.7,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (index != tests.length - 1)
                            const Divider(height: 1, color: _border),
                        ],
                      );
                    }),

                    if (hasPrice) ...[
                      const SizedBox(height: 7),
                      const Divider(height: 1, color: _border),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Estimated total',
                              style: TextStyle(
                                color: _text,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            AppHelpers.formatCurrency(price.toDouble()),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              : _PreparingTestList(status: status),
        ),
      ],
    );
  }
}

class _PreparingTestList extends StatelessWidget {
  const _PreparingTestList({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeStatus(status);
    final reviewStarted = const {
      'reviewing',
      'under_review',
      'processing',
      'prescription_reviewing',
      'prescription_processing',
    }.contains(normalized);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PreparingIcon(),
            const SizedBox(width: 13),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewStarted
                          ? 'Medical review is underway'
                          : 'Medical review is next',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A verified team member will map the prescribed tests. You’ll approve every test before booking.',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12.2,
                        height: 1.46,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PrescriptionFlowTheme.primaryOutline),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: _primary, size: 18),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'No action needed • We’ll notify you when the list is ready',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10.8,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreparingIcon extends StatelessWidget {
  const _PreparingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.medical_information_outlined,
        color: _primary,
        size: 23,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _TrackingStage {
  const _TrackingStage({
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.futureDescription,
    required this.icon,
  });

  final String title;
  final String shortTitle;
  final String description;
  final String futureDescription;
  final IconData icon;
}

const List<_TrackingStage> _trackingStages = [
  _TrackingStage(
    title: 'Prescription received',
    shortTitle: 'Received',
    description: 'Your prescription is safely uploaded.',
    futureDescription: 'Your prescription will appear here after it is sent.',
    icon: Icons.description_outlined,
  ),
  _TrackingStage(
    title: 'Medical review',
    shortTitle: 'Review',
    description: 'The medical team is mapping the prescribed tests.',
    futureDescription:
        'A verified team member will map the tests from your prescription.',
    icon: Icons.medical_information_outlined,
  ),
  _TrackingStage(
    title: 'Your approval',
    shortTitle: 'Approve',
    description: 'Review every mapped test before confirming the booking.',
    futureDescription:
        'You’ll approve the mapped tests before anything is booked.',
    icon: Icons.fact_check_outlined,
  ),
  _TrackingStage(
    title: 'Home collection',
    shortTitle: 'Collection',
    description: 'Collection details and executive updates will appear here.',
    futureDescription:
        'Collection details will appear after the booking is confirmed.',
    icon: Icons.home_work_outlined,
  ),
  _TrackingStage(
    title: 'Lab testing',
    shortTitle: 'Lab testing',
    description: 'Your sample is being tested by the diagnostic lab.',
    futureDescription: 'Your collected sample will be processed at the lab.',
    icon: Icons.science_outlined,
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Report',
    description: 'Your diagnostic report is ready to view and download.',
    futureDescription: 'Your completed report will appear in the app.',
    icon: Icons.description_rounded,
  ),
];

class _TrackingEvent {
  const _TrackingEvent({required this.message, required this.time});

  final String message;
  final DateTime? time;
}

class _OrderStatusPresentation {
  const _OrderStatusPresentation({
    required this.title,
    required this.description,
    required this.stageIndex,
    this.isCancelled = false,
  });

  final String title;
  final String description;
  final int stageIndex;
  final bool isCancelled;
}

_OrderStatusPresentation _presentationFor(String rawStatus) {
  final status = _normalizeStatus(rawStatus);

  switch (status) {
    case 'uploaded':
    case 'prescription_uploaded':
      return const _OrderStatusPresentation(
        title: 'Prescription received',
        description:
            'It’s safely uploaded. We’ll prepare the test list, and nothing is booked without your approval.',
        stageIndex: 0,
      );

    case 'reviewing':
    case 'under_review':
    case 'processing':
    case 'prescription_reviewing':
    case 'prescription_processing':
      return const _OrderStatusPresentation(
        title: 'Medical review underway',
        description:
            'A verified team member is mapping the prescribed tests for you to review.',
        stageIndex: 1,
      );

    case 'processed':
    case 'test_list_prepared':
    case 'tests_prepared':
    case 'awaiting_user_approval':
      return const _OrderStatusPresentation(
        title: 'Your test list is ready',
        description:
            'Review every mapped test and approve only what you want to book.',
        stageIndex: 2,
      );

    case 'booking_confirmed':
    case 'confirmed':
    case 'assigned_agent':
    case 'agent_assigned':
    case 'collection_agent_assigned':
    case 'agent_out_for_collection':
    case 'out_for_collection':
    case 'executive_on_the_way':
    case 'sample_collected':
    case 'collected':
      return _collectionPresentation(status);

    case 'sample_out_for_testing':
    case 'sample_in_transit':
    case 'sample_received_at_lab':
    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
    case 'sample_processed':
    case 'report_preparing':
    case 'report_in_making':
      return _labPresentation(status);

    case 'report_ready':
    case 'report_out_for_delivery':
      return const _OrderStatusPresentation(
        title: 'Your report is ready',
        description: 'Your diagnostic report is ready to view and download.',
        stageIndex: 5,
      );

    case 'report_delivered':
    case 'completed':
      return const _OrderStatusPresentation(
        title: 'Report delivered',
        description: 'Your diagnostic report has been delivered successfully.',
        stageIndex: 5,
      );

    case 'cancelled':
    case 'canceled':
      return const _OrderStatusPresentation(
        title: 'Order cancelled',
        description:
            'This order has been cancelled. Contact support if you need assistance.',
        stageIndex: 0,
        isCancelled: true,
      );

    default:
      return const _OrderStatusPresentation(
        title: 'Order in progress',
        description: 'We’ll update this page when the status changes.',
        stageIndex: 0,
      );
  }
}

_OrderStatusPresentation _collectionPresentation(String status) {
  switch (status) {
    case 'agent_assigned':
    case 'assigned_agent':
    case 'collection_agent_assigned':
      return const _OrderStatusPresentation(
        title: 'Collection executive assigned',
        description:
            'A collection executive has been assigned for your home collection.',
        stageIndex: 3,
      );

    case 'agent_out_for_collection':
    case 'out_for_collection':
    case 'executive_on_the_way':
      return const _OrderStatusPresentation(
        title: 'Executive is on the way',
        description:
            'Your collection executive is travelling to your selected address.',
        stageIndex: 3,
      );

    case 'sample_collected':
    case 'collected':
      return const _OrderStatusPresentation(
        title: 'Sample collected',
        description:
            'Your sample has been collected and is being sent to the lab.',
        stageIndex: 3,
      );

    default:
      return const _OrderStatusPresentation(
        title: 'Preparing sample collection',
        description:
            'Your booking is confirmed. Collection details will appear shortly.',
        stageIndex: 3,
      );
  }
}

_OrderStatusPresentation _labPresentation(String status) {
  switch (status) {
    case 'sample_out_for_testing':
    case 'sample_in_transit':
      return const _OrderStatusPresentation(
        title: 'Sample on the way to lab',
        description:
            'Your collected sample is being transported to the diagnostic lab.',
        stageIndex: 4,
      );

    case 'sample_received_at_lab':
      return const _OrderStatusPresentation(
        title: 'Sample received at lab',
        description:
            'Your sample has reached the lab and will be tested shortly.',
        stageIndex: 4,
      );

    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
      return const _OrderStatusPresentation(
        title: 'Sample under testing',
        description: 'Your sample is currently being processed by the lab.',
        stageIndex: 4,
      );

    default:
      return const _OrderStatusPresentation(
        title: 'Report being prepared',
        description: 'Testing is complete and your report is being prepared.',
        stageIndex: 4,
      );
  }
}

Map<int, DateTime> _buildStageTimes(Order order) {
  final stageTimes = <int, DateTime>{0: order.createdAt};

  for (final entry in order.timeline) {
    final rawStatus = entry['status']?.toString() ?? '';
    final timestamp = _parseTimelineTime(entry['timestamp']);

    if (rawStatus.isEmpty || timestamp == null) {
      continue;
    }

    final stage = _presentationFor(rawStatus).stageIndex;
    final existing = stageTimes[stage];

    if (existing == null || timestamp.isAfter(existing)) {
      stageTimes[stage] = timestamp;
    }
  }

  return stageTimes;
}

Map<int, List<_TrackingEvent>> _buildStageEvents(Order order) {
  final events = <int, List<_TrackingEvent>>{};

  for (final entry in order.timeline) {
    final rawStatus = entry['status']?.toString() ?? '';
    final message = entry['message']?.toString().trim() ?? '';
    final time = _parseTimelineTime(entry['timestamp']);

    if (rawStatus.isEmpty) {
      continue;
    }

    final stageIndex = _presentationFor(rawStatus).stageIndex;

    events.putIfAbsent(stageIndex, () => <_TrackingEvent>[]);

    events[stageIndex]!.add(_TrackingEvent(message: message, time: time));
  }

  for (final stageEvents in events.values) {
    stageEvents.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;

      return a.time!.compareTo(b.time!);
    });
  }

  return events;
}

DateTime? _parseTimelineTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

String _normalizeStatus(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _formatCompactDateTime(DateTime value) {
  final date = value.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month - 1]}, '
      '$hour:$minute $period';
}

String _formatDateTime(DateTime value) {
  final date = value.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month - 1]} '
      '${date.year}, $hour:$minute $period';
}

BoxDecoration _surfaceDecoration({double radius = 20}) {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF17213A).withValues(alpha: 0.035),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
