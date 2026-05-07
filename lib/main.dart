import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'services/api_service.dart';

/// 백그라운드 메시지 핸들러 — top-level 함수여야 함
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드 수신 시 Android가 자동으로 알림 표시
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: 'b1a33e107f188d1a51e5302ead784509');

  // Firebase 초기화
  await Firebase.initializeApp();

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 한국어 날짜 포맷
  await initializeDateFormatting('ko', null);

  // FCM 토큰 서버 저장 (로그인 상태일 때만)
  await _registerFcmToken();

  runApp(const CoupleApp());
}

/// FCM 토큰 획득 후 서버 저장
Future<void> _registerFcmToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return; // 미로그인 상태 — 로그인 화면에서 다시 호출

    final messaging = FirebaseMessaging.instance;

    // 알림 권한 요청 (iOS는 팝업, Android 13+도 필요)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token == null) return;

    await ApiService().post('/users/fcm-token', {'token': token});

    // 토큰이 갱신될 때마다 자동으로 서버에 업데이트
    messaging.onTokenRefresh.listen((newToken) {
      ApiService().post('/users/fcm-token', {'token': newToken});
    });
  } catch (_) {
    // 알림 등록 실패해도 앱 실행에는 영향 없음
  }
}

class CoupleApp extends StatelessWidget {
  const CoupleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Our Days',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C)),
        fontFamily: 'NotoSansKR',
        useMaterial3: true,
      ),
    );
  }
}
