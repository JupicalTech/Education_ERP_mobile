import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/screens/auth_provider.dart';
import 'features/home/screens/faculty_home_screen.dart';
import 'features/home/screens/student_home_screen.dart';
import 'features/home/screens/parent_home_screen.dart';
import 'features/auth/screens/server_screen.dart';  



//flutter does not talk direct to postgresql it connects with Odoo Backend via HTTP (JSON-RPC API) ✅
void main() {
  runApp(const ProviderScope(child: SchoolAttendanceApp()));
}

class SchoolAttendanceApp extends StatelessWidget {
  const SchoolAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppRouter(),
      routes: {
        '/login': (_) => const ServerScreen(),
        '/home': (_) => const _AppRouter(),
      },
    );
  }
}

/// Decides which screen to show based on auth state
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Show loading spinner while restoring session
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not logged in → Login screen
    if (!auth.isLoggedIn) {
      return const ServerScreen();
    }

    // Logged in → route by role
    switch (auth.role) {
      case 'faculty':
        return const FacultyHomeScreen();
      case 'student':
        return const StudentHomeScreen();
      case 'parent':
        return const ParentHomeScreen();
      default:
        // Logged in but unknown role — show info + logout
        return _UnknownRoleScreen(role: auth.role ?? 'unknown');
    }
  }
}

/// Shown when role is not faculty/student/parent
class _UnknownRoleScreen extends ConsumerWidget {
  final String role;
  const _UnknownRoleScreen({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.manage_accounts_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Role "$role" not supported',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure is_student, is_parent, or is_faculty\nis set on this user\'s partner record in Odoo.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}