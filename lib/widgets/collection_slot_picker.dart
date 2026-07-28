import 'package:flutter/material.dart';

import '../models/collection_slot.dart';
import '../utils/app_time.dart';

Future<CollectionSlot?> showCollectionSlotPicker(
  BuildContext context, {
  CollectionSlot? current,
  required bool labVisit,
}) async {
  final today = AppTime.kolkataToday();
  final initialDate = current == null
      ? _firstDateWithAvailability(today)
      : AppTime.toKolkataClock(current.startUtc);
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    ),
    firstDate: today,
    lastDate: today.add(const Duration(days: 30)),
    helpText: labVisit
        ? 'SELECT LAB APPOINTMENT DATE'
        : 'SELECT COLLECTION DATE',
  );
  if (!context.mounted || pickedDate == null) return null;

  return showModalBottomSheet<CollectionSlot>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _TimeWindowSheet(
      date: pickedDate,
      labVisit: labVisit,
      selected: current,
    ),
  );
}

DateTime _firstDateWithAvailability(DateTime today) {
  final hasTodaySlot = _availableSlots(today).isNotEmpty;
  return hasTodaySlot ? today : today.add(const Duration(days: 1));
}

List<CollectionSlot> _availableSlots(DateTime date) {
  final earliest = AppTime.nowUtc().add(const Duration(minutes: 30));
  return const <int>[7, 9, 11, 15, 17]
      .map(
        (hour) => CollectionSlot.forKolkataDate(date, startHour: hour),
      )
      .where((slot) => !slot.startUtc.isBefore(earliest))
      .toList(growable: false);
}

class CollectionSlotPickerCard extends StatelessWidget {
  const CollectionSlotPickerCard({
    required this.slot,
    required this.labVisit,
    this.onChoose,
    this.enabled = true,
    this.showAction = true,
    super.key,
  });

  final CollectionSlot? slot;
  final bool labVisit;
  final VoidCallback? onChoose;
  final bool enabled;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final selected = slot;
    final title = labVisit ? 'Lab appointment slot' : 'Sample collection slot';
    final interactive = enabled && showAction && onChoose != null;
    final accent = selected == null
        ? const Color(0xFFB54708)
        : const Color(0xFF16834B);
    final accentSurface = selected == null
        ? const Color(0xFFFFF7E6)
        : const Color(0xFFECFDF3);

    return Semantics(
      button: interactive,
      label: selected == null
          ? '$title not selected'
          : '$title ${selected.fullLabel}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: interactive ? onChoose : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    labVisit
                        ? Icons.event_available_outlined
                        : Icons.home_work_outlined,
                    color: accent,
                    size: 23,
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
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        selected == null
                            ? 'Choose the day and two-hour window before booking.'
                            : selected.dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          selected.timeLabel,
                          style: TextStyle(
                            color: accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (showAction)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: interactive
                          ? const Color(0xFFEEF4FF)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      selected == null ? 'Choose' : 'Change',
                      style: TextStyle(
                        color: interactive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF98A2B3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: accent,
                      size: 22,
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

class _TimeWindowSheet extends StatelessWidget {
  const _TimeWindowSheet({
    required this.date,
    required this.labVisit,
    required this.selected,
  });

  final DateTime date;
  final bool labVisit;
  final CollectionSlot? selected;

  @override
  Widget build(BuildContext context) {
    final slots = _availableSlots(date);
    final dateLabel = AppTime.formatKolkata(
      AppTime.fromKolkataWallClock(date, hour: 12),
      pattern: 'EEEE, d MMMM',
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: ListView(
          key: const ValueKey('collection-slot-list'),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          children: [
            Text(
              labVisit ? 'Choose appointment time' : 'Choose collection time',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$dateLabel · all times in IST',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No more slots are available on this date. Go back and choose another day.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              )
            else
              for (var index = 0; index < slots.length; index++) ...[
                _SlotOption(
                  slot: slots[index],
                  selected:
                      selected?.startUtc.isAtSameMomentAs(
                        slots[index].startUtc,
                      ) ==
                      true,
                ),
                if (index != slots.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _SlotOption extends StatelessWidget {
  const _SlotOption({required this.slot, required this.selected});

  final CollectionSlot slot;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEEF4FF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pop(context, slot),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  slot.timeLabel,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'Available',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
