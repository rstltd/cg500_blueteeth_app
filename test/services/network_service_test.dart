import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkStatus', () {
    test('should have 4 status types', () {
      expect(NetworkStatus.values.length, 4);
    });

    test('should contain none status', () {
      expect(NetworkStatus.values, contains(NetworkStatus.none));
    });

    test('should contain mobile status', () {
      expect(NetworkStatus.values, contains(NetworkStatus.mobile));
    });

    test('should contain wifi status', () {
      expect(NetworkStatus.values, contains(NetworkStatus.wifi));
    });

    test('should contain unknown status', () {
      expect(NetworkStatus.values, contains(NetworkStatus.unknown));
    });

    group('displayName', () {
      test('none should display "No Connection"', () {
        expect(NetworkStatus.none.displayName, 'No Connection');
      });

      test('mobile should display "Mobile Data"', () {
        expect(NetworkStatus.mobile.displayName, 'Mobile Data');
      });

      test('wifi should display "WiFi"', () {
        expect(NetworkStatus.wifi.displayName, 'WiFi');
      });

      test('unknown should display "Unknown"', () {
        expect(NetworkStatus.unknown.displayName, 'Unknown');
      });
    });
  });

  group('NetworkService', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    group('DI pattern', () {
      test('should create independent instances with constructor', () {
        final instance1 = NetworkService();
        final instance2 = NetworkService();
        // With DI pattern, each call creates a new instance
        expect(identical(instance1, instance2), false);
        instance1.dispose();
        instance2.dispose();
      });
    });

    group('networkStream', () {
      test('should be available', () {
        expect(networkService.networkStream, isA<Stream<NetworkStatus>>());
      });
    });

    group('currentStatus', () {
      test('should return NetworkStatus', () {
        expect(networkService.currentStatus, isA<NetworkStatus>());
      });
    });

    group('isSuitableForDownload', () {
      test('should return bool', () {
        final result = networkService.isSuitableForDownload(wifiOnly: true);
        expect(result, isA<bool>());
      });

      test('should return bool for wifiOnly false', () {
        final result = networkService.isSuitableForDownload(wifiOnly: false);
        expect(result, isA<bool>());
      });
    });

    group('getStatusDescription', () {
      test('should return string', () {
        final description = networkService.getStatusDescription();
        expect(description, isA<String>());
        expect(description, isNotEmpty);
      });
    });

    group('getNetworkTypeDisplayName', () {
      test('should return string', () {
        final displayName = networkService.getNetworkTypeDisplayName();
        expect(displayName, isA<String>());
        expect(displayName, isNotEmpty);
      });
    });

    group('estimateDownloadTime', () {
      test('should return string for small file', () {
        final estimate = networkService.estimateDownloadTime(1024 * 1024); // 1 MB
        expect(estimate, isA<String>());
      });

      test('should return string for medium file', () {
        final estimate = networkService.estimateDownloadTime(50 * 1024 * 1024); // 50 MB
        expect(estimate, isA<String>());
      });

      test('should return string for large file', () {
        final estimate = networkService.estimateDownloadTime(500 * 1024 * 1024); // 500 MB
        expect(estimate, isA<String>());
      });

      test('should return string for very large file', () {
        final estimate = networkService.estimateDownloadTime(5 * 1024 * 1024 * 1024); // 5 GB
        expect(estimate, isA<String>());
      });
    });

    group('dispose', () {
      test('should not throw', () {
        expect(() => networkService.dispose(), returnsNormally);
      });
    });
  });

  group('NetworkService status descriptions', () {
    test('getStatusDescription returns valid descriptions for all status types', () {
      final service = NetworkService();

      // Test that description is non-empty string
      final description = service.getStatusDescription();
      expect(description, isA<String>());
      expect(description.isNotEmpty, true);
    });

    test('getNetworkTypeDisplayName returns valid display names', () {
      final service = NetworkService();

      final displayName = service.getNetworkTypeDisplayName();
      expect(displayName, isA<String>());
      expect(displayName.isNotEmpty, true);
    });
  });

  group('NetworkService download estimation', () {
    late NetworkService service;

    setUp(() {
      service = NetworkService();
    });

    test('should estimate seconds for very small files', () {
      // Very small file should show seconds
      final estimate = service.estimateDownloadTime(100 * 1024); // 100 KB
      expect(estimate, anyOf(contains('s'), contains('Cannot')));
    });

    test('should handle zero byte file', () {
      final estimate = service.estimateDownloadTime(0);
      expect(estimate, isA<String>());
    });

    test('should handle 1 byte file', () {
      final estimate = service.estimateDownloadTime(1);
      expect(estimate, isA<String>());
    });
  });

  group('NetworkStatus enum comprehensive tests', () {
    test('should have correct index for each status', () {
      expect(NetworkStatus.none.index, 0);
      expect(NetworkStatus.mobile.index, 1);
      expect(NetworkStatus.wifi.index, 2);
      expect(NetworkStatus.unknown.index, 3);
    });

    test('should have unique display names', () {
      final displayNames = NetworkStatus.values.map((s) => s.displayName).toSet();
      expect(displayNames.length, 4);
    });

    test('none should have correct name property', () {
      expect(NetworkStatus.none.name, 'none');
    });

    test('mobile should have correct name property', () {
      expect(NetworkStatus.mobile.name, 'mobile');
    });

    test('wifi should have correct name property', () {
      expect(NetworkStatus.wifi.name, 'wifi');
    });

    test('unknown should have correct name property', () {
      expect(NetworkStatus.unknown.name, 'unknown');
    });

    test('should be comparable via index', () {
      expect(NetworkStatus.none.index < NetworkStatus.wifi.index, true);
      expect(NetworkStatus.mobile.index < NetworkStatus.wifi.index, true);
    });

    test('should be usable in switch statements', () {
      for (final status in NetworkStatus.values) {
        final result = switch (status) {
          NetworkStatus.none => 'no connection',
          NetworkStatus.mobile => 'mobile',
          NetworkStatus.wifi => 'wifi',
          NetworkStatus.unknown => 'unknown',
        };
        expect(result, isNotEmpty);
      }
    });

    test('should be usable in lists and sets', () {
      final list = [NetworkStatus.wifi, NetworkStatus.mobile];
      expect(list.contains(NetworkStatus.wifi), true);
      expect(list.contains(NetworkStatus.none), false);

      final statusSet = {NetworkStatus.wifi, NetworkStatus.mobile};
      // Adding wifi again to test set behavior
      final statusList = [NetworkStatus.wifi, NetworkStatus.mobile, NetworkStatus.wifi];
      final uniqueSet = statusList.toSet();
      expect(statusSet.length, 2);
      expect(uniqueSet.length, 2); // wifi added twice but set has unique values
    });
  });

  group('NetworkService stream behavior', () {
    test('networkStream should be broadcast stream', () {
      final service = NetworkService();
      // Should be able to listen multiple times
      final sub1 = service.networkStream.listen((_) {});
      final sub2 = service.networkStream.listen((_) {});

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);

      sub1.cancel();
      sub2.cancel();
    });

    test('currentStatus should have initial value', () {
      final service = NetworkService();
      final status = service.currentStatus;
      expect(NetworkStatus.values.contains(status), true);
    });
  });

  group('NetworkService download suitability edge cases', () {
    late NetworkService service;

    setUp(() {
      service = NetworkService();
    });

    test('wifiOnly true should be consistent', () {
      final result1 = service.isSuitableForDownload(wifiOnly: true);
      final result2 = service.isSuitableForDownload(wifiOnly: true);
      expect(result1, result2);
    });

    test('wifiOnly false should be consistent', () {
      final result1 = service.isSuitableForDownload(wifiOnly: false);
      final result2 = service.isSuitableForDownload(wifiOnly: false);
      expect(result1, result2);
    });

    test('should return valid bool type', () {
      final result = service.isSuitableForDownload(wifiOnly: true);
      expect(result.runtimeType, bool);
    });
  });

  group('NetworkService description methods comprehensive', () {
    late NetworkService service;

    setUp(() {
      service = NetworkService();
    });

    test('getStatusDescription should contain connection info', () {
      final description = service.getStatusDescription();
      // The descriptions are Traditional Chinese now (F-006); assert against
      // the actual strings rather than English substrings.
      expect(
        const ['已透過 WiFi 連線', '已透過行動網路連線', '無網路連線', '網路狀態未知']
            .contains(description),
        true,
      );
    });

    test('getNetworkTypeDisplayName should be one of known values', () {
      final displayName = service.getNetworkTypeDisplayName();
      final knownNames = ['WiFi', '行動網路', '無連線', '未知'];
      expect(knownNames.contains(displayName), true);
    });

    test('getStatusDescription should match getNetworkTypeDisplayName context', () {
      final description = service.getStatusDescription();
      final displayName = service.getNetworkTypeDisplayName();

      // Both should be non-empty
      expect(description.isNotEmpty, true);
      expect(displayName.isNotEmpty, true);
    });
  });

  group('NetworkService estimateDownloadTime comprehensive', () {
    late NetworkService service;

    setUp(() {
      service = NetworkService();
    });

    test('should handle boundary values', () {
      // Test various boundary values
      expect(service.estimateDownloadTime(0), isA<String>());
      expect(service.estimateDownloadTime(1), isA<String>());
      expect(service.estimateDownloadTime(1023), isA<String>());
      expect(service.estimateDownloadTime(1024), isA<String>());
    });

    test('should handle KB range files', () {
      final estimate1KB = service.estimateDownloadTime(1024);
      final estimate100KB = service.estimateDownloadTime(100 * 1024);
      final estimate512KB = service.estimateDownloadTime(512 * 1024);

      expect(estimate1KB, isA<String>());
      expect(estimate100KB, isA<String>());
      expect(estimate512KB, isA<String>());
    });

    test('should handle MB range files', () {
      final estimate1MB = service.estimateDownloadTime(1024 * 1024);
      final estimate10MB = service.estimateDownloadTime(10 * 1024 * 1024);
      final estimate100MB = service.estimateDownloadTime(100 * 1024 * 1024);

      expect(estimate1MB, isA<String>());
      expect(estimate10MB, isA<String>());
      expect(estimate100MB, isA<String>());
    });

    test('should handle GB range files', () {
      final estimate1GB = service.estimateDownloadTime(1024 * 1024 * 1024);
      final estimate5GB = service.estimateDownloadTime(5 * 1024 * 1024 * 1024);

      expect(estimate1GB, isA<String>());
      expect(estimate5GB, isA<String>());
    });

    test('should return time unit indicators or cannot message', () {
      final estimate = service.estimateDownloadTime(50 * 1024 * 1024);
      // Should contain a time unit (s, m, h) or "Cannot"
      expect(
        estimate.contains('s') ||
        estimate.contains('m') ||
        estimate.contains('h') ||
        estimate.contains('Cannot'),
        true,
      );
    });

    test('estimates should be consistent for same file size', () {
      final size = 100 * 1024 * 1024; // 100 MB
      final estimate1 = service.estimateDownloadTime(size);
      final estimate2 = service.estimateDownloadTime(size);
      expect(estimate1, estimate2);
    });
  });

  group('NetworkService DI behavior', () {
    test('multiple constructor calls should create independent instances', () {
      final instances = <NetworkService>[];
      for (int i = 0; i < 10; i++) {
        instances.add(NetworkService());
      }

      // With DI pattern, each call creates a new instance
      for (int i = 1; i < instances.length; i++) {
        expect(identical(instances[0], instances[i]), false);
      }

      for (final instance in instances) {
        instance.dispose();
      }
    });

    test('constructor instances are independent', () {
      final instance1 = NetworkService();
      final instance2 = NetworkService();

      // Both should have same initial status
      expect(instance1.currentStatus, instance2.currentStatus);

      instance1.dispose();
      instance2.dispose();
    });
  });

  group('NetworkService dispose behavior', () {
    test('dispose should be callable multiple times', () {
      final service = NetworkService();
      expect(() {
        service.dispose();
        service.dispose();
      }, returnsNormally);
    });

    test('dispose should not throw exception', () {
      final service = NetworkService();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('NetworkStatus displayName consistency', () {
    test('all statuses should have non-empty displayName', () {
      for (final status in NetworkStatus.values) {
        expect(status.displayName.isNotEmpty, true);
      }
    });

    test('displayName should not contain leading/trailing whitespace', () {
      for (final status in NetworkStatus.values) {
        expect(status.displayName.trim(), status.displayName);
      }
    });

    test('displayName should be title case or proper format', () {
      for (final status in NetworkStatus.values) {
        // First character should be uppercase
        expect(status.displayName[0], status.displayName[0].toUpperCase());
      }
    });
  });
}
