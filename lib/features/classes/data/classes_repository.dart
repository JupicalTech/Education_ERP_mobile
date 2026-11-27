import 'package:supabase_flutter/supabase_flutter.dart';

import 'class_model.dart';

abstract interface class ClassesRepository {
  Future<List<SchoolClass>> fetchClasses();
  Future<SchoolClass> createClass({
    required String name,
    required int displayOrder,
    List<String> initialSections,
  });
  Future<void> createClasses({
    required List<String> names,
    required int startingOrder,
    List<String> initialSections,
  });
  Future<void> deleteClass(String classId);
  Future<SectionItem> addSection({
    required String classId,
    required String name,
  });
  Future<void> deleteSection(String sectionId);
}

class SupabaseClassesRepository implements ClassesRepository {
  SupabaseClassesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SchoolClass>> fetchClasses() async {
    final rows = await _client
        .from('classes')
        .select('id, name, display_order, sections(id, class_id, name, class_teacher_id)')
        .order('display_order', ascending: true)
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => SchoolClass.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SchoolClass> createClass({
    required String name,
    required int displayOrder,
    List<String> initialSections = const [],
  }) async {
    final inserted = await _client
        .from('classes')
        .insert({'name': name.trim(), 'display_order': displayOrder})
        .select('id, name, display_order')
        .single();

    final classId = inserted['id'] as String;
    final cleanSections = initialSections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    var createdSections = <SectionItem>[];
    if (cleanSections.isNotEmpty) {
      final sectionRows = await _client
          .from('sections')
          .insert([
            for (final sec in cleanSections) {'class_id': classId, 'name': sec},
          ])
          .select('id, class_id, name, class_teacher_id');
      createdSections = (sectionRows as List<dynamic>)
          .map((e) => SectionItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }

    return SchoolClass(
      id: classId,
      name: (inserted['name'] as String?) ?? name.trim(),
      displayOrder: (inserted['display_order'] as int?) ?? displayOrder,
      sections: createdSections,
    );
  }

  @override
  Future<void> createClasses({
    required List<String> names,
    required int startingOrder,
    List<String> initialSections = const [],
  }) async {
    final cleanNames = names
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    if (cleanNames.isEmpty) return;

    final cleanSections = initialSections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final insertedRows = await _client
        .from('classes')
        .upsert(
          [
            for (var i = 0; i < cleanNames.length; i++)
              {'name': cleanNames[i], 'display_order': startingOrder + i},
          ],
          onConflict: 'name',
          ignoreDuplicates: true,
        )
        .select('id');

    if (cleanSections.isNotEmpty && (insertedRows as List<dynamic>).isNotEmpty) {
      final sectionPayload = <Map<String, dynamic>>[];
      for (final row in insertedRows) {
        final classId = (row as Map<String, dynamic>)['id'] as String;
        for (final sec in cleanSections) {
          sectionPayload.add({'class_id': classId, 'name': sec});
        }
      }
      await _client.from('sections').insert(sectionPayload);
    }
  }

  @override
  Future<void> deleteClass(String classId) async {
    await _client.from('classes').delete().eq('id', classId);
  }

  @override
  Future<SectionItem> addSection({
    required String classId,
    required String name,
  }) async {
    final row = await _client
        .from('sections')
        .insert({'class_id': classId, 'name': name.trim()})
        .select('id, class_id, name, class_teacher_id')
        .single();

    return SectionItem.fromJson(row);
  }

  @override
  Future<void> deleteSection(String sectionId) async {
    await _client.from('sections').delete().eq('id', sectionId);
  }
}
