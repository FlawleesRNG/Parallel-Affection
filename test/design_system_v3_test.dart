import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/core/theme/app_theme.dart';
import 'package:projeto_conexoes/ui_v3/components/game_badge_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/game_button_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/game_icon_medallion_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/game_tab_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/game_window_frame_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/resource_module_v3.dart';
import 'package:projeto_conexoes/ui_v3/debug/design_system_preview_v3.dart';
import 'package:projeto_conexoes/ui_v3/debug/ui_debug_settings_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_colors_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_motion_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_radius_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_shadows_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_theme_extension_v3.dart';
import 'package:projeto_conexoes/ui_v3/design/connections_theme_v3.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ConnectionsThemeV3.applyTo(AppTheme.dark()),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('tokens visuais V3 estão disponíveis', () {
    expect(ConnectionsThemeV3.name, 'Conexões — Cozy Arcade Journal');
    expect(ConnectionsColorsV3.background, const Color(0xFFF7EEDC));
    expect(ConnectionsColorsV3.relationship, const Color(0xFFE87572));
    expect(ConnectionsColorsV3.interaction, const Color(0xFF4EA6A0));
    expect(ConnectionsRadiusV3.window, 20);
    expect(ConnectionsRadiusV3.button, 16);
    expect(ConnectionsShadowsV3.outlineThin, 1.5);
    expect(ConnectionsShadowsV3.outline, 2.5);
    expect(ConnectionsShadowsV3.outlineStrong, 3.5);
    expect(ConnectionsMotionV3.veryFast, const Duration(milliseconds: 90));
    expect(ConnectionsMotionV3.normal, const Duration(milliseconds: 200));
  });

  testWidgets('tema V3 aplica ThemeExtension', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    final theme = Theme.of(tester.element(find.byType(SizedBox)));
    final extension = theme.extension<ConnectionsThemeExtensionV3>();
    expect(extension, isNotNull);
    expect(extension!.background, ConnectionsColorsV3.background);
    expect(extension.relationship, ConnectionsColorsV3.relationship);
  });

  testWidgets('GameWindowFrameV3 renderiza título, badge e conteúdo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 320,
          height: 160,
          child: GameWindowFrameV3(
            title: 'Janela',
            icon: Icons.favorite_rounded,
            color: ConnectionsColorsV3.relationship,
            badge: GameBadgeV3(label: 'Novo', compact: true),
            child: Text('Conteúdo'),
          ),
        ),
      ),
    );

    expect(find.text('Janela'), findsOneWidget);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameButtonV3 suporta normal, desabilitado e foco por teclado', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 48,
              child: GameButtonV3(
                onPressed: () => count++,
                semanticLabel: 'Botão normal',
                child: const Text('Normal'),
              ),
            ),
            const SizedBox(
              width: 150,
              height: 48,
              child: GameButtonV3(
                onPressed: null,
                semanticLabel: 'Botão desabilitado',
                child: Text('Desabilitado'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    expect(count, 1);
    await tester.tap(find.text('Desabilitado'));
    await tester.pumpAndSettle();
    expect(count, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(count, greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameTabV3, ResourceModuleV3, Badge e Medallion renderizam', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 70,
              child: GameTabV3(
                icon: Icons.favorite_border_rounded,
                label: 'Ryomi',
                color: ConnectionsColorsV3.relationship,
                selected: true,
                onTap: () {},
              ),
            ),
            const SizedBox(
              width: 180,
              height: 54,
              child: ResourceModuleV3(
                icon: Icons.diamond_rounded,
                label: 'Cerejas',
                value: '12',
                color: ConnectionsColorsV3.cherries,
              ),
            ),
            const Wrap(
              children: [
                GameIconMedallionV3(
                  icon: Icons.star_rounded,
                  color: ConnectionsColorsV3.shop,
                ),
                GameBadgeV3(label: 'OK', kind: GameBadgeKindV3.complete),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Ryomi'), findsOneWidget);
    expect(find.text('Cerejas'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DesignSystemPreviewV3 é acessível em debug', (tester) async {
    UiDebugSettingsV3.labelsVisible = false;
    addTearDown(() => UiDebugSettingsV3.labelsVisible = false);
    await tester.pumpWidget(
      MaterialApp(
        theme: ConnectionsThemeV3.applyTo(AppTheme.dark()),
        home: const DesignSystemPreviewV3(),
      ),
    );

    if (kDebugMode) {
      expect(
        find.byKey(const ValueKey('design_system_preview_v3')),
        findsOneWidget,
      );
      expect(find.text('Design System V3'), findsOneWidget);
      expect(find.text('Paleta'), findsOneWidget);
      expect(UiDebugSettingsV3.labelsVisible, isFalse);
      await tester.tap(find.byKey(const ValueKey('ui_debug_labels_switch_v3')));
      await tester.pumpAndSettle();
      expect(UiDebugSettingsV3.labelsVisible, isTrue);
    } else {
      expect(
        find.byKey(const ValueKey('design_system_preview_v3')),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
