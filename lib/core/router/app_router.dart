import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/profile.dart';
import '../../features/auth/data/user_role.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/fee_clerk_home.dart';
import '../../features/home/parent_home.dart';
import '../../features/home/principal_home.dart';
import '../../features/home/student_home.dart';
import '../../features/home/super_admin_home.dart';
import '../../features/home/teacher_home.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Profile?>>(
      currentProfileProvider,
      (_, _) => notifyListeners(),
    );
  }
}

bool _isAllowedForRole(String location, String homeRoute) {
  return location == homeRoute || location.startsWith('$homeRoute/');
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final profileAsync = ref.read(currentProfileProvider);

      if (profileAsync.isLoading) return null;

      final profile = profileAsync.hasError ? null : profileAsync.value;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';

      if (profile == null) {
        return isLoggingIn ? null : '/login';
      }

      final homeRoute = profile.role.homeRoute;
      if (isLoggingIn || !_isAllowedForRole(location, homeRoute)) {
        return homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: UserRole.superAdmin.homeRoute,
        builder: (context, state) => const SuperAdminHome(),
      ),
      GoRoute(
        path: UserRole.principal.homeRoute,
        builder: (context, state) => const PrincipalHome(),
      ),
      GoRoute(
        path: UserRole.feeClerk.homeRoute,
        builder: (context, state) => const FeeClerkHome(),
      ),
      GoRoute(
        path: UserRole.teacher.homeRoute,
        builder: (context, state) => const TeacherHome(),
      ),
      GoRoute(
        path: UserRole.student.homeRoute,
        builder: (context, state) => const StudentHome(),
      ),
      GoRoute(
        path: UserRole.parent.homeRoute,
        builder: (context, state) => const ParentHome(),
      ),
    ],
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
