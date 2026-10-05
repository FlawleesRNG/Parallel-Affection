import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/features/game_shell/idle_dating_game_shell.dart';
import 'package:projeto_conexoes/features/home/title_screen.dart';
import 'package:projeto_conexoes/services/game_storage.dart';

class _MemoryStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

Widget _menu(GameController controller) =>
    MaterialApp(home: MainMenuScreen(controller: controller));

void main() {
  test('boot sem save não cria save e mantém Continuar indisponível', () async {
    final storage = _MemoryStorage();
    final controller = GameController(storage);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.hasPersistedSave, isFalse);
    expect(storage.value, isNull);
  });

  testWidgets(
    'menu é uma tela real, mostra branding e não renderiza gameplay',
    (tester) async {
      final controller = GameController(_MemoryStorage());
      addTearDown(controller.dispose);
      await controller.initialize();

      await tester.pumpWidget(_menu(controller));

      expect(find.text('Parallel\nAffection'), findsOneWidget);
      expect(find.byKey(const ValueKey('main_menu_panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('ryomi_ui_v3_shell')), findsNothing);
      expect(find.byKey(const ValueKey('top_hud_v3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main_menu_continue')));
      await tester.pump();
      expect(find.byKey(const ValueKey('ryomi_ui_v3_shell')), findsNothing);
    },
  );

  testWidgets(
    'save existente permanece no menu até Continuar e então entra no shell',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1600, 900);
      addTearDown(tester.view.reset);
      final storage = _MemoryStorage();
      final controller = GameController(storage);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.newGame();
      final saved = storage.value;

      await tester.pumpWidget(_menu(controller));
      expect(find.byType(IdleDatingGameShell), findsNothing);

      await tester.tap(find.byKey(const ValueKey('main_menu_continue')));
      await tester.pumpAndSettle();

      expect(find.byType(IdleDatingGameShell), findsOneWidget);
      expect(storage.value, saved);
    },
  );

  testWidgets('novo jogo com save pede confirmação e Cancelar preserva save', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    final controller = GameController(storage);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.newGame();
    final saved = storage.value;

    await tester.pumpWidget(_menu(controller));
    await tester.tap(find.byKey(const ValueKey('main_menu_new_game')));
    await tester.pumpAndSettle();
    expect(find.text('Já existe um progresso salvo.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(storage.value, saved);
    expect(find.byKey(const ValueKey('main_menu_panel')), findsOneWidget);
  });

  testWidgets('configurações e créditos abrem a partir do menu', (
    tester,
  ) async {
    final controller = GameController(_MemoryStorage());
    addTearDown(controller.dispose);
    await controller.initialize();
    await tester.pumpWidget(_menu(controller));

    await tester.tap(find.byKey(const ValueKey('main_menu_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('main_menu_credits')));
    await tester.pumpAndSettle();
    expect(find.text('Créditos'), findsOneWidget);
    expect(find.textContaining('Flawlees'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
  });
}
