import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../data/auth_repository.dart';
import '../data/profile.dart';
import '../data/user_role.dart';

/// Selectable role for [StubAuthRepository] during pre-migration development.
class StubRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.principal;

  void setRole(UserRole role) => state = role;
}

final stubRoleProvider = NotifierProvider<StubRoleNotifier, UserRole>(
  StubRoleNotifier.new,
);

/// Active [AuthRepository] backed by Supabase Auth and the `profiles` table.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseProvider));
});

/// Emits the authenticated user's ID, or `null` when signed out.
final authStateProvider = StreamProvider<String?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUserId;
  yield* repo.authStateChanges;
});

/// Fetches the [Profile] for the currently authenticated user, or `null` when
/// signed out. Automatically re-runs whenever [authStateProvider] changes.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = await ref.watch(authStateProvider.future);
  if (userId == null) return null;
  return ref.watch(authRepositoryProvider).fetchProfile(userId);
});

/// Handles login form submission state (loading / error / success).
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password),
    );
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
