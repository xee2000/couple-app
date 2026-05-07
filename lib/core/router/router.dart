import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/gender_setup_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/couple/couple_setup_screen.dart';
import '../../features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final loc = state.matchedLocation;
    final isLogin = loc == '/login';
    final isGenderSetup = loc == '/gender-setup';

    if (token == null && !isLogin) return '/login';
    if (token != null && isLogin) return '/home';
    if (token != null && isGenderSetup) return null;
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/gender-setup', builder: (_, __) => const GenderSetupScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainScreen()),
    GoRoute(path: '/calendar', redirect: (_, __) async => '/home'),
    GoRoute(path: '/couple-setup', builder: (_, __) => const CoupleSetupScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
