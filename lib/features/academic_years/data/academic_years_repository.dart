import 'package:supabase_flutter/supabase_flutter.dart';

import 'academic_year_model.dart';

abstract interface class AcademicYearsRepository {
  Future<List<AcademicYear>> fetchAcademicYears();
  Future<void> saveAcademicYear({
    String? id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isCurrent,
  });
  Future<void> setCurrentAcademicYear(String id);
}

class SupabaseAcademicYearsRepository implements AcademicYearsRepository {
  SupabaseAcademicYearsRepository(this._client);

  final SupabaseClient _client;

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async {
    final rows = await _client
        .from('academic_years')
        .select('id, name, start_date, end_date, is_current')
        .order('is_current', ascending: false)
        .order('start_date', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => AcademicYear.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAcademicYear({
    String? id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isCurrent,
  }) async {
    await _client.rpc<String>(
      'save_academic_year',
      params: {
        'p_id': id,
        'p_name': name.trim(),
        'p_start_date': _fmtDate(startDate),
        'p_end_date': _fmtDate(endDate),
        'p_is_current': isCurrent,
      },
    );
  }

  @override
  Future<void> setCurrentAcademicYear(String id) async {
    await _client.rpc<void>(
      'set_current_academic_year',
      params: {'p_academic_year_id': id},
    );
  }
}
