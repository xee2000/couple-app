import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';
import 'event_form_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _anniversaries = [];
  List<Map<String, dynamic>> _cycles = [];
  bool _loading = false;
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadNickname();
    _loadData();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nickname = prefs.getString('nickname') ?? '');
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadEvents(), _loadAnniversaries(), _loadCycles()]);
    setState(() => _loading = false);
  }

  Future<void> _loadEvents() async {
    try {
      final res = await ApiService().get(
        '/events?year=${_focusedDay.year}&month=${_focusedDay.month}',
      );
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final map = <String, List<Map<String, dynamic>>>{};
      for (final e in list) {
        final key = e['date'] as String;
        map.putIfAbsent(key, () => []).add(e);
      }
      setState(() => _events = map);
    } catch (_) {}
  }

  Future<void> _loadAnniversaries() async {
    try {
      final res = await ApiService().get('/anniversaries');
      setState(() => _anniversaries =
          (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {}
  }

  Future<void> _loadCycles() async {
    try {
      final res = await ApiService().get('/cycles');
      setState(() => _cycles =
          (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _events[key] ?? [];
  }

  bool _isInPeriod(DateTime day) {
    for (final cycle in _cycles) {
      final start = DateTime.tryParse(cycle['start_date'] ?? '');
      final end = DateTime.tryParse(cycle['end_date'] ?? '');
      if (start == null) continue;
      final periodEnd =
          end ?? start.add(Duration(days: (cycle['period_length'] ?? 5) - 1));
      if (!day.isBefore(start) && !day.isAfter(periodEnd)) return true;
    }
    return false;
  }

  String? _getAnniversaryForDay(DateTime day) {
    for (final a in _anniversaries) {
      final aDate = DateTime.tryParse(a['date'] ?? '');
      if (aDate == null) continue;
      final check = (a['repeat_yearly'] == true)
          ? (aDate.month == day.month && aDate.day == day.day)
          : (aDate.year == day.year &&
              aDate.month == day.month &&
              aDate.day == day.day);
      if (check) return a['title'];
    }
    return null;
  }

  void _showAddEvent() {
    if (_selectedDay == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(date: _selectedDay!, onSaved: _loadData),
    );
  }

  String get _headerTitle {
    return DateFormat('yyyy년 M월', 'ko').format(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Map<String, dynamic>>[];
    final anniversary =
        _selectedDay != null ? _getAnniversaryForDay(_selectedDay!) : null;
    final inPeriod = _selectedDay != null && _isInPeriod(_selectedDay!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 헤더 ──
          _CalendarHeader(
            title: _headerTitle,
            nickname: _nickname,
            onSettingsTap: () => context.push('/settings'),
          ),

          // ── 캘린더 ──
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
                _loadEvents();
              },
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, _) => _DayCell(
                  day: day, selected: false,
                  inPeriod: _isInPeriod(day),
                  hasAnniversary: _getAnniversaryForDay(day) != null,
                  events: _getEventsForDay(day),
                ),
                selectedBuilder: (ctx, day, _) => _DayCell(
                  day: day, selected: true,
                  inPeriod: _isInPeriod(day),
                  hasAnniversary: _getAnniversaryForDay(day) != null,
                  events: _getEventsForDay(day),
                ),
                todayBuilder: (ctx, day, _) => _DayCell(
                  day: day, selected: false, isToday: true,
                  inPeriod: _isInPeriod(day),
                  hasAnniversary: _getAnniversaryForDay(day) != null,
                  events: _getEventsForDay(day),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: EdgeInsets.zero,
                titleTextFormatter: (date, locale) => '',
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
                leftChevronPadding: const EdgeInsets.only(left: 16),
                rightChevronPadding: const EdgeInsets.only(right: 16),
                headerMargin: EdgeInsets.zero,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.all(2),
              ),
              rowHeight: 52,
            ),
          ),

          // ── 날짜별 내용 ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : _DayDetailPanel(
                    selectedDay: _selectedDay,
                    events: selectedEvents,
                    anniversary: anniversary,
                    inPeriod: inPeriod,
                    onDeleteEvent: (id) async {
                      await ApiService().delete('/events/$id');
                      _loadData();
                    },
                    onEditEvent: (e) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EventFormSheet(
                          date: _selectedDay!,
                          existing: e,
                          onSaved: _loadData,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _AddButton(onTap: _showAddEvent),
    );
  }
}

// ── 헤더 ─────────────────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  final String title;
  final String nickname;
  final VoidCallback onSettingsTap;

  const _CalendarHeader({
    required this.title,
    required this.nickname,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.3,
                      ),
                    ),
                    if (nickname.isNotEmpty)
                      Text(
                        '안녕하세요, $nickname 님 💕',
                        style: TextStyle(
                          fontSize: 12, color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: onSettingsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 날짜 셀 ─────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool inPeriod;
  final bool hasAnniversary;
  final List events;

  const _DayCell({
    required this.day,
    required this.selected,
    this.isToday = false,
    required this.inPeriod,
    required this.hasAnniversary,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = AppColors.textPrimary;

    if (selected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppColors.primaryLight.withOpacity(0.3);
      textColor = AppColors.primary;
    } else if (inPeriod) {
      bgColor = AppColors.periodRed.withOpacity(0.12);
      textColor = AppColors.periodRed;
    }

    // 주말 색상
    if (!selected && !isToday && (day.weekday == DateTime.saturday)) {
      textColor = const Color(0xFF6B9FE8);
    } else if (!selected && !isToday && !inPeriod && day.weekday == DateTime.sunday) {
      textColor = AppColors.primary.withOpacity(0.8);
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: hasAnniversary && !selected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (events.isNotEmpty && !selected)
            Container(
              width: 4, height: 4,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 날짜 상세 패널 ────────────────────────────────────────────────────────────

class _DayDetailPanel extends StatelessWidget {
  final DateTime? selectedDay;
  final List<Map<String, dynamic>> events;
  final String? anniversary;
  final bool inPeriod;
  final Function(String id) onDeleteEvent;
  final Function(Map<String, dynamic> event) onEditEvent;

  const _DayDetailPanel({
    required this.selectedDay,
    required this.events,
    required this.anniversary,
    required this.inPeriod,
    required this.onDeleteEvent,
    required this.onEditEvent,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = events.isNotEmpty || anniversary != null || inPeriod;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // 선택 날짜 표시
          if (selectedDay != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                DateFormat('M월 d일 (E)', 'ko').format(selectedDay!),
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // 기념일 배너
          if (anniversary != null)
            _InfoBanner(
              icon: '🎉',
              label: anniversary!,
              color: AppColors.primary,
            ),

          // 생리 배너
          if (inPeriod)
            _InfoBanner(
              icon: '🌸',
              label: '생리 기간',
              color: AppColors.periodRed,
            ),

          // 이벤트 목록
          ...events.map((e) => _EventCard(
                event: e,
                onDelete: () => onDeleteEvent(e['id']),
                onEdit: () => onEditEvent(e),
              )),

          // 비어있을 때
          if (!hasContent)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Text('✨', style: TextStyle(fontSize: 40, color: Colors.grey[300])),
                  const SizedBox(height: 12),
                  Text(
                    '이 날의 기록이 없어요',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+ 버튼으로 추가해보세요',
                    style: TextStyle(color: Colors.grey[350], fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _InfoBanner({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
      ]),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EventCard({required this.event, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(event['emoji'] ?? '💑',
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      if (event['description'] != null &&
                          (event['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          event['description'],
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('수정', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); onEdit(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              onTap: () { Navigator.pop(context); onDelete(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        shape: BoxShape.circle,
        boxShadow: AppColors.pinkShadow,
      ),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
