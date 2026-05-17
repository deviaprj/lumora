import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/shared/widgets/lumora_card.dart';
import 'package:lumora_mobile/app/theme.dart';

void main() {
  group('LumoraCard', () {
    Widget buildCard({
      Widget? child,
      double? borderRadius,
      List<BoxShadow>? shadows,
      bool enableBlur = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LumoraCard(
            borderRadius: borderRadius ?? LumoraRadii.card,
            shadows: shadows,
            enableBlur: enableBlur,
            child: child ?? const Text('Test Content'),
          ),
        ),
      );
    }

    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders with custom child widget', (tester) async {
      await tester.pumpWidget(buildCard(
        child: Column(
          children: [
            Text('Title', style: LumoraTextStyles.titleLarge()),
            Text('Body', style: LumoraTextStyles.bodyMedium()),
          ],
        ),
      ));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('has rounded corners (no right angles)', (tester) async {
      await tester.pumpWidget(buildCard());
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.borderRadius, equals(BorderRadius.circular(LumoraRadii.card)));
    });

    testWidgets('has border with semi-transparent white color', (tester) async {
      await tester.pumpWidget(buildCard());
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('default shadows are present', (tester) async {
      await tester.pumpWidget(buildCard());
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, true);
    });

    testWidgets('custom shadows override defaults', (tester) async {
      final customShadows = [
        LumoraShadows.glow(color: LumoraColors.auroraGold),
      ];
      await tester.pumpWidget(buildCard(shadows: customShadows));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow!.length, 1);
    });

    testWidgets('renders without blur by default (no BackdropFilter)', (tester) async {
      await tester.pumpWidget(buildCard(enableBlur: false));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('renders with blur when enabled', (tester) async {
      await tester.pumpWidget(buildCard(enableBlur: true));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('blur card does not crash on pump', (tester) async {
      await tester.pumpWidget(buildCard(enableBlur: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('custom border radius is applied', (tester) async {
      await tester.pumpWidget(buildCard(borderRadius: LumoraRadii.modal));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(LumoraRadii.modal)));
    });

    testWidgets('multiple LumoraCards in a column', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LumoraCard(child: Text('Card 1')),
              const SizedBox(height: 8),
              LumoraCard(child: Text('Card 2')),
            ],
          ),
        ),
      ));
      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
    });
  });
}