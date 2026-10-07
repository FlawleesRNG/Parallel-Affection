import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/features/activities/jobs_view.dart';
import 'package:projeto_conexoes/services/game_storage.dart';

class _MemoryIdleStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

Future<GameController> _controller() async {
  final controller = GameController(_MemoryIdleStorage());
  await controller.initialize();
  return controller;
}

Widget _app(GameController controller, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: JobsView(controller: controller)),
  ),
);

void main() {
  for (final size in [
    const Size(1024, 768),
    const Size(1152, 648),
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1440, 900),
    const Size(1600, 900),
    const Size(1920, 1080),
    const Size(2560, 1440),
  ]) {
    testWidgets('Empregos sem overflow em ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pump();

      expect(find.text('EMPREGOS'), findsOneWidget);
      expect(find.byKey(const ValueKey('jobs_grid')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
        findsOneWidget,
      );
      expect(find.text('Nv. 1'), findsWidgets);
      expect(
        find.text('Trabalhe, evolua e construa sua independência.'),
        findsNothing,
      );
      expect(find.text('Todos'), findsNothing);
      expect(find.text('Ativos'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Empregos suporta escala de texto aumentada sem overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller, textScale: 1.25));
    await tester.pump();

    expect(find.text('EMPREGOS'), findsOneWidget);
    expect(find.byKey(const ValueKey('jobs_grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
