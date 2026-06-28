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
      color: _BookingPalette.teal,
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
      color: _BookingPalette.blue,
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
      color: _BookingPalette.green,
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
      color: _BookingPalette.green,
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
        _Header(onBookNewTest: widget.onBookNewTest),
        const SizedBox(height: 18),
        _NextBookingCard(
          booking: _upcomingBookings.first,
          onCall: () => _showAction('Care team will call you shortly'),
          onTrack: () => _showAction('Tracking will open here'),
        ),
        const SizedBox(height: 14),
        const _TrustStrip(),
        const SizedBox(height: 18),
        _BookingTabs(
          selectedIndex: _selectedTab,
          upcomingCount: _upcomingBookings.length,
          completedCount: _completedBookings.length,
          onChanged: (index) => setState(() => _selectedTab = index),
        ),
        const SizedBox(height: 14),
        _SectionHeader(
          title: _selectedTab == 0 ? 'Upcoming bookings' : 'Past bookings',
          subtitle: _selectedTab == 0
              ? 'Clear updates for each visit.'
              : 'Completed tests and reports.',
        ),
        const SizedBox(height: 10),
        for (final booking in bookings) ...[
          _BookingCard(
            booking: booking,
            onPrimaryTap: () => _showAction(
              _selectedTab == 0 ? 'Tracking will open here' : 'Report will open here',
            ),
            onSecondaryTap: () => _showAction(
              _selectedTab == 0 ? 'Care team will call you shortly' : 'Report shared',
            ),
            completed: _selectedTab == 1,
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedTab == 0) ...[
          const SizedBox(height: 4),
          const _PrepCard(),
          const SizedBox(height: 12),
          const _HelpCard(),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBookNewTest});

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
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your lab visits, home collections, and simple updates.',
                style: TextStyle(
                  color: _BookingPalette.muted,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
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

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({
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
        color: _BookingPalette.deep,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _BookingPalette.deep.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LightChip(label: 'Next booking'),
              const Spacer(),
              Icon(Icons.verified_rounded, color: Colors.white.withValues(alpha: .82), size: 20),
              const SizedBox(width: 5),
              Text(
                'Verified lab',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .76),
                  fontSize: 12,
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
              color: Colors.white,
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.note,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .74),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroInfo(
                  icon: Icons.schedule_rounded,
                  label: '${booking.date}, ${booking.time}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroInfo(
                  icon: Icons.location_on_rounded,
                  label: booking.place,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DarkCardButton(
                  label: 'Call',
                  icon: Icons.call_rounded,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LightCardButton(
                  label: 'Track',
                  icon: Icons.map_rounded,
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

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_rounded,
              label: 'Verified labs',
              color: _BookingPalette.teal,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.clean_hands_rounded,
              label: 'Sterile kit',
              color: _BookingPalette.green,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.notifications_active_rounded,
              label: 'Live updates',
              color: _BookingPalette.blue,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _BookingPalette.border),
        boxShadow: _softShadow,
      ),
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
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.completed,
  });

  final _BookingData booking;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
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
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${booking.patient} - ${booking.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingPalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Chip(label: booking.status, color: booking.color),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(icon: Icons.schedule_rounded, text: '${booking.date}, ${booking.time}'),
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
                  icon: Icon(completed ? Icons.ios_share_rounded : Icons.call_rounded, size: 18),
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
                  icon: Icon(completed ? Icons.description_rounded : Icons.map_rounded, size: 18),
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

class _PrepCard extends StatelessWidget {
  const _PrepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFF0FDF4)),
      child: const Row(
        children: [
          Icon(Icons.fact_check_rounded, color: _BookingPalette.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'For fasting tests, avoid food for 10-12 hours. Water is okay.',
              style: TextStyle(
                color: Color(0xFF164E43),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFEFF6FF)),
      child: const Row(
        children: [
          Icon(Icons.support_agent_rounded, color: _BookingPalette.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Need help with a booking? Our care team is here.',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: .78), size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _BookingPalette.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
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
      height: 42,
      color: _BookingPalette.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _LightChip extends StatelessWidget {
  const _LightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

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

class _DarkCardButton extends StatelessWidget {
  const _DarkCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: .34)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _LightCardButton extends StatelessWidget {
  const _LightCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _BookingPalette.deep,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
  final Color color;
}

class _BookingPalette {
  const _BookingPalette._();

  static const Color deep = Color(0xFF063B4C);
  static const Color ink = Color(0xFF0B2538);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF087E86);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF0F766E);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Color(0x09000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _BookingPalette.border),
    boxShadow: _softShadow,
  );
}
