import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/role/user_role.dart';
import '../utils/logger.dart';

/// Manages the active [UserRole] for the running app.
///
/// Design:
/// - The current role lives **only in memory**. Cold start always starts in
///   [UserRole.normal]; the role is never persisted. This is strictly safer
///   than persisting + clearing on a lifecycle hook because the hook can be
///   missed when the OS kills the process.
/// - The developer-mode password is persisted as a sha256 hash in
///   [SharedPreferences]. If no hash is stored, the hardcoded factory
///   default applies.
/// - The factory default password is `cg500dev`. Anyone who knows it can
///   enter developer mode and is encouraged to change it via
///   [changePassword]. If the custom password is forgotten,
///   [resetPasswordToDefault] removes the stored hash so the factory
///   default applies again — see [resetPasswordToDefault] for the rationale.
class RoleService {
  RoleService();

  static const String _passwordHashKey = 'role_dev_password_hash';

  /// Breadcrumb: set while developer mode is active, removed on an explicit
  /// exit. It is **not** the role — a leftover `true` never elevates anything,
  /// it only tells the next launch that the previous run ended while elevated.
  /// See [consumeInterruptedDeveloperSession].
  static const String _devSessionFlagKey = 'role_dev_session_active';

  /// sha256(`cg500dev`) — factory default password hash.
  /// Used when no custom hash is stored in [SharedPreferences].
  static const String defaultPasswordHashHex =
      '3aeecd88f6b72d40cef56cf59536aedb5689a8c8e561fcd6425af2e38974de2f';

  /// Minimum length for a custom password.
  static const int minPasswordLength = 4;

  final StreamController<UserRole> _roleController =
      StreamController<UserRole>.broadcast();

  UserRole _currentRole = UserRole.normal;

  UserRole get currentRole => _currentRole;

  Stream<UserRole> get roleStream => _roleController.stream;

  /// Attempt to enter developer mode with the given plaintext password.
  /// Returns `true` on success and emits the new role on [roleStream].
  Future<bool> tryEnableDeveloperMode(String plaintext) async {
    final inputHash = _hash(plaintext);
    final stored = await _loadStoredHashOrDefault();
    if (inputHash != stored) {
      Logger.diagnostic('[ROLE] tryEnableDeveloperMode: incorrect password');
      return false;
    }
    _currentRole = UserRole.developer;
    _roleController.add(_currentRole);
    await _setDevSessionFlag(true);
    Logger.diagnostic('[ROLE] developer mode enabled');
    return true;
  }

  /// Leave developer mode. No password required.
  void disableDeveloperMode() {
    if (_currentRole == UserRole.normal) return;
    _currentRole = UserRole.normal;
    _roleController.add(_currentRole);
    // Fire-and-forget: an explicit exit must not be reported as an interrupted
    // session on the next launch. Kept synchronous so the existing callers
    // (the switch tile) don't have to become async.
    unawaited(_setDevSessionFlag(false));
    Logger.diagnostic('[ROLE] developer mode disabled');
  }

  /// Change the developer-mode password. Requires the old password to
  /// match. Returns `false` if the old password is wrong, the new
  /// password is too short, or persistence fails.
  Future<bool> changePassword(
    String oldPlaintext,
    String newPlaintext,
  ) async {
    if (newPlaintext.length < minPasswordLength) return false;
    final stored = await _loadStoredHashOrDefault();
    if (_hash(oldPlaintext) != stored) return false;
    final newHash = _hash(newPlaintext);
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(_passwordHashKey, newHash);
    if (ok) {
      Logger.diagnostic('[ROLE] password changed');
    }
    return ok;
  }

  /// Reset the password by removing the stored hash so the factory
  /// default applies again.
  ///
  /// Intentionally requires no auth: a user who forgot their custom
  /// password needs an escape hatch. The security model is unchanged
  /// because the user must still know the factory default to actually
  /// enter developer mode after the reset, and field operators do not
  /// know the factory default.
  Future<void> resetPasswordToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordHashKey);
    Logger.diagnostic('[ROLE] password reset to factory default');
  }

  /// Test-only helper: closes the broadcast stream.
  void dispose() {
    _roleController.close();
  }

  /// Returns `true` exactly once when the previous run ended while developer
  /// mode was still active — i.e. the role was dropped by a restart the user
  /// never asked for. The flag is cleared on read so the notice is one-shot.
  ///
  /// ADR-0005 is untouched: the role itself is still never restored and every
  /// launch begins in [UserRole.normal]. This only lets the UI say what
  /// happened instead of silently shrinking the command surface.
  Future<bool> consumeInterruptedDeveloperSession() async {
    final prefs = await SharedPreferences.getInstance();
    final wasActive = prefs.getBool(_devSessionFlagKey) ?? false;
    if (wasActive) {
      await prefs.remove(_devSessionFlagKey);
      Logger.diagnostic('[ROLE] previous developer session was interrupted');
    }
    return wasActive;
  }

  Future<void> _setDevSessionFlag(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    if (active) {
      await prefs.setBool(_devSessionFlagKey, true);
    } else {
      await prefs.remove(_devSessionFlagKey);
    }
  }

  Future<String> _loadStoredHashOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_passwordHashKey);
    return stored ?? defaultPasswordHashHex;
  }

  String _hash(String plaintext) =>
      sha256.convert(utf8.encode(plaintext)).toString();
}
