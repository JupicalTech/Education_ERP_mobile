import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Welcome Card ──────────────────────────────────────────────
// Shown at top of every role's home screen

class WelcomeCard extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color color;

  const WelcomeCard({
    required this.name,
    required this.role,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Module Card ───────────────────────────────────────────────
// Grid tile for each feature module

class ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isReady; // false = coming soon

  const ModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isReady
          ? () {
              // TODO: navigate to module
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title module — tap to open'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title — coming soon'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReady
                ? color.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isReady
                        ? color.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isReady ? color : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                if (!isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isReady
                    ? const Color(0xFF1A1D23)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}