import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_dummy_data.dart';

final principalDashboardProvider = Provider<PrincipalDashboardData>(
  (ref) => HomeDummyData.principal,
);

final teacherClassesProvider = Provider<List<TeacherClassItem>>(
  (ref) => HomeDummyData.teacherClasses,
);

final parentChildrenProvider = Provider<List<ParentChildSummary>>(
  (ref) => HomeDummyData.parentChildren,
);

class SelectedChildIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedChildIndexProvider =
    NotifierProvider<SelectedChildIndexNotifier, int>(
  SelectedChildIndexNotifier.new,
);

final feeClerkDashboardProvider = Provider<FeeClerkDashboardData>(
  (ref) => HomeDummyData.feeClerk,
);
