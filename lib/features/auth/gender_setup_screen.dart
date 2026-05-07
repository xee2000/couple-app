import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';

class GenderSetupScreen extends StatefulWidget {
  const GenderSetupScreen({super.key});

  @override
  State<GenderSetupScreen> createState() => _GenderSetupScreenState();
}

class _GenderSetupScreenState extends State<GenderSetupScreen> {
  String? _selected; // 'male' | 'female'
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);

    try {
      // 서버에 성별 저장
      await ApiService().put('/users/gender', {'gender': _selected});

      // 로컬에도 저장 (설정 화면 조건부 표시에 사용)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gender', _selected!);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),

              // 타이틀
              const Text(
                '성별을 알려주세요',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '맞춤형 기능 제공을 위해 사용됩니다.\n이후 설정에서 변경할 수 없어요.',
                style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // 성별 카드
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      emoji: '👨',
                      label: '남성',
                      selected: _selected == 'male',
                      onTap: () => setState(() => _selected = 'male'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GenderCard(
                      emoji: '👩',
                      label: '여성',
                      selected: _selected == 'female',
                      onTap: () => setState(() => _selected = 'female'),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedOpacity(
                  opacity: _selected != null ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 200),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _selected != null
                          ? AppColors.gradient
                          : const LinearGradient(colors: [Colors.grey, Colors.grey]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _selected != null ? AppColors.pinkShadow : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _selected != null ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '확인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 160,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? AppColors.pinkShadow : AppColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
