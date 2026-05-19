import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/odoo_client.dart';

final odooClientProvider = Provider<OdooClient>((ref) => OdooClient());

// ── Auth State ────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final int? uid;
  final String? role;
  final String? userName;
  final int? partnerId;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.uid,
    this.role,
    this.userName,
    this.partnerId,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    int? uid,
    String? role,
    String? userName,
    int? partnerId,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        uid: uid ?? this.uid,
        role: role ?? this.role,
        userName: userName ?? this.userName,
        partnerId: partnerId ?? this.partnerId,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Auth Notifier ─────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final OdooClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final restored = await _client.restoreSession();
      if (restored) {
        // Get partner info from storage — zero extra API calls
        final info = await _client.getStoredUserInfo();
        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
          uid: _client.uid,
          role: _client.userRole,
          userName: info['partner_name'],
          partnerId: int.tryParse(info['partner_id'] ?? ''),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _client.configure(baseUrl: baseUrl, database: database);
      final result = await _client.login(login, password);
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        uid: result.uid,
        role: result.role,
        userName: result.partnerName,
        partnerId: result.partnerId,
      );
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _client.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(odooClientProvider));
});