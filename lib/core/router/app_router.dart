import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_ai_config_screen.dart';
import '../../features/admin/presentation/admin_export_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_live_list_screen.dart';
import '../../features/admin/presentation/admin_participants_screen.dart';
import '../../features/admin/presentation/admin_session_monitor_screen.dart';
import '../../features/admin/presentation/admin_tasks_screen.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../../features/auth/presentation/admin_signup_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/participant_login_screen.dart';
import '../../features/auth/presentation/participant_signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/participant_dashboard_screen.dart';
import '../../features/session/presentation/session_break_screen.dart';
import '../../features/session/presentation/session_results_screen.dart';
import '../../features/session/presentation/session_room_screen.dart';
import '../../features/session/presentation/session_survey_screen.dart';
import '../../shared/providers/auth_state_provider.dart';

// Wires GoRouter's refreshListenable to the Riverpod auth stream so route
// guards re-evaluate whenever auth state changes (login, logout, role load).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // Listen to the derived user model — this fires after both the Firebase
    // auth token AND the Firestore role doc have resolved, which avoids the
    // brief flash where an admin sees the participant dashboard (§3.2).
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
      final userAsync = ref.read(currentUserModelProvider);

      // Still resolving — hold at splash while we wait
      if (authAsync.isLoading || userAsync.isLoading) {
        return state.matchedLocation == '/' ? null : '/';
      }

      final firebaseUser = authAsync.valueOrNull;
      final userModel = userAsync.valueOrNull;
      final isLoggedIn = firebaseUser != null;
      final isAdmin = userModel?.isAdmin ?? false;

      final loc = state.matchedLocation;

      // Routes that don't require authentication
      const publicRoutes = {
        '/',
        '/onboarding',
        '/login',
        '/signup',
        '/admin/login',
        '/admin/signup',
      };
      final isPublic = publicRoutes.contains(loc);

      if (!isLoggedIn) {
        // Send unauthenticated users to the login screen unless they're already
        // on a public route (onboarding, splash, admin invite signup etc.)
        return isPublic ? null : '/login';
      }

      // Authenticated users shouldn't linger on auth screens
      if (isPublic) {
        return isAdmin ? '/admin' : '/dashboard';
      }

      // Cross-role guards — gentle redirects rather than errors
      if (isAdmin) {
        if (loc.startsWith('/dashboard')) return '/admin';
        // Participant-specific session routes (not the admin monitor)
        if (loc.startsWith('/session/') && !loc.startsWith('/admin/session/')) {
          return '/admin';
        }
      } else {
        if (loc.startsWith('/admin')) return '/dashboard';
      }

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

      // ── Participant routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const ParticipantDashboardScreen(),
      ),
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

      // ── Admin routes ───────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/live',
        builder: (_, __) => const AdminLiveListScreen(),
      ),
      GoRoute(
        path: '/admin/session/:sessionId',
        builder: (_, state) => AdminSessionMonitorScreen(
            sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/admin/tasks',
        builder: (_, __) => const AdminTasksScreen(),
      ),
      GoRoute(
        path: '/admin/participants',
        builder: (_, __) => const AdminParticipantsScreen(),
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
