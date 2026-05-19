import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/screens/auth_provider.dart';
import '../../../shared/widgets/home_widgets.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeCard(
              name: auth.userName ?? 'Student',
              role: 'Student',
              icon: Icons.school_outlined,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 28),
            Text(
              'Modules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1D23),
                  ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                ModuleCard(
                  title: 'Attendance',
                  icon: Icons.how_to_reg_outlined,
                  color: Color(0xFF1565C0),
                  isReady: true,
                ),
                ModuleCard(
                  title: 'Results',
                  icon: Icons.bar_chart_rounded,
                  color: Color(0xFFF57C00),
                  isReady: false,
                ),
                ModuleCard(
                  title: 'Timetable',
                  icon: Icons.calendar_today_outlined,
                  color: Color(0xFF2E7D32),
                  isReady: false,
                ),
                ModuleCard(
                  title: 'Fees',
                  icon: Icons.payment_outlined,
                  color: Color(0xFF6A1B9A),
                  isReady: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}