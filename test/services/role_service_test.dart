import 'package:cg500_blueteeth_app/models/role/user_role.dart';
import 'package:cg500_blueteeth_app/services/role_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('cold start defaults to normal role', () {
      final service = RoleService();
      expect(service.currentRole, UserRole.normal);
    });

    test('factory default password unlocks developer mode', () async {
      final service = RoleService();
      final ok = await service.tryEnableDeveloperMode('cg500dev');
      expect(ok, isTrue);
      expect(service.currentRole, UserRole.developer);
    });

    test('wrong password keeps role as normal', () async {
      final service = RoleService();
      final ok = await service.tryEnableDeveloperMode('wrong');
      expect(ok, isFalse);
      expect(service.currentRole, UserRole.normal);
    });

    test('successful unlock emits developer on roleStream', () async {
      final service = RoleService();
      final emitted = <UserRole>[];
      final sub = service.roleStream.listen(emitted.add);
      await service.tryEnableDeveloperMode('cg500dev');
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [UserRole.developer]);
      await sub.cancel();
    });

    test('disableDeveloperMode emits normal on roleStream', () async {
      final service = RoleService();
      await service.tryEnableDeveloperMode('cg500dev');

      final emitted = <UserRole>[];
      final sub = service.roleStream.listen(emitted.add);
      service.disableDeveloperMode();
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [UserRole.normal]);
      expect(service.currentRole, UserRole.normal);
      await sub.cancel();
    });

    test('disableDeveloperMode is no-op when already normal', () async {
      final service = RoleService();
      final emitted = <UserRole>[];
      final sub = service.roleStream.listen(emitted.add);
      service.disableDeveloperMode();
      await Future<void>.delayed(Duration.zero);
      expect(emitted, isEmpty);
      await sub.cancel();
    });

    test('changePassword fails with wrong old password', () async {
      final service = RoleService();
      final ok = await service.changePassword('wrong', 'newpass');
      expect(ok, isFalse);
    });

    test('changePassword fails when new password is too short', () async {
      final service = RoleService();
      final ok = await service.changePassword('cg500dev', 'abc');
      expect(ok, isFalse);
    });

    test('changePassword succeeds and new password unlocks', () async {
      final service = RoleService();
      final ok = await service.changePassword('cg500dev', 'newpass');
      expect(ok, isTrue);

      // Old password no longer works
      expect(await service.tryEnableDeveloperMode('cg500dev'), isFalse);
      // New password works
      expect(await service.tryEnableDeveloperMode('newpass'), isTrue);
    });

    test('SharedPreferences stores hash, not plaintext', () async {
      final service = RoleService();
      await service.changePassword('cg500dev', 'mysecret');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('role_dev_password_hash');
      expect(stored, isNotNull);
      expect(stored, isNot(contains('mysecret')));
      expect(stored!.length, 64); // sha256 hex length
    });

    test('multiple stream listeners all receive events', () async {
      final service = RoleService();
      final a = <UserRole>[];
      final b = <UserRole>[];
      final subA = service.roleStream.listen(a.add);
      final subB = service.roleStream.listen(b.add);
      await service.tryEnableDeveloperMode('cg500dev');
      service.disableDeveloperMode();
      await Future<void>.delayed(Duration.zero);
      expect(a, [UserRole.developer, UserRole.normal]);
      expect(b, [UserRole.developer, UserRole.normal]);
      await subA.cancel();
      await subB.cancel();
    });

    test('resetPasswordToDefault restores factory default', () async {
      final service = RoleService();
      await service.changePassword('cg500dev', 'custom1');
      // Custom password works
      expect(await service.tryEnableDeveloperMode('custom1'), isTrue);
      service.disableDeveloperMode();

      await service.resetPasswordToDefault();

      // Factory default works again
      expect(await service.tryEnableDeveloperMode('cg500dev'), isTrue);
    });

    test('resetPasswordToDefault invalidates the previous custom password',
        () async {
      final service = RoleService();
      await service.changePassword('cg500dev', 'custom2');

      await service.resetPasswordToDefault();

      service.disableDeveloperMode();
      // Old custom password no longer works
      expect(await service.tryEnableDeveloperMode('custom2'), isFalse);
    });

    // F-008: an Android Activity recreate spawns a new Dart isolate and
    // rebuilds every singleton inside the same OS process, so developer mode
    // vanished with no visible restart and no notice.
    test('a restart while elevated is reported once, then cleared', () async {
      final before = RoleService();
      await before.tryEnableDeveloperMode('cg500dev');

      // The isolate restarting: brand-new instance, same SharedPreferences.
      final after = RoleService();
      expect(after.currentRole, UserRole.normal,
          reason: 'ADR-0005 — the role is never restored');
      expect(await after.consumeInterruptedDeveloperSession(), isTrue);
      expect(await after.consumeInterruptedDeveloperSession(), isFalse,
          reason: 'the notice is one-shot');
    });

    test('an explicit exit is not reported as interrupted', () async {
      final service = RoleService();
      await service.tryEnableDeveloperMode('cg500dev');
      service.disableDeveloperMode();
      await Future<void>.delayed(Duration.zero); // let the flag write land

      expect(await RoleService().consumeInterruptedDeveloperSession(), isFalse);
    });

    test('never entering developer mode reports nothing', () async {
      expect(
        await RoleService().consumeInterruptedDeveloperSession(),
        isFalse,
      );
    });
  });
}
