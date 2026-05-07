import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';

/// 이벤트에 붙일 수 있는 태그 목록
const _kAllTags = [
  '기념일', '데이트', '놀이동산', '영화', '피시방', '노래방',
  '카페', '여행', '맛집', '드라이브', '쇼핑', '운동', '기타',
];

class EventFormSheet extends StatefulWidget {
  final DateTime date;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const EventFormSheet({
    super.key,
    required this.date,
    this.existing,
    required this.onSaved,
  });

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!['title'] ?? '';
      _descCtrl.text = widget.existing!['description'] ?? '';

      // 기존 태그 복원
      final tags = widget.existing!['tags'];
      if (tags is List) {
        _selectedTags.addAll(tags.cast<String>());
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(widget.date),
        'tags': _selectedTags.toList(),
      };
      if (widget.existing != null) {
        await ApiService().put('/events/${widget.existing!['id']}', body);
      } else {
        await ApiService().post('/events', body);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 날짜 + 닫기
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('M월 d일 (E)', 'ko').format(widget.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 태그 선택
          const Text(
            '태그',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kAllTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 제목
          const Text(
            '제목',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            autofocus: widget.existing == null,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '어떤 날이었나요?',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 메모
          const Text(
            '메모',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '간단한 메모를 남겨보세요 (선택)',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.pinkShadow,
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.existing != null ? '수정하기' : '저장하기',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
