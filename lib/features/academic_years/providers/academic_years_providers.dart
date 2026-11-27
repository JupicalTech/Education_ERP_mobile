import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../../subjects/providers/subjects_providers.dart';
import '../data/academic_year_model.dart';
import '../data/academic_years_repository.dart';

final academicYearsRepositoryProvider = Provider<AcademicYearsRepository>(
  (ref) => SupabaseAcademicYearsRepository(ref.watch(supabaseProvider)),
);

class AcademicYearsNotifier extends AsyncNotifier<List<AcademicYear>> {
  @override
  FutureOr<List<AcademicYear>> build() {
    return ref.watch(academicYearsRepositoryProvider).fetchAcademicYears();
  }

  Future<void> saveAcademicYear({
    String? id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isCurrent,
  }) async {
    await ref
        .read(academicYearsRepositoryProvider)
        .saveAcademicYear(
          id: id,
          name: name,
          startDate: startDate,
          endDate: endDate,
          isCurrent: isCurrent,
        );
    state = AsyncData(
      await ref.read(academicYearsRepositoryProvider).fetchAcademicYears(),
    );
    ref.invalidate(subjectMappingsProvider);
  }

  Future<void> setCurrent(String id) async {
    await ref.read(academicYearsRepositoryProvider).setCurrentAcademicYear(id);
    state = AsyncData(
      await ref.read(academicYearsRepositoryProvider).fetchAcademicYears(),
    );
    ref.invalidate(subjectMappingsProvider);
  }
}

final academicYearsProvider =
    AsyncNotifierProvider<AcademicYearsNotifier, List<AcademicYear>>(
      AcademicYearsNotifier.new,
    );

final currentAcademicYearProvider = Provider<AcademicYear?>((ref) {
  final years = ref.watch(academicYearsProvider).value ?? const [];
  for (final y in years) {
    if (y.isCurrent) return y;
  }
  return null;
});
