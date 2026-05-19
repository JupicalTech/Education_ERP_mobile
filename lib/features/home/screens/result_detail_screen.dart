import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_attendance/features/auth/screens/auth_provider.dart';
import '../../../core/models/result_model.dart';
import '../../../core/api/parent_service.dart';
import '../../../core/api/odoo_client.dart';

final resultDetailProvider = FutureProvider.family<ResultModel, int>((ref, resultId) {
  final service = ParentService(ref.read(odooClientProvider));
  return service.fetchResultDetail(resultId);
});

class ResultDetailScreen extends ConsumerWidget {
  final int resultId;
  final String title;

  const ResultDetailScreen({
    super.key,
    required this.resultId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(resultDetailProvider(resultId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF25A667),
      ),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF25A667)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (result) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 238, 232, 153).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF6BB18).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Student', result.studentName),
                    _SummaryRow('Exam', result.examName ?? '—'),
                    _SummaryRow('Standard', result.standardName ?? '—'),
                    _SummaryRow('Division', result.divisionName ?? '—'),
                    _SummaryRow('Academic Year', result.academicYear ?? '—'),
                    const Divider(height: 20),
                    _SummaryRow('Total Marks', result.totalMark.toStringAsFixed(1)),
                    _SummaryRow('Marks Scored', result.totalMarkScored.toStringAsFixed(1)),
                    _SummaryRow('Percentage',
                        '${result.percentage.toStringAsFixed(2)}%'),
                    _SummaryRow(
                      'Result',
                      result.passFailFull ? 'Pass' : 'Fail',
                      valueColor: result.passFailFull
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Subject lines ─────────────────────────
              const Text(
                'Subject Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
              const SizedBox(height: 12),

              if (result.subjectLines.isEmpty)
                const Center(
                  child: Text('No subject details found',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF25A667),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(11)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 4, child: _TH('Subject')),
                            Expanded(flex: 2, child: _TH('Min')),
                            Expanded(flex: 2, child: _TH('Scored')),
                            Expanded(flex: 2, child: _TH('Total')),
                            Expanded(flex: 2, child: _TH('Grade')),
                            Expanded(flex: 2, child: _TH('P/F')),
                          ],
                        ),
                      ),
                      // Rows
                      ...result.subjectLines.asMap().entries.map((e) {
                        final idx = e.key;
                        final line = e.value;
                        final isLast =
                            idx == result.subjectLines.length - 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: idx.isEven
                                ? Colors.white
                                : const Color.fromARGB(255, 248, 246, 218),
                            borderRadius: isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(11))
                                : null,
                            border: !isLast
                                ? const Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFE8ECF0)))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  line.subjectName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: _TD(line.passMark
                                      .toStringAsFixed(1))),
                              Expanded(
                                  flex: 2,
                                  child: _TD(line.markScored
                                      .toStringAsFixed(1))),
                              Expanded(
                                  flex: 2,
                                  child:
                                      _TD(line.mark.toStringAsFixed(1))),
                              Expanded(
                                  flex: 2,
                                  child: _TD(line.grade ?? '—')),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  line.passOrFail ? 'Pass' : 'Fail',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: line.passOrFail
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1D23),
              )),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700));
}

class _TD extends StatelessWidget {
  final String text;
  const _TD(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600));
}