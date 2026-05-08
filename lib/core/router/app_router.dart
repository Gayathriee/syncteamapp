import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_ai_config_screen.dart';
import '../../features/admin/presentation/admin_export_screen.dart';
import '../../features/admin/presentation/admin_session_monitor_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../../features/auth/presentation/admin_signup_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/participant_login_screen.dart';
import '../../features/auth/presentation/participant_signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/participant_shell.dart';
import '../../features/session/presentation/session_break_screen.dart';
import '../../features/session/presentation/session_results_screen.dart';
import '../../features/session/presentation/session_room_screen.dart';
import '../../features/session/presentation/session_survey_screen.dart';
import '../../shared/providers/auth_state_provider.dart';

// Wires GoRouter's refreshListenable to the Riverpod auth stream so route
// guards re-evaluate whenever auth state changes (login, logout, role load).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<dynamic>>(currentUserModelProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      final authAsync = ref.read(firebaseAuthStateProvider);

      if (authAsync.isLoading) {
        return state.matchedLocation == '/' ? null : '/';
      }

      final isLoggedIn = authAsync.valueOrNull != null;
      final loc = state.matchedLocation;

      const publicRoutes = {
        '/',
        '/onboarding',
        '/login',
        '/signup',
        '/admin/login',
        '/admin/signup',
      };
      final isPublic = publicRoutes.contains(loc);

      if (!isLoggedIn) return isPublic ? null : '/login';
      if (loc == '/' || loc == '/onboarding') return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Participant auth ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const ParticipantLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const ParticipantSignupScreen(),
      ),

      // ── Admin auth ────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/signup',
        builder: (_, __) => const AdminSignupScreen(),
      ),

      // ── Participant shell (4-tab bottom nav) ──────────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const ParticipantShell(),
      ),

      // ── Session routes (full-screen, outside the shell) ───────────────────
      GoRoute(
        path: '/session/:sessionId',
        builder: (_, state) =>
            SessionRoomScreen(sessionId: state.pathParameters['sessionId']!),
        routes: [
          GoRoute(
            path: 'survey',
            builder: (_, state) => SessionSurveyScreen(
                sessionId: state.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: 'break',
            builder: (_, state) => SessionBreakScreen(
                sessionId: state.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: 'results',
            builder: (_, state) => SessionResultsScreen(
                sessionId: state.pathParameters['sessionId']!),
          ),
        ],
      ),

      // ── Admin shell (4-tab bottom nav) ────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(),
      ),

      // ── Admin full-screen routes (push over the shell) ───────────────────
      GoRoute(
        path: '/admin/session/:sessionId',
        builder: (_, state) => AdminSessionMonitorScreen(
            sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/admin/ai-config',
        builder: (_, __) => const AdminAiConfigScreen(),
      ),
      GoRoute(
        path: '/admin/export',
        builder: (_, __) => const AdminExportScreen(),
      ),
    ],
  );
});
