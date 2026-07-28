import 'dart:async';

import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../services/direct_booking_service.dart';
import '../utils/index.dart';
import '../utils/location_display_formatter.dart';
import '../widgets/collection_slot_picker.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';
import 'prescription_review_screen.dart';

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
  const OrderDetailsScreen({
    required this.order,
    this.liveUpdates = true,
    super.key,
  });

  final Order order;
  final bool liveUpdates;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  StorageService? _storageService;
  FirestoreService? _firestoreService;

  Future<String>? _signedUrlFuture;
  Future<List<PrescriptionOrderTest>>? _prescriptionTestsFuture;
  late Order _currentOrder;
  StreamSubscription<Order?>? _orderSubscription;
  Set<String> _selectedTestIds = <String>{};
  int _recommendationCount = 0;
  bool _confirming = false;
  bool _schedulingSlot = false;

  Order get order => _currentOrder;
  bool get _isAwaitingApproval =>
      order.isPrescriptionBooking &&
      _normalizeStatus(order.status) == 'awaiting_user_approval';

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _preparePrescriptionUrl();
    _preparePrescriptionTests();
    if (widget.liveUpdates) _subscribeToOrder();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final orderChanged = oldWidget.order.orderId != widget.order.orderId;
    _currentOrder = widget.order;

    if (oldWidget.order.prescriptionImagePath !=
        widget.order.prescriptionImagePath) {
      _preparePrescriptionUrl();
    }

    if (oldWidget.order.status != widget.order.status ||
        orderChanged) {
      _preparePrescriptionTests();
    }

    if (orderChanged && widget.liveUpdates) _subscribeToOrder();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToOrder() {
    _orderSubscription?.cancel();
    _orderSubscription = (_firestoreService ??= FirestoreService())
        .streamOrder(order.orderId)
        .listen((updatedOrder) {
          if (!mounted || updatedOrder == null) return;

          final prescriptionChanged =
              updatedOrder.prescriptionImagePath !=
              _currentOrder.prescriptionImagePath;
          final statusChanged = updatedOrder.status != _currentOrder.status;

          setState(() => _currentOrder = updatedOrder);
          if (prescriptionChanged) {
            _preparePrescriptionUrl();
          }
          if (statusChanged) {
            _preparePrescriptionTests();
          }
        });
  }

  void _preparePrescriptionUrl() {
    final path = order.prescriptionImagePath.trim();

    if (path.isEmpty) {
      _signedUrlFuture = null;
      return;
    }

    _signedUrlFuture = (_storageService ??= StorageService()).createSignedUrl(
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

    final future = (_firestoreService ??= FirestoreService())
        .fetchPrescriptionTests(order.orderId);
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
    setState(() => _confirming = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PrescriptionReviewScreen(order: order),
      ),
    );
    if (mounted) setState(() => _confirming = false);
  }

  Future<void> _scheduleDirectSlot() async {
    if (_schedulingSlot) return;
    final selected = await showCollectionSlotPicker(
      context,
      current: order.collectionSlot,
      labVisit: order.isLabVisit,
    );
    if (!mounted || selected == null) return;

    setState(() => _schedulingSlot = true);
    try {
      final updated = await DirectBookingService().scheduleExistingBooking(
        orderId: order.orderId,
        collectionSlot: selected,
      );
      if (!mounted) return;
      setState(() => _currentOrder = updated);
    } on DirectBookingException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _schedulingSlot = false);
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
    final trackingStages = _trackingStagesFor(order);
    final presentation = _presentationFor(
      order.status,
      directBooking: order.isDirectTestBooking,
      labVisit: order.isLabVisit,
    );
    final stageTimes = _buildStageTimes(order);
    final hasCollectionAddress =
        !order.isLabVisit &&
        order.patientLocationAddress?.trim().isNotEmpty == true;
    final showCollectionDetails =
        order.collectionSlot != null ||
        order.isDirectTestBooking ||
        hasCollectionAddress;
    final waitingForDirectSlot =
        order.isDirectTestBooking &&
        order.collectionSlot == null &&
        presentation.title == 'Choose your appointment slot';

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
          color: _ink,
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        titleSpacing: 0,
        title: const Text(
          'Order details',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            _isAwaitingApproval ? 132 : 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.isDirectTestBooking && order.testList.isNotEmpty) ...[
                _TestListSection(
                  tests: order.testList,
                  price: order.price,
                  isDirectBooking: true,
                ),
                const SizedBox(height: 16),
              ],

              if (order.isPrescriptionBooking &&
                  _signedUrlFuture != null) ...[
                _PrescriptionPreview(
                  signedUrlFuture: _signedUrlFuture!,
                  heroTag:
                      'prescription-${order.orderId}-${order.createdAt.microsecondsSinceEpoch}',
                ),
                const SizedBox(height: 16),
              ],

              if (showCollectionDetails)
                _CollectionDetailsSection(
                  order: order,
                  schedulingSlot: _schedulingSlot,
                  onChooseSlot: _scheduleDirectSlot,
                ),

              if (!waitingForDirectSlot) ...[
                if (showCollectionDetails) const SizedBox(height: 20),
                const _SectionTitle(title: 'Booking progress'),
                const SizedBox(height: 8),
                _CompactTrackingCard(
                  presentation: presentation,
                  trackingStages: trackingStages,
                  stageTimes: stageTimes,
                  onSeeAllUpdates: _openAllUpdates,
                ),
              ],

              if (_isAwaitingApproval && _prescriptionTestsFuture != null) ...[
                const SizedBox(height: 20),
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
                ),
              ] else if (order.isPrescriptionBooking &&
                  order.testList.isNotEmpty) ...[
                const SizedBox(height: 20),
                _TestListSection(
                  tests: order.testList,
                  price: order.price,
                  isDirectBooking: false,
                ),
              ],

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
    required this.trackingStages,
    required this.stageTimes,
    required this.onSeeAllUpdates,
  });

  final _OrderStatusPresentation presentation;
  final List<_TrackingStage> trackingStages;
  final Map<int, DateTime> stageTimes;
  final VoidCallback onSeeAllUpdates;

  @override
  Widget build(BuildContext context) {
    final currentIndex = presentation.stageIndex.clamp(
      0,
      trackingStages.length - 1,
    );
    final currentStage = trackingStages[currentIndex];
    final currentTime = stageTimes[currentIndex];
    final nextStage = currentIndex < trackingStages.length - 1
        ? trackingStages[currentIndex + 1]
        : null;
    final statusColor = presentation.isCancelled ? _danger : _success;
    final statusContainer = presentation.isCancelled
        ? const Color(0xFFFFECEB)
        : _successSoft;
    final nextLabel = presentation.isCancelled
        ? 'Request closed'
        : nextStage == null
        ? 'Journey complete'
        : 'Next: ${nextStage.shortTitle}';
    final detailLabel = currentTime == null
        ? nextLabel
        : '${_formatCompactDateTime(currentTime)} • $nextLabel';
    final progress = presentation.isCancelled
        ? 0.0
        : (currentIndex + 1) / trackingStages.length;

    return Semantics(
      container: true,
      label:
          '${presentation.title}. Step ${currentIndex + 1} of ${trackingStages.length}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 9),
        decoration: _quietSurfaceDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    presentation.isCancelled
                        ? Icons.cancel_outlined
                        : currentStage.icon,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presentation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: presentation.isCancelled ? _danger : _ink,
                            fontSize: 16.5,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          presentation.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 12.2,
                            height: 1.42,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: _futureLine,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    detailLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.8,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllUpdates,
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.only(left: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'View timeline',
                    style: TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Separate full tracking page.
///
/// This timeline is deliberately not placed inside a card.
class TrackingUpdatesScreen extends StatefulWidget {
  const TrackingUpdatesScreen({
    required this.order,
    this.liveUpdates = true,
    super.key,
  });

  final Order order;
  final bool liveUpdates;

  @override
  State<TrackingUpdatesScreen> createState() => _TrackingUpdatesScreenState();
}

class _TrackingUpdatesScreenState extends State<TrackingUpdatesScreen> {
  late Order _order;
  StreamSubscription<Order?>? _subscription;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (widget.liveUpdates) _subscribe();
  }

  @override
  void didUpdateWidget(covariant TrackingUpdatesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderId == widget.order.orderId) return;
    _order = widget.order;
    if (widget.liveUpdates) _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = FirestoreService()
        .streamOrder(_order.orderId)
        .listen((updated) {
          if (!mounted || updated == null) return;
          setState(() => _order = updated);
        });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final trackingStages = _trackingStagesFor(order);
    final presentation = _presentationFor(
      order.status,
      directBooking: order.isDirectTestBooking,
      labVisit: order.isLabVisit,
    );
    final stageTimes = _buildStageTimes(order);
    final stageEvents = _buildStageEvents(order);
    final currentIndex = presentation.stageIndex.clamp(
      0,
      trackingStages.length - 1,
    );

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
          color: _ink,
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        titleSpacing: 0,
        title: const Text(
          'Tracking updates',
          style: TextStyle(
            color: _ink,
            fontSize: 19,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _TrackingSummaryCard(
              presentation: presentation,
              stage: trackingStages[currentIndex],
              totalSteps: trackingStages.length,
              currentIndex: currentIndex,
              updatedAt: stageTimes[currentIndex] ?? order.createdAt,
            ),
            const SizedBox(height: 22),
            _TimelineSectionHeader(
              directBooking: order.isDirectTestBooking,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              decoration: PrescriptionFlowTheme.card(
                color: _surface,
                borderColor: _border,
                radius: 20,
                shadow: false,
              ),
              child: Column(
                children: List.generate(trackingStages.length, (index) {
                  final stage = trackingStages[index];

                  return _FullTimelineRow(
                    stage: stage,
                    stepNumber: index + 1,
                    isCompleted: index < currentIndex,
                    isCurrent: index == currentIndex,
                    isLast: index == trackingStages.length - 1,
                    time: stageTimes[index],
                    events: stageEvents[index] ?? const [],
                    isCancelled:
                        presentation.isCancelled && index == currentIndex,
                  );
                }),
              ),
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
    required this.stage,
    required this.totalSteps,
    required this.currentIndex,
    required this.updatedAt,
  });

  final _OrderStatusPresentation presentation;
  final _TrackingStage stage;
  final int totalSteps;
  final int currentIndex;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final accent = presentation.isCancelled ? _danger : _success;
    final accentContainer = presentation.isCancelled
        ? const Color(0xFFFFECEB)
        : _successSoft;
    final progress = (currentIndex + 1) / totalSteps;

    return Semantics(
      container: true,
      label:
          '${presentation.title}. Step ${currentIndex + 1} of $totalSteps.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PrescriptionFlowTheme.card(
          color: _surface,
          borderColor: _border,
          radius: 20,
          shadow: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    presentation.isCancelled
                        ? Icons.cancel_outlined
                        : stage.icon,
                    color: accent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.isCancelled
                            ? 'REQUEST CANCELLED'
                            : 'STEP ${currentIndex + 1} OF $totalSteps',
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: presentation.isCancelled ? _danger : _ink,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              presentation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 12.2,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: accent,
                backgroundColor: _futureLine,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: _muted, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Updated ${_formatDateTime(updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSectionHeader extends StatelessWidget {
  const _TimelineSectionHeader({required this.directBooking});

  final bool directBooking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking journey',
            style: TextStyle(
              color: _ink,
              fontSize: 16.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            directBooking
                ? 'Your booking moves straight to collection and lab testing.'
                : 'We’ll notify you when the next step begins.',
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
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
    final accent = isCancelled ? _danger : _success;
    final titleColor = isCurrent
        ? accent
        : isCompleted
        ? _ink
        : _text;
    final latestEvent = events.isEmpty ? null : events.last;
    final latestMessage = latestEvent?.message.trim();
    final currentDescription = latestMessage == null || latestMessage.isEmpty
        ? stage.description
        : latestMessage;
    final detailTime = latestEvent?.time ?? time;
    final stateLabel = isCurrent
        ? isCancelled
              ? 'Cancelled'
              : 'Current'
        : isCompleted
        ? 'Completed'
        : 'Upcoming';

    return Semantics(
      container: true,
      label: 'Step $stepNumber, ${stage.title}, $stateLabel',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  if (isCompleted)
                    const _CompletedMarker()
                  else if (isCurrent)
                    _ActiveRippleMarker(color: accent)
                  else
                    _NumberedFutureMarker(number: stepNumber),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
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
                padding: EdgeInsets.only(top: 3, bottom: isLast ? 18 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stage.title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14.5,
                              height: 1.25,
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
                          Text(
                            stateLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 5),
                      Text(
                        currentDescription,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 11.8,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (detailTime != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          _formatDateTime(detailTime),
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.3,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ] else if (isCompleted && detailTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(detailTime),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10.3,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
        const _SectionTitle(title: 'Prescription'),
        const SizedBox(height: 8),
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
                decoration: _quietSurfaceDecoration(radius: 18),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
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
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 72,
                            child: Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
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
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: _primary,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const _ImageError();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View prescription',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 14.2,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      color: _muted,
                                      size: 13,
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Private • Care team only',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _text,
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _muted,
                            size: 22,
                          ),
                        ],
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

class _PrescriptionLoadingCard extends StatelessWidget {
  const _PrescriptionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: _surfaceDecoration(radius: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(radius: 20),
      child: const Row(
        children: [
          Icon(Icons.image_not_supported_outlined, color: _muted, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview unavailable',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Reopen this order to refresh the secure file.',
                  style: TextStyle(color: _text, fontSize: 11.8, height: 1.35),
                ),
              ],
            ),
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
    final selectedTests = recommendations
        .where((item) => selectedIds.contains(item.test.id))
        .map((item) => item.test);
    final selectedMrpTotal = selectedTests.totalMrp;
    final selectedTotal = selectedTests.totalSellingPrice;

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
              SizedBox(
                width: 122,
                child: DiscountedPrice(
                  mrp: selectedMrpTotal,
                  sellingPrice: selectedTotal,
                  showMrpLabel: false,
                  mrpFontSize: 9.8,
                  priceFontSize: 19,
                  priceColor: _ink,
                  alignment: WrapAlignment.end,
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
                    MedicalTestPrice(
                      test: test,
                      showMrpLabel: false,
                      mrpFontSize: 9.2,
                      priceFontSize: 14,
                      priceColor: _ink,
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

class _CollectionDetailsSection extends StatelessWidget {
  const _CollectionDetailsSection({
    required this.order,
    required this.schedulingSlot,
    required this.onChooseSlot,
  });

  final Order order;
  final bool schedulingSlot;
  final VoidCallback onChooseSlot;

  @override
  Widget build(BuildContext context) {
    final hasSlotRow =
        order.collectionSlot != null || order.isDirectTestBooking;
    final hasAddress =
        !order.isLabVisit &&
        order.patientLocationAddress?.trim().isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Collection details'),
        const SizedBox(height: 8),
        if (hasSlotRow)
          CollectionSlotPickerCard(
            slot: order.collectionSlot,
            labVisit: order.isLabVisit,
            onChoose: order.collectionSlot == null ? onChooseSlot : null,
            enabled: !schedulingSlot,
            showAction: order.collectionSlot == null,
          ),
        if (hasSlotRow && hasAddress) const SizedBox(height: 10),
        if (hasAddress) _CollectionAddressCard(order: order),
      ],
    );
  }
}

class _CollectionAddressCard extends StatelessWidget {
  const _CollectionAddressCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(
      order.status,
      directBooking: order.isDirectTestBooking,
      labVisit: order.isLabVisit,
    );
    final pendingCollection =
        !presentation.isCancelled &&
        presentation.stageIndex < (order.isDirectTestBooking ? 2 : 3);
    final readableAddress = stripLocationCodes(
      order.patientLocationAddress ?? '',
    );
    String? helperText;
    if (order.collectionSlot != null) {
      helperText = 'Pickup is scheduled for this address.';
    } else if (order.isDirectTestBooking) {
      helperText = 'Choose a collection slot to finish booking.';
    } else if (pendingCollection) {
      helperText = 'Choose a collection slot after your test list is ready.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _quietSurfaceDecoration(radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: _primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection address',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  readableAddress.isEmpty
                      ? 'Saved collection area'
                      : readableAddress,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    helperText,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.8,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
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
                label: Text(
                  confirming ? 'Opening…' : 'Choose slot & confirm',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTheme.fontFamily,
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

class _TestListSection extends StatelessWidget {
  const _TestListSection({
    required this.tests,
    required this.price,
    required this.isDirectBooking,
  });

  final List<String> tests;
  final num price;
  final bool isDirectBooking;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) return const SizedBox.shrink();

    final hasPrice = price > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: isDirectBooking
              ? tests.length == 1
                    ? 'Booked test'
                    : 'Booked tests'
              : 'Selected tests',
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDirectBooking ? _primarySoft : _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDirectBooking ? const Color(0xFFCADBFF) : _border,
              width: isDirectBooking ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              ...List.generate(tests.length, (index) {
                final test = tests[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _OrderTestArtwork(testName: test),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 14.2,
                                    height: 1.3,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  isDirectBooking
                                      ? 'Direct test booking'
                                      : 'Included in this booking',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != tests.length - 1)
                      const Divider(
                        height: 1,
                        indent: 82,
                        color: _border,
                      ),
                  ],
                );
              }),

              if (hasPrice) ...[
                const Divider(height: 1, color: _border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Booking total',
                          style: TextStyle(
                            color: _text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        AppHelpers.formatCurrency(price.toDouble()),
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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

class _OrderTestArtwork extends StatelessWidget {
  const _OrderTestArtwork({required this.testName});

  final String testName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6F5)),
      ),
      child: MedicalCategoryIllustration(
        category: testName,
        color: _primary,
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
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.15,
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
    title: 'Collection scheduled',
    shortTitle: 'Scheduled',
    description: 'Your selected collection slot is confirmed.',
    futureDescription:
        'Choose a collection slot while confirming the prepared tests.',
    icon: Icons.event_available_outlined,
  ),
  _TrackingStage(
    title: 'Agent on the way',
    shortTitle: 'On the way',
    description: 'Your collection agent is travelling to your location.',
    futureDescription: 'The agent will update you after leaving for collection.',
    icon: Icons.route_outlined,
  ),
  _TrackingStage(
    title: 'Sample collected',
    shortTitle: 'Collected',
    description: 'Your sample has been collected successfully.',
    futureDescription: 'The agent will confirm after collecting your sample.',
    icon: Icons.water_drop_outlined,
  ),
  _TrackingStage(
    title: 'Sample at lab',
    shortTitle: 'At lab',
    description: 'Your sample has reached the diagnostic lab.',
    futureDescription: 'The lab will confirm when it receives your sample.',
    icon: Icons.apartment_outlined,
  ),
  _TrackingStage(
    title: 'Sample processing',
    shortTitle: 'Processing',
    description: 'The diagnostic lab is processing your sample.',
    futureDescription: 'Testing begins after the lab receives your sample.',
    icon: Icons.science_outlined,
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Ready',
    description: 'Your diagnostic report is ready.',
    futureDescription: 'You’ll be notified as soon as the report is ready.',
    icon: Icons.description_rounded,
  ),
  _TrackingStage(
    title: 'Report on the way',
    shortTitle: 'Delivery',
    description: 'Your agent is travelling to deliver the report.',
    futureDescription: 'The agent will update you before report delivery.',
    icon: Icons.delivery_dining_outlined,
  ),
  _TrackingStage(
    title: 'Report delivered',
    shortTitle: 'Delivered',
    description: 'Your diagnostic report has been delivered.',
    futureDescription: 'Delivery confirmation will appear here.',
    icon: Icons.task_alt_rounded,
  ),
];

const List<_TrackingStage> _directTrackingStages = [
  _TrackingStage(
    title: 'Collection scheduled',
    shortTitle: 'Scheduled',
    description: 'Your test and selected appointment slot are confirmed.',
    futureDescription: 'Choose an appointment slot to finish booking.',
    icon: Icons.event_available_outlined,
  ),
  _TrackingStage(
    title: 'Agent assigned',
    shortTitle: 'Assigned',
    description: 'A verified agent has accepted your booking.',
    futureDescription: 'A verified agent will accept your scheduled booking.',
    icon: Icons.badge_outlined,
  ),
  _TrackingStage(
    title: 'Agent on the way',
    shortTitle: 'On the way',
    description: 'Your collection agent is travelling to your location.',
    futureDescription: 'The agent will update you after leaving for collection.',
    icon: Icons.route_outlined,
  ),
  _TrackingStage(
    title: 'Sample collected',
    shortTitle: 'Collected',
    description: 'Your sample has been collected successfully.',
    futureDescription: 'The agent will confirm after collecting your sample.',
    icon: Icons.water_drop_outlined,
  ),
  _TrackingStage(
    title: 'Sample at lab',
    shortTitle: 'At lab',
    description: 'Your sample has reached the diagnostic lab.',
    futureDescription: 'The lab will confirm when it receives your sample.',
    icon: Icons.apartment_outlined,
  ),
  _TrackingStage(
    title: 'Sample processing',
    shortTitle: 'Processing',
    description: 'The diagnostic lab is processing your sample.',
    futureDescription: 'Testing begins after the lab receives your sample.',
    icon: Icons.science_outlined,
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Ready',
    description: 'Your diagnostic report is ready.',
    futureDescription: 'You’ll be notified as soon as the report is ready.',
    icon: Icons.description_rounded,
  ),
  _TrackingStage(
    title: 'Report on the way',
    shortTitle: 'Delivery',
    description: 'Your agent is travelling to deliver the report.',
    futureDescription: 'The agent will update you before report delivery.',
    icon: Icons.delivery_dining_outlined,
  ),
  _TrackingStage(
    title: 'Report delivered',
    shortTitle: 'Delivered',
    description: 'Your diagnostic report has been delivered.',
    futureDescription: 'Delivery confirmation will appear here.',
    icon: Icons.task_alt_rounded,
  ),
];

const List<_TrackingStage> _prescriptionLabTrackingStages = [
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
    title: 'Lab appointment scheduled',
    shortTitle: 'Scheduled',
    description: 'Your selected lab appointment slot is confirmed.',
    futureDescription:
        'Choose a lab appointment while confirming the prepared tests.',
    icon: Icons.event_available_outlined,
  ),
  _TrackingStage(
    title: 'Agent assigned',
    shortTitle: 'Assigned',
    description: 'A verified agent has accepted your appointment.',
    futureDescription: 'A verified agent will accept your appointment.',
    icon: Icons.badge_outlined,
  ),
  _TrackingStage(
    title: 'Sample at lab',
    shortTitle: 'At lab',
    description: 'The diagnostic lab has received your sample.',
    futureDescription: 'The lab will confirm after receiving your sample.',
    icon: Icons.apartment_outlined,
  ),
  _TrackingStage(
    title: 'Sample processing',
    shortTitle: 'Processing',
    description: 'The diagnostic lab is processing your sample.',
    futureDescription: 'Testing begins after the lab receives your sample.',
    icon: Icons.science_outlined,
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Ready',
    description: 'Your diagnostic report is ready.',
    futureDescription: 'You’ll be notified as soon as the report is ready.',
    icon: Icons.description_rounded,
  ),
  _TrackingStage(
    title: 'Report on the way',
    shortTitle: 'Delivery',
    description: 'Your agent is travelling to deliver the report.',
    futureDescription: 'The agent will update you before report delivery.',
    icon: Icons.delivery_dining_outlined,
  ),
  _TrackingStage(
    title: 'Report delivered',
    shortTitle: 'Delivered',
    description: 'Your diagnostic report has been delivered.',
    futureDescription: 'Delivery confirmation will appear here.',
    icon: Icons.task_alt_rounded,
  ),
];

const List<_TrackingStage> _directLabTrackingStages = [
  _TrackingStage(
    title: 'Lab appointment scheduled',
    shortTitle: 'Scheduled',
    description: 'Your test and selected lab appointment are confirmed.',
    futureDescription: 'Choose a lab appointment slot to finish booking.',
    icon: Icons.event_available_outlined,
  ),
  _TrackingStage(
    title: 'Agent assigned',
    shortTitle: 'Assigned',
    description: 'A verified agent has accepted your appointment.',
    futureDescription: 'A verified agent will accept your appointment.',
    icon: Icons.badge_outlined,
  ),
  _TrackingStage(
    title: 'Sample at lab',
    shortTitle: 'At lab',
    description: 'The diagnostic lab has received your sample.',
    futureDescription: 'The lab will confirm after receiving your sample.',
    icon: Icons.apartment_outlined,
  ),
  _TrackingStage(
    title: 'Sample processing',
    shortTitle: 'Processing',
    description: 'The diagnostic lab is processing your sample.',
    futureDescription: 'Testing begins after the lab receives your sample.',
    icon: Icons.science_outlined,
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Ready',
    description: 'Your diagnostic report is ready.',
    futureDescription: 'You’ll be notified as soon as the report is ready.',
    icon: Icons.description_rounded,
  ),
  _TrackingStage(
    title: 'Report on the way',
    shortTitle: 'Delivery',
    description: 'Your agent is travelling to deliver the report.',
    futureDescription: 'The agent will update you before report delivery.',
    icon: Icons.delivery_dining_outlined,
  ),
  _TrackingStage(
    title: 'Report delivered',
    shortTitle: 'Delivered',
    description: 'Your diagnostic report has been delivered.',
    futureDescription: 'Delivery confirmation will appear here.',
    icon: Icons.task_alt_rounded,
  ),
];

List<_TrackingStage> _trackingStagesFor(Order order) {
  if (order.isDirectTestBooking) {
    return order.isLabVisit
        ? _directLabTrackingStages
        : _directTrackingStages;
  }
  return order.isLabVisit
      ? _prescriptionLabTrackingStages
      : _trackingStages;
}

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

_OrderStatusPresentation _presentationFor(
  String rawStatus, {
  bool directBooking = false,
  bool labVisit = false,
}) {
  if (directBooking) {
    return _directPresentationFor(rawStatus, labVisit: labVisit);
  }

  final status = _normalizeStatus(rawStatus);
  if (labVisit) {
    final labPresentation = _prescriptionLabPresentationFor(status);
    if (labPresentation != null) return labPresentation;
  }

  switch (status) {
    case 'uploaded':
    case 'prescription_uploaded':
      return const _OrderStatusPresentation(
        title: 'Prescription received',
        description:
            'Uploaded safely. We’ll prepare the test list for your approval.',
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
    case 'assigned':
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
      return const _OrderStatusPresentation(
        title: 'Your report is ready',
        description: 'Your diagnostic report is ready.',
        stageIndex: 8,
      );

    case 'report_out_for_delivery':
      return const _OrderStatusPresentation(
        title: 'Your report is on the way',
        description:
            'Your agent is travelling to your location with the report.',
        stageIndex: 9,
      );

    case 'report_delivered':
    case 'completed':
      return const _OrderStatusPresentation(
        title: 'Report delivered',
        description: 'Your diagnostic report has been delivered successfully.',
        stageIndex: 10,
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

_OrderStatusPresentation _directPresentationFor(
  String rawStatus, {
  bool labVisit = false,
}) {
  final status = _normalizeStatus(rawStatus);
  if (labVisit) {
    final labPresentation = _directLabPresentationFor(status);
    if (labPresentation != null) return labPresentation;
  }

  switch (status) {
    case 'booking_requested':
    case 'uploaded':
    case 'processing':
      return const _OrderStatusPresentation(
        title: 'Choose your appointment slot',
        description:
            'Your selected tests are saved. Choose a slot to finish booking.',
        stageIndex: 0,
      );

    case 'booking_confirmed':
    case 'confirmed':
      return const _OrderStatusPresentation(
        title: 'Collection scheduled',
        description:
            'Your tests and selected appointment slot are confirmed.',
        stageIndex: 0,
      );

    case 'assigned':
    case 'assigned_agent':
    case 'agent_assigned':
    case 'collection_agent_assigned':
      return const _OrderStatusPresentation(
        title: 'Collection executive assigned',
        description:
            'A collection executive has been assigned for your sample.',
        stageIndex: 1,
      );

    case 'agent_out_for_collection':
    case 'out_for_collection':
    case 'executive_on_the_way':
      return const _OrderStatusPresentation(
        title: 'Executive is on the way',
        description:
            'Your collection executive is travelling to your selected address.',
        stageIndex: 2,
      );

    case 'sample_collected':
    case 'collected':
      return const _OrderStatusPresentation(
        title: 'Sample collected',
        description: 'Your sample has been collected and is going to the lab.',
        stageIndex: 3,
      );

    case 'sample_out_for_testing':
    case 'sample_in_transit':
      return const _OrderStatusPresentation(
        title: 'Sample on the way to lab',
        description: 'Your sample is being transported to the diagnostic lab.',
        stageIndex: 3,
      );

    case 'sample_received_at_lab':
      return const _OrderStatusPresentation(
        title: 'Sample received at lab',
        description: 'Your sample has reached the lab for testing.',
        stageIndex: 4,
      );

    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
      return const _OrderStatusPresentation(
        title: 'Sample under testing',
        description: 'Your sample is currently being processed by the lab.',
        stageIndex: 5,
      );

    case 'sample_processed':
    case 'report_preparing':
    case 'report_in_making':
      return const _OrderStatusPresentation(
        title: 'Report being prepared',
        description: 'Testing is complete and your report is being prepared.',
        stageIndex: 5,
      );

    case 'report_ready':
      return const _OrderStatusPresentation(
        title: 'Your report is ready',
        description: 'Your diagnostic report is ready.',
        stageIndex: 6,
      );

    case 'report_out_for_delivery':
      return const _OrderStatusPresentation(
        title: 'Your report is on the way',
        description:
            'Your agent is travelling to your location with the report.',
        stageIndex: 7,
      );

    case 'report_delivered':
    case 'completed':
      return const _OrderStatusPresentation(
        title: 'Report delivered',
        description: 'Your diagnostic report has been delivered successfully.',
        stageIndex: 8,
      );

    case 'cancelled':
    case 'canceled':
      return const _OrderStatusPresentation(
        title: 'Booking cancelled',
        description:
            'This booking has been cancelled. Contact support if you need help.',
        stageIndex: 0,
        isCancelled: true,
      );

    default:
      return const _OrderStatusPresentation(
        title: 'Booking in progress',
        description: 'We’ll update this page when the status changes.',
        stageIndex: 0,
      );
  }
}

_OrderStatusPresentation? _prescriptionLabPresentationFor(String status) {
  switch (status) {
    case 'booking_confirmed':
    case 'confirmed':
      return const _OrderStatusPresentation(
        title: 'Lab appointment scheduled',
        description:
            'Your tests and selected lab appointment slot are confirmed.',
        stageIndex: 3,
      );

    case 'assigned':
    case 'assigned_agent':
    case 'agent_assigned':
    case 'collection_agent_assigned':
      return const _OrderStatusPresentation(
        title: 'Agent assigned',
        description:
            'A verified agent has accepted your lab appointment.',
        stageIndex: 4,
      );

    case 'sample_received_at_lab':
      return const _OrderStatusPresentation(
        title: 'Sample received at lab',
        description: 'The diagnostic lab has received your sample.',
        stageIndex: 5,
      );

    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
    case 'sample_processed':
    case 'report_preparing':
    case 'report_in_making':
      return const _OrderStatusPresentation(
        title: 'Sample under testing',
        description: 'Your sample is currently being processed by the lab.',
        stageIndex: 6,
      );

    case 'report_ready':
      return const _OrderStatusPresentation(
        title: 'Your report is ready',
        description: 'Your diagnostic report is ready.',
        stageIndex: 7,
      );

    case 'report_out_for_delivery':
      return const _OrderStatusPresentation(
        title: 'Your report is on the way',
        description:
            'Your agent is travelling to your location with the report.',
        stageIndex: 8,
      );

    case 'report_delivered':
    case 'completed':
      return const _OrderStatusPresentation(
        title: 'Report delivered',
        description: 'Your diagnostic report has been delivered successfully.',
        stageIndex: 9,
      );

    default:
      return null;
  }
}

_OrderStatusPresentation? _directLabPresentationFor(String status) {
  switch (status) {
    case 'booking_requested':
    case 'uploaded':
    case 'processing':
      return const _OrderStatusPresentation(
        title: 'Choose your lab appointment',
        description:
            'Your selected tests are saved. Choose a slot to finish booking.',
        stageIndex: 0,
      );

    case 'booking_confirmed':
    case 'confirmed':
      return const _OrderStatusPresentation(
        title: 'Lab appointment scheduled',
        description:
            'Your tests and selected lab appointment slot are confirmed.',
        stageIndex: 0,
      );

    case 'assigned':
    case 'assigned_agent':
    case 'agent_assigned':
    case 'collection_agent_assigned':
      return const _OrderStatusPresentation(
        title: 'Agent assigned',
        description:
            'A verified agent has accepted your lab appointment.',
        stageIndex: 1,
      );

    case 'sample_received_at_lab':
      return const _OrderStatusPresentation(
        title: 'Sample received at lab',
        description: 'The diagnostic lab has received your sample.',
        stageIndex: 2,
      );

    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
    case 'sample_processed':
    case 'report_preparing':
    case 'report_in_making':
      return const _OrderStatusPresentation(
        title: 'Sample under testing',
        description: 'Your sample is currently being processed by the lab.',
        stageIndex: 3,
      );

    case 'report_ready':
      return const _OrderStatusPresentation(
        title: 'Your report is ready',
        description: 'Your diagnostic report is ready.',
        stageIndex: 4,
      );

    case 'report_out_for_delivery':
      return const _OrderStatusPresentation(
        title: 'Your report is on the way',
        description:
            'Your agent is travelling to your location with the report.',
        stageIndex: 5,
      );

    case 'report_delivered':
    case 'completed':
      return const _OrderStatusPresentation(
        title: 'Report delivered',
        description: 'Your diagnostic report has been delivered successfully.',
        stageIndex: 6,
      );

    default:
      return null;
  }
}

_OrderStatusPresentation _collectionPresentation(String status) {
  switch (status) {
    case 'agent_assigned':
    case 'assigned':
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
        stageIndex: 4,
      );

    case 'sample_collected':
    case 'collected':
      return const _OrderStatusPresentation(
        title: 'Sample collected',
        description:
            'Your sample has been collected and is being sent to the lab.',
        stageIndex: 5,
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
        stageIndex: 5,
      );

    case 'sample_received_at_lab':
      return const _OrderStatusPresentation(
        title: 'Sample received at lab',
        description:
            'Your sample has reached the lab and will be tested shortly.',
        stageIndex: 6,
      );

    case 'sample_processing':
    case 'sample_testing':
    case 'testing':
      return const _OrderStatusPresentation(
        title: 'Sample under testing',
        description: 'Your sample is currently being processed by the lab.',
        stageIndex: 7,
      );

    default:
      return const _OrderStatusPresentation(
        title: 'Report being prepared',
        description: 'Testing is complete and your report is being prepared.',
        stageIndex: 7,
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

    final stage = _presentationFor(
      rawStatus,
      directBooking: order.isDirectTestBooking,
      labVisit: order.isLabVisit,
    ).stageIndex;
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

    final stageIndex = _presentationFor(
      rawStatus,
      directBooking: order.isDirectTestBooking,
      labVisit: order.isLabVisit,
    ).stageIndex;

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
  return AppTime.parseUtc(value);
}

String _normalizeStatus(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _formatCompactDateTime(DateTime value) {
  return AppTime.formatKolkataCompact(value);
}

String _formatDateTime(DateTime value) {
  return AppTime.formatKolkataFull(value);
}

BoxDecoration _quietSurfaceDecoration({double radius = 18}) {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _border),
  );
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
