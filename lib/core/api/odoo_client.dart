import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import 'dart:io';
/*
app starts
    ↓
_instance = OdooClient._internal()  ← runs ONCE, object created
    ↓
user logs in
    ↓
_sessionId = "abc123"  ← saved in that one object
    ↓
callKw res.partner    ← uses same object
callKw fees.fees      ← uses same object
callKw student.exam   ← uses same object
    ↓
app closes
    ↓
object destroyed from RAM

*/

/// Odoo 19 JSON-RPC Client — optimized for speed
///
/// Login flow: 2 API calls total (was 5)
///   1. /web/session/authenticate  → uid + session
///   2. res.users.read             → role + partner info (single call)
///
/// Session restore: 0 API calls if session is fresh
///   Uses stored role/partnerId — no verify call on every app open
class OdooClient {
  // static means = only one copy of this variable shared across all instances of OdooClient
  // const means = this variable cannot be reassigned after it's initialized
  static const _storage = FlutterSecureStorage();


  // late means = this variable will be initialized later, not in the constructor, but before it's used
  // const means = this variable is a compile-time constant, and must be assigned at the time of declaration
  // final means  = this variable can only be assigned once, but can be assigned at runtime (not necessarily at declaration)
  late final Dio _dio;
  String? _sessionId;
  int? _uid;
  String? _userRole;
  String? _savedLogin;
  String? _savedPassword;

  
  //odooclient._internal() is a named private constructor, used for singleton pattern
  // _instance is a static final variable that holds the single instance of OdooClient
  static final OdooClient _instance = OdooClient._internal();
  factory OdooClient() => _instance;


  OdooClient._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15), // reduced from 30
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
      extra: {'withCredentials': true},
    ));

    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['withCredentials'] = true;
          if (!kIsWeb && _sessionId != null) {
            final isReal = !_sessionId!.startsWith('mobile-uid-')
                        && !_sessionId!.startsWith('web-session-');
            if (isReal) {
              options.headers['Cookie'] = 'session_id=$_sessionId';
              options.headers['X-Openerp-Session-Id'] = _sessionId!;
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  String _baseUrl = '';
  String _database = '';

  void configure({required String baseUrl, required String database}) {
    _baseUrl = baseUrl.trimRight().replaceAll(RegExp(r'/$'), '');
    _database = database;
    _dio.options.baseUrl = _baseUrl;
  }

  // ── LOGIN ──────────────────────────────────────────────────
  // Only 2 API calls:
  //   1. authenticate
  //   2. read user fields (role + partner — combined)
  // what is authresult
  Future<AuthResult> login(String login, String password) async {
    _savedLogin = login;
    _savedPassword = password;

    try {
      // ── Call 1: authenticate ───────────────────────────────
      final response = await _dio.post(
        '/web/session/authenticate',
        data: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'id': 1,
          'params': {
            'db': _database,
            'login': login,
            'password': password,
          },
        }),
      );

      final body = response.data as Map<String, dynamic>;

      if (body['error'] != null) {
        final errData = body['error']['data'] as Map<String, dynamic>?;
        final msg = errData?['message']
            ?? body['error']['message']
            ?? 'Login failed';
        throw OdooException(msg.toString());
      }

      final result = body['result'] as Map<String, dynamic>?;
      if (result == null || result['uid'] == null || result['uid'] == false) {
        throw OdooException('Invalid username or password');
      }

      _uid = result['uid'] as int;

      // Extract partner_id — Odoo 19 returns it as plain int in authenticate
      // but as [id, name] in other calls. Handle both formats.
      final partnerRaw = result['partner_id'];
      int? partnerId;
      String? partnerName;

      AppLogger.i('partner_id raw value: $partnerRaw (type: ${partnerRaw.runtimeType})');

      if (partnerRaw is int) {
        partnerId = partnerRaw;
      } else if (partnerRaw is List && partnerRaw.isNotEmpty) {
        partnerId = partnerRaw[0] as int?;
        partnerName = partnerRaw.length > 1 ? partnerRaw[1] as String? : null;
      }

      // Fallback: if still null, read from res.users directly
      if (partnerId == null) {
        AppLogger.i('partner_id null from login response — reading from res.users');
        try {
          final userRead = await callKw(
            model: 'res.users',
            method: 'read',
            args: [[_uid!], ['partner_id', 'name']],
          );
          AppLogger.i('res.users read: $userRead');
          if (userRead is List && userRead.isNotEmpty) {
            final u = userRead[0] as Map<String, dynamic>;
            final pid = u['partner_id'];
            if (pid is int) partnerId = pid;
            if (pid is List && pid.isNotEmpty) partnerId = pid[0] as int?;
            partnerName ??= u['name'] as String?;
          }
        } catch (e) {
          AppLogger.e('partner_id fallback read failed', e);
        }
      }

      partnerName ??= result['name'] as String?;
      AppLogger.i('partnerId resolved: $partnerId  partnerName: $partnerName');

      // Extract session
      if (kIsWeb) {
        _sessionId = result['session_id'] as String? ?? 'web-session-$_uid';
      } else {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (final c in cookies) {
            final m = RegExp(r'session_id=([^;]+)').firstMatch(c);
            if (m != null) {
              _sessionId = m.group(1);
              break;
            }
          }
        }
        _sessionId ??= 'mobile-uid-$_uid';
      }

      AppLogger.i('Login OK uid=$_uid partner=$partnerId session=${_sessionId?.substring(0, 8)}...');

      // ── Call 2: read role + is_faculty in ONE call ─────────
      final String role;
      if (partnerId != null) {
        role = await _detectRoleSingleCall(_uid!, partnerId);
      } else {
        role = 'other';
      }

      _userRole = role;

      // ── Persist everything ─────────────────────────────────
      await Future.wait([
        _storage.write(key: 'session_id', value: _sessionId),
        _storage.write(key: 'uid', value: _uid.toString()),
        _storage.write(key: 'partner_id', value: partnerId?.toString()),
        _storage.write(key: 'partner_name', value: partnerName),
        _storage.write(key: 'user_role', value: role),
        _storage.write(key: 'base_url', value: _baseUrl),
        _storage.write(key: 'database', value: _database),
        _storage.write(key: 'odoo_login', value: login),
        _storage.write(key: 'odoo_password', value: password),
      ]);

      return AuthResult(
        uid: _uid!,
        role: role,
        partnerId: partnerId,
        partnerName: partnerName ?? '',
        sessionId: _sessionId ?? '',
      );

    } on OdooException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.e('Login error', e);
      if (e.response?.statusCode == 404) {
        throw OdooException('Server not found. Check your URL:\n$_baseUrl');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw OdooException(
            'Connection timed out.\nMake sure your phone and Odoo server are on the same WiFi.');
      }
      throw OdooException('Network error: ${e.message}');
    } catch (e) {
      if (e is OdooException) rethrow;
      throw OdooException('Unexpected error: $e');
    }
  }

  // Single call: read all role flags from res.partner (one call only)
  // All flags (is_student, is_parent, is_faculty) live on res.partner
  Future<String> _detectRoleSingleCall(int uid, int partnerId) async {
    try {
      AppLogger.i('Detecting role — uid=$uid partnerId=$partnerId');

      // Read all role flags from res.partner in ONE call
      final partnerResult = await callKw(
        model: 'res.partner',
        method: 'read',
        args: [
          [partnerId],
          ['is_student', 'is_parent', 'is_faculty'],
        ],
      );

      AppLogger.i('partner flags result: $partnerResult');

      if (partnerResult is List && partnerResult.isNotEmpty) {
        final p = partnerResult[0] as Map<String, dynamic>;
        AppLogger.i('is_student=${p['is_student']} is_parent=${p['is_parent']} is_faculty=${p['is_faculty']}');

        if (p['is_faculty'] == true) return 'faculty';
        if (p['is_parent'] == true) return 'parent';
        if (p['is_student'] == true) return 'student';
      }
    } catch (e) {
      AppLogger.e('_detectRole error', e);
    }
    return 'other';
  }

  // ── SESSION RESTORE ────────────────────────────────────────
  // Zero API calls — uses stored data directly.
  // Only re-logins if stored credentials exist but session is clearly invalid.
  Future<bool> restoreSession() async {
    try {
      final results = await Future.wait([
        _storage.read(key: 'base_url'),
        _storage.read(key: 'database'),
        _storage.read(key: 'odoo_login'),
        _storage.read(key: 'odoo_password'),
        _storage.read(key: 'user_role'),
        _storage.read(key: 'session_id'),
        _storage.read(key: 'uid'),
        _storage.read(key: 'partner_id'),
        _storage.read(key: 'partner_name'),
      ]);

      final baseUrl    = results[0];
      final database   = results[1];
      _savedLogin      = results[2];
      _savedPassword   = results[3];
      _userRole        = results[4];
      _sessionId       = results[5];
      final uidStr     = results[6];
      final partnerStr = results[7];

      // Nothing stored → fresh install
      if (baseUrl == null || _savedLogin == null || uidStr == null) {
        return false;
      }

      configure(baseUrl: baseUrl, database: database ?? '');
      _uid = int.tryParse(uidStr);

      // Session looks valid → use it immediately, no API call
      if (_sessionId != null && _uid != null && _userRole != null) {
        AppLogger.i('Session restored from storage — no API call needed');
        return true;
      }

      // Missing something → silent re-login (only done once)
      if (_savedLogin != null && _savedPassword != null) {
        AppLogger.i('Incomplete session — silent re-login');
        await login(_savedLogin!, _savedPassword!);
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.e('restoreSession error', e);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        '/web/session/destroy',
        data: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'id': 1,
          'params': {},
        }),
      );
    } catch (_) {}
    _sessionId = null;
    _uid = null;
    _userRole = null;
    _savedLogin = null;
    _savedPassword = null;
    await _storage.deleteAll();
  }

  // ── CORE RPC ───────────────────────────────────────────────
  Future<dynamic> callKw({
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic>? kwargs,
    List<String>? fields,
    List<dynamic>? domain,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final kw = <String, dynamic>{
      ...?kwargs,
      if (fields != null) 'fields': fields,
      if (domain != null) 'domain': domain,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (orderBy != null) 'order': orderBy,
    };
    return _callOnce(model: model, method: method, args: args, kw: kw);
  }

  // No retry loop — just one attempt. If session expired, show error.
  Future<dynamic> _callOnce({
    required String model,
    required String method,
    required List<dynamic> args,
    required Map<String, dynamic> kw,
  }) async {
    try {
      final response = await _dio.post(
        '/web/dataset/call_kw',
        data: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'id': DateTime.now().millisecondsSinceEpoch,
          'params': {
            'model': model,
            'method': method,
            'args': args,
            'kwargs': kw,
          },
        }),
      );

      final body = response.data as Map<String, dynamic>;

      if (body['error'] != null) {
        final error = body['error'] as Map<String, dynamic>;
        final errData = error['data'] as Map<String, dynamic>?;
        final msg = errData?['message']?.toString()
            ?? error['message']?.toString()
            ?? 'Odoo error';
        throw OdooException(msg);
      }

      return body['result'];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw OdooException('Request timed out. Check your network connection.');
      }
      throw OdooException('Network error: ${e.message ?? e.type.name}');
    }
  }

  // ── GETTERS ────────────────────────────────────────────────
  int? get uid => _uid;
  String? get sessionId => _sessionId;
  String? get userRole => _userRole;
  bool get isLoggedIn => _uid != null;
  String get baseUrl => _baseUrl;
  String get database => _database;

  // Read stored partner info without an API call
  Future<Map<String, String?>> getStoredUserInfo() async {
    final results = await Future.wait([
      _storage.read(key: 'partner_id'),
      _storage.read(key: 'partner_name'),
    ]);
    return {
      'partner_id': results[0],
      'partner_name': results[1],
    };
  }

  Future<String> downloadFile({
    required String route,
    required String fileName,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      // Save to public Downloads folder — accessible by all apps
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir!.path}/$fileName';
      AppLogger.i('Downloading to: $savePath');
      AppLogger.i('Session ID: $_sessionId');

      await _dio.download(
        route,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            if (!kIsWeb && _sessionId != null) ...{
              'Cookie': 'session_id=$_sessionId',
              'X-Openerp-Session-Id': _sessionId!,
            },
          },
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      AppLogger.i('File saved to: $savePath');
      return savePath;
    } on DioException catch (e) {
      throw OdooException('Download failed: ${e.message ?? e.type.name}');
    }
  }
}

// ── Result / Exception ────────────────────────────────────────

class AuthResult {
  final int uid;
  final String role;
  final int? partnerId;
  final String partnerName;
  final String sessionId;

  const AuthResult({
    required this.uid,
    required this.role,
    this.partnerId,
    required this.partnerName,
    required this.sessionId,
  });
}

class OdooException implements Exception {
  final String message;
  const OdooException(this.message);
  @override
  String toString() => 'OdooException: $message';
}