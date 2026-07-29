import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/utils/responsive_utils.dart';

void main() {
  group('DeviceType', () {
    test('should have 3 device types', () {
      expect(DeviceType.values.length, 3);
    });

    test('should contain mobile type', () {
      expect(DeviceType.values, contains(DeviceType.mobile));
    });

    test('should contain tablet type', () {
      expect(DeviceType.values, contains(DeviceType.tablet));
    });

    test('should contain desktop type', () {
      expect(DeviceType.values, contains(DeviceType.desktop));
    });
  });

  group('ScreenOrientation', () {
    test('should have 2 orientation types', () {
      expect(ScreenOrientation.values.length, 2);
    });

    test('should contain portrait orientation', () {
      expect(ScreenOrientation.values, contains(ScreenOrientation.portrait));
    });

    test('should contain landscape orientation', () {
      expect(ScreenOrientation.values, contains(ScreenOrientation.landscape));
    });
  });

  group('ResponsiveUtils constants', () {
    test('mobileBreakpoint should be 600', () {
      expect(ResponsiveUtils.mobileBreakpoint, 600);
    });

    test('tabletBreakpoint should be 1024', () {
      expect(ResponsiveUtils.tabletBreakpoint, 1024);
    });

    test('mobilePadding should be 16.0', () {
      expect(ResponsiveUtils.mobilePadding, 16.0);
    });

    test('tabletPadding should be 24.0', () {
      expect(ResponsiveUtils.tabletPadding, 24.0);
    });

    test('desktopPadding should be 32.0', () {
      expect(ResponsiveUtils.desktopPadding, 32.0);
    });

    test('mobileCardMaxWidth should be infinity', () {
      expect(ResponsiveUtils.mobileCardMaxWidth, double.infinity);
    });

    test('tabletCardMaxWidth should be 400.0', () {
      expect(ResponsiveUtils.tabletCardMaxWidth, 400.0);
    });

    test('desktopCardMaxWidth should be 480.0', () {
      expect(ResponsiveUtils.desktopCardMaxWidth, 480.0);
    });
  });

  group('ResponsiveUtils with BuildContext', () {
    testWidgets('getDeviceType should return mobile for small screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.mobile);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return tablet for medium screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.tablet);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return desktop for large screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.desktop);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return mobile at boundary (599)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(599, 800)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.mobile);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return tablet at boundary (600)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.tablet);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return tablet at boundary (1023)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1023, 800)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.tablet);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType should return desktop at boundary (1024)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 800)),
          child: Builder(
            builder: (context) {
              final deviceType = ResponsiveUtils.getDeviceType(context);
              expect(deviceType, DeviceType.desktop);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getOrientation should return portrait',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final orientation = ResponsiveUtils.getOrientation(context);
              expect(orientation, ScreenOrientation.portrait);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getOrientation should return landscape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 400)),
          child: Builder(
            builder: (context) {
              final orientation = ResponsiveUtils.getOrientation(context);
              expect(orientation, ScreenOrientation.landscape);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isMobile should return true for mobile screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isMobile(context), true);
              expect(ResponsiveUtils.isTablet(context), false);
              expect(ResponsiveUtils.isDesktop(context), false);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet should return true for tablet screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isMobile(context), false);
              expect(ResponsiveUtils.isTablet(context), true);
              expect(ResponsiveUtils.isDesktop(context), false);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop should return true for desktop screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isMobile(context), false);
              expect(ResponsiveUtils.isTablet(context), false);
              expect(ResponsiveUtils.isDesktop(context), true);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isLandscape should return true for landscape orientation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 400)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isLandscape(context), true);
              expect(ResponsiveUtils.isPortrait(context), false);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isPortrait should return true for portrait orientation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isLandscape(context), false);
              expect(ResponsiveUtils.isPortrait(context), true);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding should return mobile padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveUtils.getResponsivePadding(context);
              expect(padding, EdgeInsets.all(ResponsiveUtils.mobilePadding));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding should return tablet padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveUtils.getResponsivePadding(context);
              expect(padding, EdgeInsets.all(ResponsiveUtils.tabletPadding));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding should return desktop padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveUtils.getResponsivePadding(context);
              expect(padding, EdgeInsets.all(ResponsiveUtils.desktopPadding));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveMargin should return mobile margin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final margin = ResponsiveUtils.getResponsiveMargin(context);
              expect(margin, EdgeInsets.all(ResponsiveUtils.mobilePadding * 0.75));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveMargin should return tablet margin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final margin = ResponsiveUtils.getResponsiveMargin(context);
              expect(margin, EdgeInsets.all(ResponsiveUtils.tabletPadding * 0.75));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveMargin should return desktop margin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final margin = ResponsiveUtils.getResponsiveMargin(context);
              expect(margin, EdgeInsets.all(ResponsiveUtils.desktopPadding * 0.75));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getCardMaxWidth should return correct values',
        (WidgetTester tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getCardMaxWidth(context), double.infinity);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getCardMaxWidth(context), 400.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getCardMaxWidth(context), 480.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for mobile portrait',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 1);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for mobile landscape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 300)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 2);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for tablet portrait',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 2);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for tablet landscape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 600)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 3);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for desktop portrait',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1100, 1400)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 3);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns should return correct columns for desktop landscape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final columns = ResponsiveUtils.getGridColumns(context);
              expect(columns, 4);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveFontSize should scale correctly for mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 16.0);
              expect(fontSize, 16.0); // Mobile multiplier is 1.0
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveFontSize should scale correctly for tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 16.0);
              expect(fontSize, 16.0 * 1.1); // Tablet multiplier is 1.1
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveFontSize should scale correctly for desktop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 16.0);
              expect(fontSize, 16.0 * 1.2); // Desktop multiplier is 1.2
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveFontSize should not apply the user text scale',
        (WidgetTester tester) async {
      // Flutter's Text/RichText already scales fontSize by
      // MediaQuery.textScalerOf at paint time. If this helper multiplied the
      // user scale in as well it would be applied twice (scale squared), so
      // the returned value must depend on the device size only.
      // Not const: Size overrides ==, which a const map key may not do.
      final cases = <Size, double>{
        const Size(400, 800): 16.0, // mobile, multiplier 1.0
        const Size(800, 1024): 16.0 * 1.1, // tablet
        const Size(1400, 900): 16.0 * 1.2, // desktop
      };

      for (final entry in cases.entries) {
        for (final scale in <double>[1.5, 2.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: entry.key,
                textScaler: TextScaler.linear(scale),
              ),
              child: Builder(
                builder: (context) {
                  expect(
                    ResponsiveUtils.getResponsiveFontSize(context, 16.0),
                    entry.value,
                    reason: 'size ${entry.key} at text scale $scale',
                  );
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      }
    });

    testWidgets('getResponsiveIconSize should scale correctly',
        (WidgetTester tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getResponsiveIconSize(context, 24.0), 24.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getResponsiveIconSize(context, 24.0), 24.0 * 1.2);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getResponsiveIconSize(context, 24.0), 24.0 * 1.4);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getSafeAreaPadding should return correct padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(top: 44, bottom: 34, left: 0, right: 0),
          ),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveUtils.getSafeAreaPadding(context);
              expect(padding.top, 44);
              expect(padding.bottom, 34);
              expect(padding.left, 0);
              expect(padding.right, 0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveHeight should calculate correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final height = ResponsiveUtils.getResponsiveHeight(context, 50);
              expect(height, 400.0); // 50% of 800
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveWidth should calculate correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final width = ResponsiveUtils.getResponsiveWidth(context, 50);
              expect(width, 200.0); // 50% of 400
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getAppBarHeight should return correct heights',
        (WidgetTester tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getAppBarHeight(context), kToolbarHeight);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getAppBarHeight(context), kToolbarHeight + 8);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getAppBarHeight(context), kToolbarHeight + 16);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getMinButtonSize should return correct sizes',
        (WidgetTester tester) async {
      // Mobile - iOS HIG
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getMinButtonSize(context), 44.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet - Material Design
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getMinButtonSize(context), 48.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop - smaller due to precise cursor
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getMinButtonSize(context), 40.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveConstraints should return correct constraints for mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final constraints = ResponsiveUtils.getResponsiveConstraints(context);
              expect(constraints.maxWidth, 400.0);
              expect(constraints.minWidth, 0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveConstraints should return correct constraints for tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              final constraints = ResponsiveUtils.getResponsiveConstraints(context);
              expect(constraints.maxWidth, 720.0); // min(800 * 0.9, 800)
              expect(constraints.minWidth, 400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsiveConstraints should return correct constraints for desktop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              final constraints = ResponsiveUtils.getResponsiveConstraints(context);
              expect(constraints.maxWidth, 1120.0); // min(1400 * 0.8, 1200)
              expect(constraints.minWidth, 600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('canShowSideBySideLayout should return false for mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.canShowSideBySideLayout(context), false);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('canShowSideBySideLayout should return false for tablet portrait',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.canShowSideBySideLayout(context), false);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('canShowSideBySideLayout should return true for desktop landscape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.canShowSideBySideLayout(context), true);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getStaggeredGridCrossAxisCount should return correct values',
        (WidgetTester tester) async {
      // < 600
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getStaggeredGridCrossAxisCount(context), 1);
              return const SizedBox();
            },
          ),
        ),
      );

      // 600-899
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getStaggeredGridCrossAxisCount(context), 2);
              return const SizedBox();
            },
          ),
        ),
      );

      // 900-1199
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getStaggeredGridCrossAxisCount(context), 3);
              return const SizedBox();
            },
          ),
        ),
      );

      // >= 1200
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getStaggeredGridCrossAxisCount(context), 4);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getIconSize should return correct values',
        (WidgetTester tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getIconSize(context, base: 24.0), 24.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getIconSize(context, base: 24.0), 24.0 * 1.15);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getIconSize(context, base: 24.0), 24.0 * 1.3);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
