import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/medical_test_catalog/medical_test_catalog_widgets.dart';

const Color _pageBackground = Color(0xFFF8FAFD);
const Color _surface = Color(0xFFFFFFFF);

const Color _ink = Color(0xFF12172B);
const Color _text = Color(0xFF64748B);
const Color _muted = Color(0xFF94A3B8);

const Color _primary = Color(0xFF2F67F5);
const Color _primarySoft = Color(0xFFEEF4FF);

const Color _success = Color(0xFF16A34A);
const Color _successSoft = Color(0xFFECFDF3);
const Color _successLine = Color(0xFF86D6A0);

const Color _danger = Color(0xFFDC3545);
//const Color _dangerSoft = Color(0xFFFFEFF1);

const Color _border = Color(0xFFE3E9F2);
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
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
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
        leadingWidth: 58,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 25),
        ),
        titleSpacing: 2,
        title: const Text(
          'Order details',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            _isAwaitingApproval ? 132 : 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompactTrackingCard(
                presentation: presentation,
                stageTimes: stageTimes,
                onSeeAllUpdates: _openAllUpdates,
              ),
              const SizedBox(height: 24),

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
                _TestListSection(tests: order.testList, price: order.price),

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
    required this.onSeeAllUpdates,
  });

  final _OrderStatusPresentation presentation;
  final Map<int, DateTime> stageTimes;
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

    return Container(
      width: double.infinity,
      decoration: _surfaceDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.title,
                  style: TextStyle(
                    color: presentation.isCancelled ? _danger : _ink,
                    fontSize: 18,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  presentation.description,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    height: 1.48,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
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

                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 7,
                        right: 7,
                      ),
                      child: Container(
                        width: 68,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isLastStage ? _successLine : _futureLine,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
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
              ],
            ),
          ),

          const Divider(height: 1, color: _border),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSeeAllUpdates,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all updates',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
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

    return Column(
      children: [
        if (isCurrent)
          _ActiveRippleMarker(color: isCancelled ? _danger : _success)
        else if (isCompleted)
          const _CompletedMarker()
        else
          const _FutureMarker(),

        const SizedBox(height: 10),

        Text(
          stage.shortTitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 12.2,
            height: 1.25,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          isCurrent
              ? time == null
                    ? 'In progress'
                    : _formatCompactDateTime(time!)
              : isCompleted
              ? time == null
                    ? 'Completed'
                    : _formatCompactDateTime(time!)
              : 'Next',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _muted,
            fontSize: 10.8,
            height: 1.2,
            fontWeight: FontWeight.w500,
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

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 25),
        ),
        titleSpacing: 2,
        title: const Text(
          'Tracking updates',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
          children: [
            Text(
              presentation.title,
              style: TextStyle(
                color: presentation.isCancelled ? _danger : _ink,
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              presentation.description,
              style: const TextStyle(
                color: _text,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),

            ...List.generate(_trackingStages.length, (index) {
              final stage = _trackingStages[index];
              final currentStage = presentation.stageIndex;

              final isCompleted = index < currentStage;
              final isCurrent = index == currentStage;
              final isLast = index == _trackingStages.length - 1;

              return _FullTimelineRow(
                stage: stage,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: isLast,
                time: stageTimes[index],
                events: stageEvents[index] ?? const [],
                isCancelled: presentation.isCancelled && isCurrent,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FullTimelineRow extends StatelessWidget {
  const _FullTimelineRow({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.time,
    required this.events,
    required this.isCancelled,
  });

  final _TrackingStage stage;
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
        : const Color(0xFF8B96A8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                const _FutureMarker(),

              if (!isLast)
                Container(
                  width: 2,
                  height: _connectorHeight(
                    isCurrent: isCurrent,
                    hasEvents: events.isNotEmpty,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? _successLine : _futureLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2, bottom: isLast ? 4 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    height: 1.28,
                    fontWeight: isCurrent
                        ? FontWeight.w800
                        : isCompleted
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),

                if (isCompleted || isCurrent) ...[
                  if (events.isNotEmpty)
                    ...events.map((event) => _TimelineEventView(event: event))
                  else ...[
                    const SizedBox(height: 8),
                    Text(
                      stage.description,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        height: 1.46,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDateTime(time!),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ] else ...[
                  const SizedBox(height: 7),
                  Text(
                    stage.futureDescription,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.7,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _connectorHeight({required bool isCurrent, required bool hasEvents}) {
    if (isCurrent && hasEvents) {
      return 110;
    }

    if (isCurrent) {
      return 90;
    }

    return 70;
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
        const _SectionTitle(title: 'Uploaded prescription'),
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
              label: 'View uploaded prescription',
              child: GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: _surfaceDecoration(radius: 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: Hero(
                        tag: heroTag,
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
                                      color: _pageBackground,
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: _primary,
                                            strokeWidth: 2.3,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const _ImageError();
                              },
                            ),

                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.03),
                                      Colors.black.withValues(alpha: 0.28),
                                    ],
                                    stops: const [0, 0.62, 1],
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 13,
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tap to view prescription',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.42,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.open_in_full_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ],
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

class _PrescriptionLoadingCard extends StatelessWidget {
  const _PrescriptionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
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
            'Please try opening this order again.',
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
                    style: TextStyle(
                      color: _text,
                      fontSize: 12.3,
                      height: 1.4,
                    ),
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
              onChanged: (value) => onChanged(
                recommendations[index].test.id,
                value,
              ),
            ),
            if (index != recommendations.length - 1)
              const SizedBox(height: 9),
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
            color: selected
                ? style.soft.withValues(alpha: .45)
                : Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test, size: 44),
              const SizedBox(width: 11),
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
  const _TestListSection({required this.tests, required this.price});

  final List<String> tests;
  final num price;

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
              : const _PreparingTestList(),
        ),
      ],
    );
  }
}

class _PreparingTestList extends StatelessWidget {
  const _PreparingTestList();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreparingIcon(),
        SizedBox(width: 13),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your test list is being prepared',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You’ll be able to review the required tests before confirming your booking.',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12.5,
                    height: 1.48,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.playlist_add_check_circle_outlined,
        color: _primary,
        size: 22,
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
        fontSize: 17,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
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
  });

  final String title;
  final String shortTitle;
  final String description;
  final String futureDescription;
}

const List<_TrackingStage> _trackingStages = [
  _TrackingStage(
    title: 'Prescription uploaded',
    shortTitle: 'Uploaded',
    description: 'Your prescription was received successfully.',
    futureDescription: 'Your prescription will appear here after upload.',
  ),
  _TrackingStage(
    title: 'Test list preparation',
    shortTitle: 'Test list',
    description: 'The medical team is identifying the required tests.',
    futureDescription:
        'The required test list will be prepared from your prescription.',
  ),
  _TrackingStage(
    title: 'Review & confirm',
    shortTitle: 'Review',
    description: 'Review the prepared test list before confirming the booking.',
    futureDescription:
        'You will review and approve the prepared tests before booking.',
  ),
  _TrackingStage(
    title: 'Sample collection',
    shortTitle: 'Collection',
    description:
        'Your collection executive and collection updates will appear here.',
    futureDescription:
        'Collection details will appear after the booking is confirmed.',
  ),
  _TrackingStage(
    title: 'Lab processing',
    shortTitle: 'Lab testing',
    description: 'Your sample is being processed by the diagnostic lab.',
    futureDescription: 'Your collected sample will be processed at the lab.',
  ),
  _TrackingStage(
    title: 'Report ready',
    shortTitle: 'Report',
    description: 'Your diagnostic report is ready to view and download.',
    futureDescription: 'Your completed report will appear in the app.',
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
        title: 'Prescription uploaded',
        description:
            'We received your prescription. Review will begin shortly.',
        stageIndex: 0,
      );

    case 'reviewing':
    case 'under_review':
    case 'processing':
    case 'prescription_reviewing':
    case 'prescription_processing':
      return const _OrderStatusPresentation(
        title: 'Test list being prepared',
        description:
            'Our medical team is identifying the required tests from your prescription.',
        stageIndex: 1,
      );

    case 'processed':
    case 'test_list_prepared':
    case 'tests_prepared':
    case 'awaiting_user_approval':
      return const _OrderStatusPresentation(
        title: 'Test list ready for review',
        description:
            'Review the prepared tests before confirming your booking.',
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
