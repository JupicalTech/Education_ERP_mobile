import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_attendance/core/utils/logger.dart';
import '../../../core/api/odoo_client.dart';
import '../../auth/screens/auth_provider.dart';
import '../screens/result_report_screen.dart'; // ← adjust import path as needed

// Report key constants
const _kScore      = 'score';
const _kAttendance = 'attendance';
const _kEvalStudent  = 'eval_student';
const _kEvalTeacher  = 'eval_teacher';
const _kEvalParent   = 'eval_parent';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Keyed by report ID — scales to any number of reports cleanly
  final Map<String, bool>    _downloading = {};
  final Map<String, double>  _progress    = {};
  final Map<String, String?> _errors      = {};

  bool    _isDownloading(String key) => _downloading[key] ?? false;
  double  _getProgress(String key)   => _progress[key]    ?? 0;
  String? _getError(String key)      => _errors[key];

  Future<void> _download({
    required String key,
    required String route,
    required String fileName,
  }) async {
    setState(() {
      _downloading[key] = true;
      _progress[key]    = 0;
      _errors[key]      = null;
    });

    try {
      final client = ref.read(odooClientProvider);
      final path = await client.downloadFile(
        route: route,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress[key] = received / total);
          }
        },
      );

      AppLogger.i('File saved to: $path');
      final result = await OpenFilex.open(path);
      AppLogger.i('OpenFilex result: ${result.type} — ${result.message}');

      if (result.type != ResultType.done) {
        _showSnack('File saved to: $path', isError: false);
      } else {
        _showSnack('$fileName downloaded successfully');
      }
    } catch (e) {
      AppLogger.e('Download error', e);
      setState(() => _errors[key] = e.toString());
      _showSnack('Download failed: $e', isError: true);
    } finally {
      setState(() => _downloading[key] = false);
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      final result = await Permission.storage.request();
      if (result.isGranted) return true;
      final result2 = await Permission.manageExternalStorage.request();
      return result2.isGranted;
    }
    return true;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Reports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1D23),
                  ),
            ),
            const SizedBox(height: 16),

            // ── Score Summary ──────────────────────────
            _ReportCard(
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF1565C0),
              title: 'Score Summary',
              subtitle: 'Download student exam scores as Excel',
              buttonLabel: 'Download Excel',
              buttonIcon: Icons.table_chart_outlined,
              isLoading: _isDownloading(_kScore),
              progress: _getProgress(_kScore),
              error: _getError(_kScore),
              onTap: () => _download(
                key: _kScore,
                route: '/my/score-summary/download',
                fileName: 'Score_Summary.xlsx',
              ),
            ),
            const SizedBox(height: 14),

            // ── Attendance Report ──────────────────────
            _ReportCard(
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFF2E7D32),
              title: 'Attendance Report',
              subtitle: 'Download monthly attendance as PDF',
              buttonLabel: 'Download PDF',
              buttonIcon: Icons.picture_as_pdf_outlined,
              isLoading: _isDownloading(_kAttendance),
              progress: _getProgress(_kAttendance),
              error: _getError(_kAttendance),
              onTap: () => _download(
                key: _kAttendance,
                route: '/my/attendance/download/pdf',
                fileName: 'Attendance_Report.pdf',
              ),
            ),
            const SizedBox(height: 14),

            // ── Result Report (View) ───────────────────
            _ViewReportCard(
              icon: Icons.assignment_turned_in_outlined,
              color: const Color(0xFF6A1B9A),
              title: 'Result Report',
              subtitle: 'View subject-wise exam results & grades',
              buttonLabel: 'View Results',
              buttonIcon: Icons.open_in_new_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResultReportScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Evaluation Reports section header ──────
            Text(
              'Evaluation Reports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1D23),
                  ),
            ),
            const SizedBox(height: 16),

            // ── Student Evaluation Summary ─────────────
            _ReportCard(
              icon: Icons.school_outlined,
              color: const Color(0xFFE65100),
              title: 'Student Evaluation Summary',
              subtitle: 'Download student evaluation as PDF',
              buttonLabel: 'Download PDF',
              buttonIcon: Icons.picture_as_pdf_outlined,
              isLoading: _isDownloading(_kEvalStudent),
              progress: _getProgress(_kEvalStudent),
              error: _getError(_kEvalStudent),
              onTap: () => _download(
                key: _kEvalStudent,
                route: '/my/evaluation-summary/student/pdf',
                fileName: 'Student_Evaluation_Summary.pdf',
              ),
            ),
            const SizedBox(height: 14),

            // ── Teacher Evaluation Summary ─────────────
            _ReportCard(
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF00695C),
              title: 'Teacher Evaluation Summary',
              subtitle: 'Download teacher evaluation as PDF',
              buttonLabel: 'Download PDF',
              buttonIcon: Icons.picture_as_pdf_outlined,
              isLoading: _isDownloading(_kEvalTeacher),
              progress: _getProgress(_kEvalTeacher),
              error: _getError(_kEvalTeacher),
              onTap: () => _download(
                key: _kEvalTeacher,
                route: '/my/evaluation-summary/teacher/pdf',
                fileName: 'Teacher_Evaluation_Summary.pdf',
              ),
            ),
            const SizedBox(height: 14),

            // ── Parent Evaluation Summary ──────────────
            _ReportCard(
              icon: Icons.family_restroom_outlined,
              color: const Color(0xFF6A1B9A),
              title: 'Parent Evaluation Summary',
              subtitle: 'Download parent evaluation as PDF',
              buttonLabel: 'Download PDF',
              buttonIcon: Icons.picture_as_pdf_outlined,
              isLoading: _isDownloading(_kEvalParent),
              progress: _getProgress(_kEvalParent),
              error: _getError(_kEvalParent),
              onTap: () => _download(
                key: _kEvalParent,
                route: '/my/evaluation-summary/parent/pdf',
                fileName: 'Parent_Evaluation_Summary.pdf',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Download Report Card ──────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isLoading;
  final double progress;
  final String? error;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.isLoading,
    required this.progress,
    required this.onTap,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
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
        children: [
          // ── Top row ───────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Progress bar ──────────────────────────────
          if (isLoading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 5,
                backgroundColor: const Color(0xFFE8ECF0),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              progress > 0
                  ? '${(progress * 100).round()}% downloaded'
                  : 'Preparing download...',
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],

          // ── Error ─────────────────────────────────────
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],

          const SizedBox(height: 14),

          // ── Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(buttonIcon, size: 18),
              label: Text(isLoading ? 'Downloading...' : buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── View Report Card (no download state) ─────────────────────

class _ViewReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;

  const _ViewReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}