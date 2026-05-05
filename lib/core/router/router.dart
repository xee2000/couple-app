import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/login_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final isLogin = state.matchedLocation == '/login';
    if (token == null && !isLogin) return '/login';
    if (token != null && isLogin) return '/calendar';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
