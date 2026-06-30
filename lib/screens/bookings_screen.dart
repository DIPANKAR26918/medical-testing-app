import 'package:flutter/material.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({required this.onBookNewTest, super.key});

  final VoidCallback onBookNewTest;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;

  static const _upcomingBookings = [
    _BookingData(
      test: 'Complete Blood Count',
      patient: 'Self',
      date: 'Today',
      time: '7:30 PM',
      place: 'Home collection - Koramangala',
      status: 'Confirmed',
      note: 'Phlebotomist assigned',
      type: 'Home',
      price: 'Rs 319',
      color: _BookingPalette.red,
    ),
    _BookingData(
      test: 'Thyroid Profile',
      patient: 'Self',
      date: 'Tomorrow',
      time: '9:00 AM',
      place: 'Partner lab visit',
      status: 'Scheduled',
      note: 'Slot reserved',
      type: 'Lab',
      price: 'Rs 399',
      color: _BookingPalette.indigo,
    ),
  ];

  static const _completedBookings = [
    _BookingData(
      test: 'Liver Function Test',
      patient: 'Self',
      date: '18 Jun',
      time: '8:15 AM',
      place: 'Home collection',
      status: 'Done',
      note: 'Report ready',
      type: 'Home',
      price: 'Rs 449',
      color: _BookingPalette.blue,
    ),
    _BookingData(
      test: 'Vitamin D Test',
      patient: 'Self',
      date: '02 Jun',
      time: '10:30 AM',
      place: 'Testified partner lab',
      status: 'Done',
      note: 'Report ready',
      type: 'Lab',
      price: 'Rs 599',
      color: _BookingPalette.amber,
    ),
  ];

  List<_BookingData> get _visibleBookings {
    return _selectedTab == 0 ? _upcomingBookings : _completedBookings;
  }

  void _showAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _visibleBookings;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
      children: [
        _BookingsHeader(onBookNewTest: widget.onBookNewTest),
        const SizedBox(height: 14),
        _NextCollectionCard(
          booking: _upcomingBookings.first,
          onCall: () => _showAction('Care team will call you shortly'),
          onTrack: () => _showAction('Tracking will open here'),
        ),
        const SizedBox(height: 10),
        const _BookingAssuranceStrip(),
        const SizedBox(height: 18),
        const _PickupPrepCard(),
        const SizedBox(height: 18),
        _BookingTabs(
          selectedIndex: _selectedTab,
          upcomingCount: _upcomingBookings.length,
          completedCount: _completedBookings.length,
          onChanged: (index) => setState(() => _selectedTab = index),
        ),
        const SizedBox(height: 14),
        _SectionTitle(
          title: _selectedTab == 0 ? 'Upcoming' : 'Completed',
          subtitle: _selectedTab == 0
              ? 'Track your home collection and lab visits.'
              : 'Past bookings with report-ready actions.',
        ),
        const SizedBox(height: 10),
        for (final booking in bookings) ...[
          _BookingCard(
            booking: booking,
            completed: _selectedTab == 1,
            onPrimaryTap: () => _showAction(
              _selectedTab == 0
                  ? 'Tracking will open here'
                  : 'Report will open here',
            ),
            onSecondaryTap: () => _showAction(
              _selectedTab == 0
                  ? 'Care team will call you shortly'
                  : 'Report shared',
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        _BookMoreCard(onBookNewTest: widget.onBookNewTest),
      ],
    );
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader({required this.onBookNewTest});

  final VoidCallback onBookNewTest;

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
                'Bookings',
                style: TextStyle(
                  color: _BookingPalette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Home sample pickups and lab visits, tracked clearly.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _BookingPalette.muted,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: onBookNewTest,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _BookingPalette.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _NextCollectionCard extends StatelessWidget {
  const _NextCollectionCard({
    required this.booking,
    required this.onCall,
    required this.onTrack,
  });

  final _BookingData booking;
  final VoidCallback onCall;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_BookingPalette.heroStart, _BookingPalette.heroEnd],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _BookingPalette.mintBorder),
        boxShadow: [
          BoxShadow(
            color: _BookingPalette.blue.withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LightPill(text: 'Next home collection'),
              const Spacer(),
              Icon(
                Icons.verified_rounded,
                color: _BookingPalette.trustTeal,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                'Verified collector',
                style: const TextStyle(
                  color: _BookingPalette.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            booking.test,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingPalette.ink,
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.date}, ${booking.time} | ${booking.place}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingPalette.muted,
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const _CollectionProgress(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroActionButton(
                  label: 'Call',
                  icon: Icons.call_rounded,
                  filled: false,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroActionButton(
                  label: 'Track pickup',
                  icon: Icons.map_rounded,
                  filled: true,
                  onTap: onTrack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _ProgressStep(label: 'Booked', active: true)),
        _ProgressLine(active: true),
        Expanded(child: _ProgressStep(label: 'Assigned', active: true)),
        _ProgressLine(active: false),
        Expanded(child: _ProgressStep(label: 'Collected', active: false)),
      ],
    );
  }
}

class _BookingAssuranceStrip extends StatelessWidget {
  const _BookingAssuranceStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _surfaceDecoration(shadow: false),
      child: const Row(
        children: [
          Expanded(
            child: _AssuranceItem(
              icon: Icons.badge_rounded,
              label: 'ID verified',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _AssuranceItem(
              icon: Icons.clean_hands_rounded,
              label: 'Sterile kit',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _AssuranceItem(
              icon: Icons.receipt_long_rounded,
              label: 'Digital invoice',
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupPrepCard extends StatelessWidget {
  const _PickupPrepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _BookingPalette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_rounded, color: _BookingPalette.blue),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before pickup',
                  style: TextStyle(
                    color: _BookingPalette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Keep your prescription ready. For fasting tests, water is okay.',
                  style: TextStyle(
                    color: _BookingPalette.muted,
                    fontSize: 12.5,
                    height: 1.35,
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

class _BookingTabs extends StatelessWidget {
  const _BookingTabs({
    required this.selectedIndex,
    required this.upcomingCount,
    required this.completedCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int upcomingCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: _surfaceDecoration(shadow: false),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Upcoming',
              count: upcomingCount,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: 'Completed',
              count: completedCount,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.completed,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final _BookingData booking;
  final bool completed;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: booking.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science_rounded, color: booking.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.test,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingPalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.patient} | ${booking.type} | ${booking.price}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: booking.status, color: booking.color),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(
            icon: Icons.schedule_rounded,
            text: '${booking.date}, ${booking.time}',
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.location_on_rounded, text: booking.place),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.info_rounded, text: booking.note),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondaryTap,
                  icon: Icon(
                    completed ? Icons.ios_share_rounded : Icons.call_rounded,
                    size: 18,
                  ),
                  label: Text(completed ? 'Share' : 'Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _BookingPalette.teal,
                    side: const BorderSide(color: _BookingPalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPrimaryTap,
                  icon: Icon(
                    completed ? Icons.description_rounded : Icons.map_rounded,
                    size: 18,
                  ),
                  label: Text(completed ? 'Report' : 'Track'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _BookingPalette.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
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

class _BookMoreCard extends StatelessWidget {
  const _BookMoreCard({required this.onBookNewTest});

  final VoidCallback onBookNewTest;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onBookNewTest,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _BookingPalette.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_circle_rounded, color: _BookingPalette.teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Book another low-cost lab test at home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _BookingPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _BookingPalette.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _BookingPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _BookingPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: selected ? _BookingPalette.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$label ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _BookingPalette.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _BookingPalette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return SizedBox(
      height: 44,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BookingPalette.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: _BookingPalette.teal,
                side: const BorderSide(color: _BookingPalette.border),
                shape: shape,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: active
                ? _BookingPalette.teal
                : Colors.white.withValues(alpha: .80),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? _BookingPalette.teal : _BookingPalette.border,
            ),
          ),
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? _BookingPalette.ink : _BookingPalette.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: active ? _BookingPalette.teal : _BookingPalette.border,
    );
  }
}

class _AssuranceItem extends StatelessWidget {
  const _AssuranceItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _BookingPalette.trustTeal, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingPalette.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _BookingPalette.border,
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _BookingPalette.blue.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _BookingPalette.blue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BookingData {
  const _BookingData({
    required this.test,
    required this.patient,
    required this.date,
    required this.time,
    required this.place,
    required this.status,
    required this.note,
    required this.type,
    required this.price,
    required this.color,
  });

  final String test;
  final String patient;
  final String date;
  final String time;
  final String place;
  final String status;
  final String note;
  final String type;
  final String price;
  final Color color;
}

class _BookingPalette {
  const _BookingPalette._();

  static const Color heroStart = Color(0xFFF8FCFF);
  static const Color heroEnd = Color(0xFFEFF8FB);
  static const Color mintBorder = Color(0xFFD8E5EF);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF0E9FA6);
  static const Color blue = Color(0xFF2563EB);
  static const Color trustTeal = Color(0xFF2D8C92);
  static const Color amber = Color(0xFFD97706);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color red = Color(0xFFE11D48);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 8)),
];

BoxDecoration _surfaceDecoration({bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _BookingPalette.border),
    boxShadow: shadow ? _softShadow : null,
  );
}
