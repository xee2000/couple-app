import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class EventFormSheet extends StatefulWidget {
  final DateTime date;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const EventFormSheet({super.key, required this.date, this.existing, required this.onSaved});

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _emoji = '💑';
  String _category = 'date';
  bool _saving = false;

  final _emojis = ['💑', '🍽️', '🎬', '🏖️', '🎡', '☕', '🎂', '🎁', '💐', '✈️'];
  final _categories = ['date', 'special', 'trip'];
  final _categoryLabels = {'date': '데이트', 'special': '특별한 날', 'trip': '여행'};

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _descCtrl.text = widget.existing!['description'] ?? '';
      _emoji = widget.existing!['emoji'] ?? '💑';
      _category = widget.existing!['category'] ?? 'date';
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(widget.date),
        'emoji': _emoji,
        'category': _category,
      };

      if (widget.existing != null) {
        await ApiService().put('/events/${widget.existing!['id']}', body);
      } else {
        await ApiService().post('/events', body);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              DateFormat('M월 d일', 'ko').format(widget.date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE91E8C)),
            ),
            const SizedBox(height: 16),

            // 이모지 선택
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _emoji = _emojis[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _emoji == _emojis[i] ? const Color(0xFFE91E8C).withOpacity(0.15) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: _emoji == _emojis[i] ? Border.all(color: const Color(0xFFE91E8C)) : null,
                    ),
                    child: Text(_emojis[i], style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 제목
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '어떤 날이었나요?',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // 메모
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '메모 (선택)',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
