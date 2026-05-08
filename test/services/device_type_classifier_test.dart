import 'package:cg500_blueteeth_app/services/device_type_classifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyDeviceType', () {
    test('A01LT prefix maps to GNSS', () {
      expect(classifyDeviceType('A01LT12345'), RstDeviceType.gnss);
      expect(classifyDeviceType('A01LT'), RstDeviceType.gnss);
    });

    test('B01LT prefix maps to accelerometer', () {
      expect(classifyDeviceType('B01LT12345'), RstDeviceType.accelerometer);
      expect(classifyDeviceType('B01LT'), RstDeviceType.accelerometer);
    });

    test('lowercase prefix matches case-insensitively', () {
      expect(classifyDeviceType('a01lt99999'), RstDeviceType.gnss);
      expect(classifyDeviceType('b01lt99999'), RstDeviceType.accelerometer);
    });

    test('mixed case matches', () {
      expect(classifyDeviceType('a01Lt12345'), RstDeviceType.gnss);
      expect(classifyDeviceType('B01lT99999'), RstDeviceType.accelerometer);
    });

    test('empty name returns unknown', () {
      expect(classifyDeviceType(''), RstDeviceType.unknown);
    });

    test('non-matching name returns unknown', () {
      expect(classifyDeviceType('SonyHeadphones'), RstDeviceType.unknown);
      expect(classifyDeviceType('My Phone'), RstDeviceType.unknown);
      expect(classifyDeviceType('A01'), RstDeviceType.unknown); // partial prefix
    });

    test('leading whitespace is NOT trimmed (firmware-bug surface)', () {
      // Documented behaviour: a name that starts with whitespace does not
      // match the prefix, so it falls through to unknown. Surfaces a
      // misconfigured firmware rather than silently classifying it.
      expect(classifyDeviceType(' A01LT12345'), RstDeviceType.unknown);
    });

    test('inclinometer prefix is reserved but unassigned', () {
      // CONTEXT.md flags the inclinometer prefix as undefined as of 2026-05.
      // No name should classify as inclinometer until a prefix is added to
      // the map. This test is the canary that catches a premature mapping.
      // Using a plausible-but-not-real value to assert "no match yet".
      expect(classifyDeviceType('C01LT00000'), RstDeviceType.unknown);
    });
  });

  group('iconForDeviceType', () {
    test('GNSS returns satellite_alt regardless of connection state', () {
      expect(
        iconForDeviceType(RstDeviceType.gnss, connected: false),
        Icons.satellite_alt,
      );
      expect(
        iconForDeviceType(RstDeviceType.gnss, connected: true),
        Icons.satellite_alt,
      );
    });

    test('accelerometer returns vibration regardless of connection state', () {
      expect(
        iconForDeviceType(RstDeviceType.accelerometer, connected: false),
        Icons.vibration,
      );
      expect(
        iconForDeviceType(RstDeviceType.accelerometer, connected: true),
        Icons.vibration,
      );
    });

    test('inclinometer returns architecture regardless of connection state', () {
      expect(
        iconForDeviceType(RstDeviceType.inclinometer, connected: false),
        Icons.architecture,
      );
      expect(
        iconForDeviceType(RstDeviceType.inclinometer, connected: true),
        Icons.architecture,
      );
    });

    test('unknown swaps between bluetooth and bluetooth_connected', () {
      expect(
        iconForDeviceType(RstDeviceType.unknown, connected: false),
        Icons.bluetooth,
      );
      expect(
        iconForDeviceType(RstDeviceType.unknown, connected: true),
        Icons.bluetooth_connected,
      );
    });
  });
}
