import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/update_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdatePreferencesStore', () {
    test('current is null and isLoaded is false before load', () {
      final store = UpdatePreferencesStore();

      expect(store.current, isNull);
      expect(store.isLoaded, isFalse);

      store.dispose();
    });

    test('load populates current with disk-backed defaults', () async {
      final store = UpdatePreferencesStore();
      await store.load();

      expect(store.isLoaded, isTrue);
      expect(store.current, isNotNull);
      expect(store.current!.autoCheckEnabled, isTrue);
      expect(store.current!.wifiOnlyDownload, isTrue);
      expect(store.current!.skippedVersions, isEmpty);

      store.dispose();
    });

    test('setWifiOnlyDownload updates current and emits on changeStream',
        () async {
      final store = UpdatePreferencesStore();
      await store.load();

      final changes = <bool>[];
      final sub = store.changeStream.listen((p) => changes.add(p.wifiOnlyDownload));

      await store.setWifiOnlyDownload(false);
      await Future<void>.delayed(Duration.zero); // drain stream microtask

      expect(store.current!.wifiOnlyDownload, isFalse);
      expect(changes, [false]);

      await sub.cancel();
      store.dispose();
    });

    test('setWifiOnlyDownload persists across a fresh load', () async {
      final s1 = UpdatePreferencesStore();
      await s1.load();
      await s1.setWifiOnlyDownload(false);
      s1.dispose();

      final s2 = UpdatePreferencesStore();
      await s2.load();

      expect(s2.current!.wifiOnlyDownload, isFalse);

      s2.dispose();
    });

    test('skipVersion adds to the list and persists', () async {
      final store = UpdatePreferencesStore();
      await store.load();

      await store.skipVersion('1.2.3');
      await store.skipVersion('1.2.4');

      expect(store.current!.skippedVersions, ['1.2.3', '1.2.4']);

      store.dispose();
    });

    test('skipVersion of an existing version does not duplicate', () async {
      final store = UpdatePreferencesStore();
      await store.load();

      await store.skipVersion('1.2.3');
      await store.skipVersion('1.2.3');

      expect(store.current!.skippedVersions, ['1.2.3']);

      store.dispose();
    });

    test('unskipVersion removes from list', () async {
      final store = UpdatePreferencesStore();
      await store.load();
      await store.skipVersion('1.2.3');
      await store.skipVersion('1.2.4');

      await store.unskipVersion('1.2.3');

      expect(store.current!.skippedVersions, ['1.2.4']);

      store.dispose();
    });

    test('clearSkippedVersions empties the list', () async {
      final store = UpdatePreferencesStore();
      await store.load();
      await store.skipVersion('1.2.3');
      await store.skipVersion('1.2.4');

      await store.clearSkippedVersions();

      expect(store.current!.skippedVersions, isEmpty);

      store.dispose();
    });

    test('replace overwrites every field and emits', () async {
      final store = UpdatePreferencesStore();
      await store.load();

      final changes = <bool>[];
      final sub = store.changeStream.listen(
        (p) => changes.add(p.autoCheckEnabled),
      );

      final fresh = store.current!.copyWith(
        autoCheckEnabled: false,
        wifiOnlyDownload: false,
      );
      await store.replace(fresh);
      await Future<void>.delayed(Duration.zero); // drain stream microtask

      expect(store.current!.autoCheckEnabled, isFalse);
      expect(store.current!.wifiOnlyDownload, isFalse);
      expect(changes, [false]);

      await sub.cancel();
      store.dispose();
    });

    test('mutations before load are silently ignored (current still null)',
        () async {
      final store = UpdatePreferencesStore();

      await store.setWifiOnlyDownload(false);
      await store.skipVersion('1.0.0');

      expect(store.current, isNull);

      store.dispose();
    });

    test('changeStream emits on every successful mutation', () async {
      final store = UpdatePreferencesStore();
      await store.load();

      final emissions = <int>[];
      final sub = store.changeStream
          .listen((p) => emissions.add(p.skippedVersions.length));

      await store.skipVersion('1.0.0');
      await Future<void>.delayed(Duration.zero);
      await store.skipVersion('1.0.1');
      await Future<void>.delayed(Duration.zero);
      await store.unskipVersion('1.0.0');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [1, 2, 1]);

      await sub.cancel();
      store.dispose();
    });
  });
}
