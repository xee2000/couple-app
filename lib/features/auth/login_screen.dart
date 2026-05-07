import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // 애니메이션 완료 후 알림 권한 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNotificationDialog());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// 최초 1회만 알림 권한 안내 다이얼로그 표시
  Future<void> _maybeShowNotificationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notification_permission_asked') ?? false;
    if (asked || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationPermissionDialog(
        onConfirm: () async {
          await prefs.setBool('notification_permission_asked', true);
          if (!mounted) return;
          Navigator.pop(context);
          // 시스템 권한 다이얼로그 표시
          await FirebaseMessaging.instance.requestPermission(
            alert: true, badge: true, sound: true,
          );
        },
        onLater: () async {
          await prefs.setBool('notification_permission_asked', true);
          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _kakaoLogin() async {
    setState(() => _loading = true);
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final res = await ApiService().post('/auth/kakao', {
        'accessToken': token.accessToken,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', res['token']);
      await prefs.setString('user_id', res['user']['id']);
      await prefs.setString('nickname', res['user']['nickname'] ?? '');

      // FCM 토큰 서버 저장 (백그라운드)
      _saveFcmToken();

      if (!mounted) return;

      // 성별 미설정이면 성별 선택 화면으로, 아니면 캘린더로
      final gender = res['user']['gender'] as String?;
      if (gender == null || gender.isEmpty) {
        context.go('/gender-setup');
      } else {
        await prefs.setString('gender', gender);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await ApiService().post('/users/fcm-token', {'token': token});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 상단 그라디언트 배경
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.52,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.07),

                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('💑', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Our Days',
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '우리 둘만의 소중한 기록',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: size.height * 0.07),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '시작하기',
                              style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '카카오 계정으로 간편하게 시작하세요',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            if (_loading)
                              const SizedBox(
                                height: 54,
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              )
                            else
                              _KakaoButton(onTap: _kakaoLogin),

                            const SizedBox(height: 24),
                            Text(
                              '로그인 시 개인정보 처리방침에 동의하게 됩니다',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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

// ── 알림 권한 설명 다이얼로그 ─────────────────────────────────────────────────

class _NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onLater;

  const _NotificationPermissionDialog({
    required this.onConfirm,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.pinkShadow,
              ),
              child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '알림을 허용해주세요',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              '아래와 같은 알림을 받을 수 있어요',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // 알림 항목들
            ...[
              ('💕', '파트너와 커플 연결이 됐을 때'),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(item.$1, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 24),

            // 확인했어요 버튼
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
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '확인했어요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 나중에 버튼
            TextButton(
              onPressed: onLater,
              child: const Text(
                '나중에',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 카카오 버튼 ───────────────────────────────────────────────────────────────

class _KakaoButton extends StatefulWidget {
  final VoidCallback onTap;
  const _KakaoButton({required this.onTap});

  @override
  State<_KakaoButton> createState() => _KakaoButtonState();
}

class _KakaoButtonState extends State<_KakaoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.kakao,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.kakao.withValues(alpha: 0.4),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💬', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                '카카오로 계속하기',
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16,
                  color: Color(0xFF3C1E1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
