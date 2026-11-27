class SectionItem {
  const SectionItem({
    required this.id,
    required this.classId,
    required this.name,
    this.classTeacherId,
  });

  final String id;
  final String classId;
  final String name;
  final String? classTeacherId;

  factory SectionItem.fromJson(Map<String, dynamic> json) {
    return SectionItem(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      name: (json['name'] as String?) ?? '',
      classTeacherId: json['class_teacher_id'] as String?,
    );
  }
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.sections = const [],
  });

  final String id;
  final String name;
  final int displayOrder;
  final List<SectionItem> sections;

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List<dynamic>?) ?? const [];
    final sections = rawSections
        .map((e) => SectionItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SchoolClass(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      displayOrder: (json['display_order'] as int?) ?? 0,
      sections: sections,
    );
  }

  SchoolClass copyWith({List<SectionItem>? sections}) {
    return SchoolClass(
      id: id,
      name: name,
      displayOrder: displayOrder,
      sections: sections ?? this.sections,
    );
  }
}
