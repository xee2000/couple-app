import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
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
      setState(() => _anniversaries = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {}
  }

  Future<void> _loadCycles() async {
    try {
      final res = await ApiService().get('/cycles');
      setState(() => _cycles = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _events[key] ?? [];
  }

  /// 해당 날짜에 생리 기간인지 확인
  bool _isInPeriod(DateTime day) {
    for (final cycle in _cycles) {
      final start = DateTime.tryParse(cycle['start_date'] ?? '');
      final end = DateTime.tryParse(cycle['end_date'] ?? '');
      if (start == null) continue;
      final periodEnd = end ?? start.add(Duration(days: (cycle['period_length'] ?? 5) - 1));
      if (!day.isBefore(start) && !day.isAfter(periodEnd)) return true;
    }
    return false;
  }

  /// 해당 날짜가 기념일인지
  String? _getAnniversaryForDay(DateTime day) {
    for (final a in _anniversaries) {
      final aDate = DateTime.tryParse(a['date'] ?? '');
      if (aDate == null) continue;
      final check = (a['repeat_yearly'] == true)
          ? (aDate.month == day.month && aDate.day == day.day)
          : (aDate.year == day.year && aDate.month == day.month && aDate.day == day.day);
      if (check) return a['title'];
    }
    return null;
  }

  void _showAddEvent() {
    if (_selectedDay == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => EventFormSheet(
        date: _selectedDay!,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    final anniversary = _selectedDay != null ? _getAnniversaryForDay(_selectedDay!) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('💑 Our Days', style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFFE91E8C)),
            onPressed: () {}, // 기념일 탭
          ),
        ],
      ),
      body: Column(
        children: [
          // 캘린더
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() { _selectedDay = selected; _focusedDay = focused; });
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
              _loadEvents();
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, focused) => _buildDay(day, false),
              selectedBuilder: (ctx, day, focused) => _buildDay(day, true),
              todayBuilder: (ctx, day, focused) => _buildDay(day, false, isToday: true),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE91E8C).withOpacity(0.3), shape: BoxShape.circle,
              ),
            ),
          ),

          const Divider(height: 1),

          // 선택한 날 정보
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 기념일 배너
                      if (anniversary != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E8C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Text('🎉', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(anniversary, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E8C))),
                          ]),
                        ),

                      // 생리 표시
                      if (_selectedDay != null && _isInPeriod(_selectedDay!))
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(children: [
                            Text('🔴', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text('생리 기간', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ]),
                        ),

                      // 이벤트 목록
                      ...selectedEvents.map((e) => _EventCard(
                        event: e,
                        onDelete: () async {
                          await ApiService().delete('/events/${e['id']}');
                          _loadData();
                        },
                      )),

                      if (selectedEvents.isEmpty && anniversary == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Text('이 날의 기록이 없어요\n+ 버튼으로 추가해보세요 💕',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, height: 1.6)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEvent,
        backgroundColor: const Color(0xFFE91E8C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDay(DateTime day, bool selected, {bool isToday = false}) {
    final inPeriod = _isInPeriod(day);
    final hasAnniversary = _getAnniversaryForDay(day) != null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFE91E8C)
            : isToday
                ? const Color(0xFFE91E8C).withOpacity(0.2)
                : inPeriod
                    ? Colors.red.withOpacity(0.15)
                    : null,
        shape: BoxShape.circle,
        border: hasAnniversary ? Border.all(color: const Color(0xFFE91E8C), width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: hasAnniversary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onDelete;
  const _EventCard({required this.event, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Text(event['emoji'] ?? '💑', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (event['description'] != null && (event['description'] as String).isNotEmpty)
                Text(event['description'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
