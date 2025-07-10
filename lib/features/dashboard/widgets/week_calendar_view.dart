import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarEvent {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final Color color;
  final bool isAllDay;

  CalendarEvent({
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.color = const Color(0xFF6366F1),
    this.isAllDay = false,
  });
}

class WeekCalendarView extends StatefulWidget {
  final List<CalendarEvent> events;
  final DateTime? initialDate;
  final Function(DateTime)? onDateTap;
  final Function(CalendarEvent)? onEventTap;
  final double hourHeight;
  final int startHour;
  final int endHour;

  const WeekCalendarView({
    Key? key,
    required this.events,
    this.initialDate,
    this.onDateTap,
    this.onEventTap,
    this.hourHeight = 60.0,
    this.startHour = 0,
    this.endHour = 24,
  }) : super(key: key);

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  late DateTime _currentWeek;
  late ScrollController _scrollController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.initialDate ?? DateTime.now();
    _scrollController = ScrollController();
    _pageController = PageController();

    // Auto-scroll to current time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (currentHour >= widget.startHour && currentHour < widget.endHour) {
      final scrollPosition = (currentHour - widget.startHour) * widget.hourHeight +
          (currentMinute / 60) * widget.hourHeight - 100;

      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeek = _currentWeek.add(const Duration(days: 7));
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeek = _currentWeek.subtract(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _currentWeek = DateTime.now();
    });
    _scrollToCurrentTime();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return widget.events.where((event) {
      final eventDate = DateTime(event.start.year, event.start.month, event.start.day);
      final dayDate = DateTime(day.year, day.month, day.day);
      return eventDate.isAtSameMomentAs(dayDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(_currentWeek);
    final today = DateTime.now();
    final todayFormatted = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        // Header with navigation
        _buildHeader(),

        // Week days header
        _buildWeekHeader(weekDates, todayFormatted),

        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(weekDates, todayFormatted),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Month/Year display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentWeek),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Week of ${DateFormat('MMM d').format(_getWeekDates(_currentWeek).first)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              // Today button
              TextButton(
                onPressed: _goToToday,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Previous week
              IconButton(
                onPressed: _goToPreviousWeek,
                icon: const Icon(Icons.chevron_left, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),

              // Next week
              IconButton(
                onPressed: _goToNextWeek,
                icon: const Icon(Icons.chevron_right, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(List<DateTime> weekDates, DateTime today) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Time column header
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'GMT',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Day columns
          ...weekDates.map((date) {
            final isToday = DateTime(date.year, date.month, date.day)
                .isAtSameMomentAs(today);

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDateTap?.call(date),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? const Color(0xFF6366F1) : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF6366F1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              color: isToday ? Colors.white : const Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> weekDates, DateTime today) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          _buildTimeColumn(),

          // Day columns
          ...weekDates.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            final isToday = DateTime(date.year, date.month, date.day)
                .isAtSameMomentAs(today);

            return Expanded(
              child: _buildDayColumn(date, isToday, index == 0),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      child: Column(
        children: List.generate(widget.endHour - widget.startHour, (index) {
          final hour = widget.startHour + index;
          return Container(
            height: widget.hourHeight,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('h a').format(DateTime(0, 0, 0, hour)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime date, bool isToday, bool isFirstColumn) {
    final events = _getEventsForDay(date);

    return Container(
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isFirstColumn ? Colors.grey.shade200 : Colors.grey.shade100,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Hour grid lines
          Column(
            children: List.generate(widget.endHour - widget.startHour, (index) {
              return Container(
                height: widget.hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade100,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),

          // Current time indicator (only for today)
          if (isToday) _buildCurrentTimeIndicator(),

          // Events
          ...events.map((event) => _buildEventWidget(event)),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (currentHour < widget.startHour || currentHour >= widget.endHour) {
      return const SizedBox.shrink();
    }

    final topOffset = (currentHour - widget.startHour) * widget.hourHeight +
        (currentMinute / 60) * widget.hourHeight;

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: const Color(0xFFEF4444),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventWidget(CalendarEvent event) {
    final startHour = event.start.hour;
    final startMinute = event.start.minute;
    final endHour = event.end.hour;
    final endMinute = event.end.minute;

    final topOffset = (startHour - widget.startHour) * widget.hourHeight +
        (startMinute / 60) * widget.hourHeight;

    final duration = event.end.difference(event.start);
    final height = (duration.inMinutes / 60) * widget.hourHeight;

    return Positioned(
      top: topOffset,
      left: 2,
      right: 2,
      child: GestureDetector(
        onTap: () => widget.onEventTap?.call(event),
        child: Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: event.color,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.description != null && height > 30)
                  Text(
                    event.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}