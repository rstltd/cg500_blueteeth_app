import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/animation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimationService constants', () {
    test('defaultDuration should be 300 milliseconds', () {
      expect(AnimationService.defaultDuration, const Duration(milliseconds: 300));
    });

    test('fastDuration should be 200 milliseconds', () {
      expect(AnimationService.fastDuration, const Duration(milliseconds: 200));
    });

    test('slowDuration should be 500 milliseconds', () {
      expect(AnimationService.slowDuration, const Duration(milliseconds: 500));
    });

    test('scanningDuration should be 1500 milliseconds', () {
      expect(AnimationService.scanningDuration, const Duration(milliseconds: 1500));
    });

    test('defaultCurve should be Curves.easeInOut', () {
      expect(AnimationService.defaultCurve, Curves.easeInOut);
    });

    test('bounceInCurve should be Curves.bounceIn', () {
      expect(AnimationService.bounceInCurve, Curves.bounceIn);
    });

    test('bounceOutCurve should be Curves.bounceOut', () {
      expect(AnimationService.bounceOutCurve, Curves.bounceOut);
    });

    test('elasticInCurve should be Curves.elasticIn', () {
      expect(AnimationService.elasticInCurve, Curves.elasticIn);
    });

    test('elasticOutCurve should be Curves.elasticOut', () {
      expect(AnimationService.elasticOutCurve, Curves.elasticOut);
    });
  });

  group('PageTransitionType', () {
    test('should have 7 transition types', () {
      expect(PageTransitionType.values.length, 7);
    });

    test('should contain slideFromRight', () {
      expect(PageTransitionType.values, contains(PageTransitionType.slideFromRight));
    });

    test('should contain slideFromLeft', () {
      expect(PageTransitionType.values, contains(PageTransitionType.slideFromLeft));
    });

    test('should contain slideFromBottom', () {
      expect(PageTransitionType.values, contains(PageTransitionType.slideFromBottom));
    });

    test('should contain slideFromTop', () {
      expect(PageTransitionType.values, contains(PageTransitionType.slideFromTop));
    });

    test('should contain fade', () {
      expect(PageTransitionType.values, contains(PageTransitionType.fade));
    });

    test('should contain scale', () {
      expect(PageTransitionType.values, contains(PageTransitionType.scale));
    });

    test('should contain rotation', () {
      expect(PageTransitionType.values, contains(PageTransitionType.rotation));
    });

    test('should have correct index order', () {
      expect(PageTransitionType.slideFromRight.index, 0);
      expect(PageTransitionType.slideFromLeft.index, 1);
      expect(PageTransitionType.slideFromBottom.index, 2);
      expect(PageTransitionType.slideFromTop.index, 3);
      expect(PageTransitionType.fade.index, 4);
      expect(PageTransitionType.scale.index, 5);
      expect(PageTransitionType.rotation.index, 6);
    });
  });

  group('ScanningRadarPainter', () {
    test('should create with required parameters', () {
      final painter = ScanningRadarPainter(
        progress: 0.5,
        color: Colors.blue,
      );
      expect(painter, isNotNull);
      expect(painter.progress, 0.5);
      expect(painter.color, Colors.blue);
    });

    test('should handle progress at 0', () {
      final painter = ScanningRadarPainter(
        progress: 0.0,
        color: Colors.blue,
      );
      expect(painter.progress, 0.0);
    });

    test('should handle progress at 1', () {
      final painter = ScanningRadarPainter(
        progress: 1.0,
        color: Colors.blue,
      );
      expect(painter.progress, 1.0);
    });

    test('should handle different colors', () {
      final redPainter = ScanningRadarPainter(
        progress: 0.5,
        color: Colors.red,
      );
      final greenPainter = ScanningRadarPainter(
        progress: 0.5,
        color: Colors.green,
      );
      expect(redPainter.color, Colors.red);
      expect(greenPainter.color, Colors.green);
    });

    test('shouldRepaint should always return true', () {
      final painter1 = ScanningRadarPainter(
        progress: 0.5,
        color: Colors.blue,
      );
      final painter2 = ScanningRadarPainter(
        progress: 0.6,
        color: Colors.blue,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });
  });

  group('CheckmarkPainter', () {
    test('should create with required parameters', () {
      final painter = CheckmarkPainter(
        progress: 0.5,
        color: Colors.green,
      );
      expect(painter, isNotNull);
      expect(painter.progress, 0.5);
      expect(painter.color, Colors.green);
    });

    test('should handle progress at 0', () {
      final painter = CheckmarkPainter(
        progress: 0.0,
        color: Colors.green,
      );
      expect(painter.progress, 0.0);
    });

    test('should handle progress at 0.5 (first half)', () {
      final painter = CheckmarkPainter(
        progress: 0.5,
        color: Colors.green,
      );
      expect(painter.progress, 0.5);
    });

    test('should handle progress at 1 (complete)', () {
      final painter = CheckmarkPainter(
        progress: 1.0,
        color: Colors.green,
      );
      expect(painter.progress, 1.0);
    });

    test('should handle different colors', () {
      final bluePainter = CheckmarkPainter(
        progress: 0.5,
        color: Colors.blue,
      );
      expect(bluePainter.color, Colors.blue);
    });

    test('shouldRepaint should always return true', () {
      final painter1 = CheckmarkPainter(
        progress: 0.5,
        color: Colors.green,
      );
      final painter2 = CheckmarkPainter(
        progress: 0.6,
        color: Colors.green,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });
  });

  group('ErrorMarkPainter', () {
    test('should create with required parameters', () {
      final painter = ErrorMarkPainter(
        progress: 0.5,
        color: Colors.red,
      );
      expect(painter, isNotNull);
      expect(painter.progress, 0.5);
      expect(painter.color, Colors.red);
    });

    test('should handle progress at 0', () {
      final painter = ErrorMarkPainter(
        progress: 0.0,
        color: Colors.red,
      );
      expect(painter.progress, 0.0);
    });

    test('should handle progress at 0.5 (first line)', () {
      final painter = ErrorMarkPainter(
        progress: 0.5,
        color: Colors.red,
      );
      expect(painter.progress, 0.5);
    });

    test('should handle progress at 1 (both lines)', () {
      final painter = ErrorMarkPainter(
        progress: 1.0,
        color: Colors.red,
      );
      expect(painter.progress, 1.0);
    });

    test('should handle different colors', () {
      final orangePainter = ErrorMarkPainter(
        progress: 0.5,
        color: Colors.orange,
      );
      expect(orangePainter.color, Colors.orange);
    });

    test('shouldRepaint should always return true', () {
      final painter1 = ErrorMarkPainter(
        progress: 0.5,
        color: Colors.red,
      );
      final painter2 = ErrorMarkPainter(
        progress: 0.6,
        color: Colors.red,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });
  });

  group('AnimationService createFadeTransition', () {
    testWidgets('should create fade transition widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createFadeTransition(
                    controller: controller,
                    child: const Text('Test'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should create fade transition with custom parameters', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createFadeTransition(
                    controller: controller,
                    child: const Text('Custom'),
                    begin: 0.5,
                    end: 1.0,
                    curve: Curves.bounceIn,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createSlideTransition', () {
    testWidgets('should create slide transition widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSlideTransition(
                    controller: controller,
                    child: const Text('Slide Test'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.text('Slide Test'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should create slide transition with custom offset', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSlideTransition(
                    controller: controller,
                    child: const Text('Custom Slide'),
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(SlideTransition), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createScaleTransition', () {
    testWidgets('should create scale transition widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createScaleTransition(
                    controller: controller,
                    child: const Text('Scale Test'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(ScaleTransition), findsOneWidget);
      expect(find.text('Scale Test'), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createRotationTransition', () {
    testWidgets('should create rotation transition widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createRotationTransition(
                    controller: controller,
                    child: const Text('Rotation Test'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(RotationTransition), findsOneWidget);
      expect(find.text('Rotation Test'), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createSizeTransition', () {
    testWidgets('should create size transition widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSizeTransition(
                    controller: controller,
                    child: const Text('Size Test'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(SizeTransition), findsOneWidget);
      expect(find.text('Size Test'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should create size transition with horizontal axis', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSizeTransition(
                    controller: controller,
                    child: const Text('Horizontal Size'),
                    axis: Axis.horizontal,
                  );
                },
              );
            },
          ),
        ),
      );

      final sizeTransition = tester.widget<SizeTransition>(find.byType(SizeTransition));
      expect(sizeTransition.axis, Axis.horizontal);

      controller.dispose();
    });
  });

  group('AnimationService createPageTransition', () {
    test('should create page route builder with default type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('Test Page'),
      );

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, AnimationService.defaultDuration);
    });

    test('should create page route builder with fade type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('Fade Page'),
        type: PageTransitionType.fade,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with scale type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('Scale Page'),
        type: PageTransitionType.scale,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with rotation type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('Rotation Page'),
        type: PageTransitionType.rotation,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with slideFromLeft type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('SlideLeft Page'),
        type: PageTransitionType.slideFromLeft,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with slideFromBottom type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('SlideBottom Page'),
        type: PageTransitionType.slideFromBottom,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with slideFromTop type', () {
      final route = AnimationService.createPageTransition(
        page: const Text('SlideTop Page'),
        type: PageTransitionType.slideFromTop,
      );

      expect(route, isA<PageRouteBuilder>());
    });

    test('should create page route builder with custom duration', () {
      final route = AnimationService.createPageTransition(
        page: const Text('Custom Duration Page'),
        duration: AnimationService.slowDuration,
      );

      expect(route.transitionDuration, AnimationService.slowDuration);
    });
  });

  group('AnimationService createScanningRadar', () {
    testWidgets('should create scanning radar widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.scanningDuration,
                  );

                  return AnimationService.createScanningRadar(
                    controller: controller,
                  );
                },
              );
            },
          ),
        ),
      );

      // AnimatedBuilder wraps CustomPaint - just verify it renders without error
      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });

    testWidgets('should create scanning radar with custom size', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.scanningDuration,
                  );

                  return AnimationService.createScanningRadar(
                    controller: controller,
                    size: 150.0,
                    color: Colors.red,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });
  });

  group('AnimationService createPulseAnimation', () {
    testWidgets('should create pulse animation widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createPulseAnimation(
                    controller: controller,
                    child: const Icon(Icons.bluetooth),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(Transform), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should create pulse animation with custom scale', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createPulseAnimation(
                    controller: controller,
                    child: const Icon(Icons.wifi),
                    minScale: 0.8,
                    maxScale: 1.2,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createConnectionStatusAnimation', () {
    testWidgets('should show child when not connected', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createConnectionStatusAnimation(
                    controller: controller,
                    isConnected: false,
                    child: const Text('Not Connected'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Not Connected'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should animate when connected', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createConnectionStatusAnimation(
                    controller: controller,
                    isConnected: true,
                    child: const Text('Connected'),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);

      controller.dispose();
    });
  });

  group('AnimationService createSuccessAnimation', () {
    testWidgets('should create success animation widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSuccessAnimation(
                    controller: controller,
                  );
                },
              );
            },
          ),
        ),
      );

      // AnimatedBuilder wraps CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });

    testWidgets('should create success animation with custom size and color', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createSuccessAnimation(
                    controller: controller,
                    size: 48.0,
                    color: Colors.teal,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });
  });

  group('AnimationService createErrorAnimation', () {
    testWidgets('should create error animation widget', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createErrorAnimation(
                    controller: controller,
                  );
                },
              );
            },
          ),
        ),
      );

      // AnimatedBuilder wraps CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });

    testWidgets('should create error animation with custom size and color', (WidgetTester tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Builder(
                builder: (context) {
                  controller = AnimationController(
                    vsync: tester,
                    duration: AnimationService.defaultDuration,
                  );

                  return AnimationService.createErrorAnimation(
                    controller: controller,
                    size: 48.0,
                    color: Colors.orange,
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });
  });

  group('PageTransition actual navigation tests', () {
    testWidgets('should execute slideFromRight transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Slide Right Page')),
                      type: PageTransitionType.slideFromRight,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Slide Right Page'), findsOneWidget);
    });

    testWidgets('should execute slideFromLeft transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Slide Left Page')),
                      type: PageTransitionType.slideFromLeft,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Slide Left Page'), findsOneWidget);
    });

    testWidgets('should execute slideFromBottom transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Slide Bottom Page')),
                      type: PageTransitionType.slideFromBottom,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Slide Bottom Page'), findsOneWidget);
    });

    testWidgets('should execute slideFromTop transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Slide Top Page')),
                      type: PageTransitionType.slideFromTop,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Slide Top Page'), findsOneWidget);
    });

    testWidgets('should execute fade transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Fade Page')),
                      type: PageTransitionType.fade,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Fade Page'), findsOneWidget);
    });

    testWidgets('should execute scale transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Scale Page')),
                      type: PageTransitionType.scale,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Scale Page'), findsOneWidget);
    });

    testWidgets('should execute rotation transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimationService.createPageTransition(
                      page: const Scaffold(body: Text('Rotation Page')),
                      type: PageTransitionType.rotation,
                    ),
                  );
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Rotation Page'), findsOneWidget);
    });
  });

  group('Painter paint tests', () {
    testWidgets('ScanningRadarPainter should paint without errors', (WidgetTester tester) async {
      final painter = ScanningRadarPainter(
        progress: 0.5,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('test_painter'),
              size: const Size(100, 100),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test_painter')), findsOneWidget);
    });

    testWidgets('CheckmarkPainter should paint first half without errors', (WidgetTester tester) async {
      final painter = CheckmarkPainter(
        progress: 0.3,
        color: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('checkmark_painter'),
              size: const Size(50, 50),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('checkmark_painter')), findsOneWidget);
    });

    testWidgets('CheckmarkPainter should paint second half without errors', (WidgetTester tester) async {
      final painter = CheckmarkPainter(
        progress: 0.8,
        color: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('checkmark_painter_2'),
              size: const Size(50, 50),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('checkmark_painter_2')), findsOneWidget);
    });

    testWidgets('ErrorMarkPainter should paint first line without errors', (WidgetTester tester) async {
      final painter = ErrorMarkPainter(
        progress: 0.3,
        color: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('error_painter'),
              size: const Size(50, 50),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('error_painter')), findsOneWidget);
    });

    testWidgets('ErrorMarkPainter should paint both lines without errors', (WidgetTester tester) async {
      final painter = ErrorMarkPainter(
        progress: 0.8,
        color: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('error_painter_2'),
              size: const Size(50, 50),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('error_painter_2')), findsOneWidget);
    });
  });
}
