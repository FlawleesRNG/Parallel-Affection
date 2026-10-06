import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/features/activities/hobbies_view.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
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
    child: Scaffold(body: HobbiesView(controller: controller)),
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
    testWidgets(
      'Hobbies definitivos sem overflow em ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = await _controller();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(controller));
        await tester.pump();

        expect(find.text('HOBBIES'), findsOneWidget);
        expect(find.byKey(const ValueKey('hobbies_grid')), findsOneWidget);
        expect(find.text('LEITURA'), findsOneWidget);
        expect(find.text('ACADEMIA'), findsOneWidget);
        expect(
          find.text(
            'Treine habilidades, descubra interesses e desenvolva seu potencial.',
          ),
          findsOneWidget,
        );
        expect(find.text('Ativos'), findsWidgets);
        expect(find.text('Tempo livre'), findsOneWidget);
        expect(find.text('Dominados'), findsWidgets);
        expect(find.text('Nível total'), findsOneWidget);
        expect(find.textContaining('Toque no card para iniciar'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Hobbies definitivos suportam escala de texto aumentada sem overflow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller, textScale: 1.25));
      await tester.pump();

      expect(find.text('HOBBIES'), findsOneWidget);
      expect(find.byKey(const ValueKey('hobbies_grid')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filtros definitivos mostram estados corretos dos Hobbies', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugSetHobbyLevel('academia', 10);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(_hobbyCardCount(), findsNWidgets(10));

    await tester.tap(find.text('Ativos').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('hobby_card_leitura')), findsOneWidget);
    expect(_hobbyCardCount(), findsOneWidget);

    await tester.tap(find.text('Bloqueados').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_hobbyCardCount(), findsNWidgets(5));
    expect(find.byKey(const ValueKey('hobby_card_musica')), findsOneWidget);
    expect(find.textContaining('Leitura — Nível'), findsWidgets);

    await tester.tap(find.text('Dominados').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('hobby_card_academia')), findsOneWidget);
    expect(find.text('HABILIDADE DOMINADA'), findsWidgets);
  });
}

Finder _hobbyCardCount() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('hobby_card_'),
);
