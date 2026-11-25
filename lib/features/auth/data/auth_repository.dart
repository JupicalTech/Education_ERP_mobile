import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';
import 'user_role.dart';

abstract interface class AuthRepository {
  String? get currentUserId;
  Stream<String?> get authStateChanges;

  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<Profile> fetchProfile(String userId);
}

/// Stub implementation used before the V1 SQL migration is run.
/// Allows testing login, role routing, and logout with any [UserRole].
class StubAuthRepository implements AuthRepository {
  StubAuthRepository({this.stubRole = UserRole.principal});

  final UserRole stubRole;
  final _controller = StreamController<String?>.broadcast();
  String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _currentUserId = 'stub-user-${stubRole.dbValue}';
    _controller.add(_currentUserId);
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _controller.add(null);
  }

  @override
  Future<Profile> fetchProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return Profile(
      id: userId,
      instituteId: 'stub-institute-1',
      role: stubRole,
      firstName: 'Demo',
      lastName: stubRole.label,
      phone: '+91 98765 43210',
      isActive: true,
    );
  }

  void dispose() {
    _controller.close();
  }
}

/// Production implementation backed by Supabase Auth and the `profiles` table.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<Profile> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }
}
