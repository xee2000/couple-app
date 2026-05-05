import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _kakaoLogin() async {
    setState(() => _loading = true);
    try {
      OAuthToken token;

      // 카카오톡 설치 여부에 따라 로그인 방법 분기
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 서버에 accessToken 전달 → JWT 수신
      final res = await ApiService().post('/auth/kakao', {
        'accessToken': token.accessToken,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', res['token']);
      await prefs.setString('user_id', res['user']['id']);
      await prefs.setString('nickname', res['user']['nickname'] ?? '');

      if (mounted) context.go('/couple-setup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💑', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              const Text(
                'Our Days',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE91E8C)),
              ),
              const SizedBox(height: 8),
              const Text('우리의 소중한 날들을 기록해요', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 60),
              _loading
                  ? const CircularProgressIndicator(color: Color(0xFFE91E8C))
                  : GestureDetector(
                      onTap: _kakaoLogin,
                      child: Container(
                        width: 280,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE500),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💬', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              '카카오로 시작하기',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3C1E1E)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
