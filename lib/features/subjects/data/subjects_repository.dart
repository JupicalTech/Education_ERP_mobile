import 'package:supabase_flutter/supabase_flutter.dart';

import 'subject_model.dart';

abstract interface class SubjectsRepository {
  Future<List<Subject>> fetchSubjects();
  Future<Subject> createSubject({required String name, String? code});
  Future<Subject> updateSubject({
    required String id,
    required String name,
    String? code,
  });
  Future<void> deleteSubject(String id);

  Future<List<SectionSubjectMapping>> fetchMappingsForCurrentYear();
  Future<List<TeacherOption>> fetchTeacherOptions();
  Future<void> assignMapping({
    required String sectionId,
    required String subjectId,
    required String teacherProfileId,
  });
  Future<void> deleteMapping(String mappingId);
}

class SupabaseSubjectsRepository implements SubjectsRepository {
  SupabaseSubjectsRepository(this._client);

  final SupabaseClient _client;

  static String? _cleanCode(String? code) {
    final trimmed = code?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<List<Subject>> fetchSubjects() async {
    final rows = await _client
        .from('subjects')
        .select('id, name, code')
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => Subject.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Subject> createSubject({required String name, String? code}) async {
    final row = await _client
        .from('subjects')
        .insert({'name': name.trim(), 'code': _cleanCode(code)})
        .select('id, name, code')
        .single();
    return Subject.fromJson(row);
  }

  @override
  Future<Subject> updateSubject({
    required String id,
    required String name,
    String? code,
  }) async {
    final row = await _client
        .from('subjects')
        .update({'name': name.trim(), 'code': _cleanCode(code)})
        .eq('id', id)
        .select('id, name, code')
        .single();
    return Subject.fromJson(row);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _client.from('subjects').delete().eq('id', id);
  }

  @override
  Future<List<SectionSubjectMapping>> fetchMappingsForCurrentYear() async {
    final rows = await _client
        .from('class_subject_teachers')
        .select(
          'id, academic_year_id, section_id, subject_id, teacher_id, '
          'academic_years!inner(is_current), '
          'sections(name, classes(name)), '
          'subjects(name, code), '
          'profiles(first_name, last_name)',
        )
        .eq('academic_years.is_current', true);

    return (rows as List<dynamic>)
        .map((r) => SectionSubjectMapping.fromJson(r as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        final cmp = a.classSection.compareTo(b.classSection);
        return cmp != 0 ? cmp : a.subjectName.compareTo(b.subjectName);
      });
  }

  @override
  Future<List<TeacherOption>> fetchTeacherOptions() async {
    final rows = await _client
        .from('teacher_directory')
        .select('profile_id, first_name, last_name, designation')
        .eq('is_active', true)
        .order('first_name', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => TeacherOption.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> assignMapping({
    required String sectionId,
    required String subjectId,
    required String teacherProfileId,
  }) async {
    await _client.rpc<String>(
      'assign_section_subject_teacher',
      params: {
        'p_section_id': sectionId,
        'p_subject_id': subjectId,
        'p_teacher_profile_id': teacherProfileId,
      },
    );
  }

  @override
  Future<void> deleteMapping(String mappingId) async {
    await _client.from('class_subject_teachers').delete().eq('id', mappingId);
  }
}
