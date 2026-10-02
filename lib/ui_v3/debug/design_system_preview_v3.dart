import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/game_badge_v3.dart';
import '../components/game_button_v3.dart';
import '../components/game_icon_medallion_v3.dart';
import '../components/game_tab_v3.dart';
import '../components/game_window_frame_v3.dart';
import '../components/resource_module_v3.dart';
import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_theme_v3.dart';
import '../design/connections_typography_v3.dart';
import 'ui_debug_settings_v3.dart';

class DesignSystemPreviewV3 extends StatelessWidget {
  const DesignSystemPreviewV3({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      key: const ValueKey('design_system_preview_v3'),
      backgroundColor: ConnectionsColorsV3.background,
      appBar: AppBar(
        title: const Text('Design System V3'),
        backgroundColor: ConnectionsColorsV3.paperElevated,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            ConnectionsThemeV3.name,
            style: ConnectionsTypographyV3.gameTitle(size: 22),
          ),
          const SizedBox(height: 16),
          const _DebugControlsPreviewV3(),
          const SizedBox(height: 16),
          _SectionV3(title: 'Botões', child: const _ButtonPreviewV3()),
          _SectionV3(title: 'Paleta', child: const _PaletteGridV3()),
          _SectionV3(title: 'Tipografia', child: const _TypographyPreviewV3()),
          _SectionV3(title: 'Janelas', child: const _WindowPreviewV3()),
          _SectionV3(title: 'Abas', child: const _TabsPreviewV3()),
          _SectionV3(title: 'Recursos', child: const _ResourcesPreviewV3()),
          _SectionV3(
            title: 'Medalhões e badges',
            child: const _BadgesPreviewV3(),
          ),
          _SectionV3(
            title: 'Contornos, raios e sombras',
            child: const _TokensPreviewV3(),
          ),
        ],
      ),
    );
  }
}

class _DebugControlsPreviewV3 extends StatelessWidget {
  const _DebugControlsPreviewV3();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: UiDebugSettingsV3.showUiDebugLabels,
    builder: (context, visible, _) => SwitchListTile(
      key: const ValueKey('ui_debug_labels_switch_v3'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Modo de inspeção'),
      subtitle: const Text(
        'Mostra rótulos técnicos de regiões apenas durante desenvolvimento.',
      ),
      value: visible,
      onChanged: (value) => UiDebugSettingsV3.labelsVisible = value,
    ),
  );
}

class _SectionV3 extends StatelessWidget {
  const _SectionV3({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ConnectionsTypographyV3.windowTitle()),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _PaletteGridV3 extends StatelessWidget {
  const _PaletteGridV3();

  static const colors = [
    ('Fundo', ConnectionsColorsV3.background),
    ('Papel', ConnectionsColorsV3.paper),
    ('Relação', ConnectionsColorsV3.relationship),
    ('Interação', ConnectionsColorsV3.interaction),
    ('Empregos', ConnectionsColorsV3.jobs),
    ('Hobbies', ConnectionsColorsV3.hobbies),
    ('Estatísticas', ConnectionsColorsV3.interaction),
    ('Conquistas', ConnectionsColorsV3.achievements),
    ('Loja', ConnectionsColorsV3.shop),
    ('Extras', ConnectionsColorsV3.extras),
    ('Dinheiro', ConnectionsColorsV3.money),
    ('Cerejas', ConnectionsColorsV3.cherries),
    ('Prestígio', ConnectionsColorsV3.prestige),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final item in colors)
        SizedBox(
          width: 132,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: item.$2,
              border: Border.all(
                color: ConnectionsColorsV3.outline,
                width: ConnectionsShadowsV3.outlineThin,
              ),
              borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
            ),
            child: Center(
              child: Text(
                item.$1,
                style: ConnectionsTypographyV3.badge().copyWith(
                  color: item.$2.computeLuminance() > .55
                      ? ConnectionsColorsV3.ink
                      : ConnectionsColorsV3.onColor,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _TypographyPreviewV3 extends StatelessWidget {
  const _TypographyPreviewV3();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Título do jogo', style: ConnectionsTypographyV3.gameTitle()),
      Text('Título de janela', style: ConnectionsTypographyV3.windowTitle()),
      Text('Botão / aba', style: ConnectionsTypographyV3.button()),
      Text(
        'Valor de recurso 123K',
        style: ConnectionsTypographyV3.resourceValue(),
      ),
      Text(
        'Corpo de texto amigável e legível.',
        style: ConnectionsTypographyV3.body(),
      ),
      Text('Informação secundária', style: ConnectionsTypographyV3.secondary()),
    ],
  );
}

class _WindowPreviewV3 extends StatelessWidget {
  const _WindowPreviewV3();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 340,
    height: 170,
    child: GameWindowFrameV3(
      title: 'Janela',
      icon: Icons.favorite_rounded,
      color: ConnectionsColorsV3.relationship,
      badge: const GameBadgeV3(label: 'Novo', compact: true),
      child: Text(
        'Base visual para vínculo, ações, diálogo, celular e modais.',
        style: ConnectionsTypographyV3.body(),
      ),
    ),
  );
}

class _ButtonPreviewV3 extends StatelessWidget {
  const _ButtonPreviewV3();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      SizedBox(
        width: 150,
        height: 48,
        child: GameButtonV3(onPressed: () {}, child: const Text('Normal')),
      ),
      SizedBox(
        width: 150,
        height: 48,
        child: GameButtonV3(
          onPressed: () {},
          selected: true,
          child: const Text('Selecionado'),
        ),
      ),
      SizedBox(
        width: 150,
        height: 48,
        child: GameButtonV3(onPressed: null, child: const Text('Desabilitado')),
      ),
      SizedBox(
        width: 150,
        height: 48,
        child: GameButtonV3(
          onPressed: () {},
          cooldown: true,
          child: const Text('Cooldown'),
        ),
      ),
    ],
  );
}

class _TabsPreviewV3 extends StatelessWidget {
  const _TabsPreviewV3();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 82,
    child: Row(
      children: [
        Expanded(
          child: GameTabV3(
            icon: Icons.favorite_border_rounded,
            label: 'Paixões',
            color: ConnectionsColorsV3.relationship,
            selected: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GameTabV3(
            icon: Icons.work_outline_rounded,
            label: 'Empregos',
            color: ConnectionsColorsV3.jobs,
            selected: false,
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}

class _ResourcesPreviewV3 extends StatelessWidget {
  const _ResourcesPreviewV3();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: const [
      SizedBox(
        width: 180,
        height: 54,
        child: ResourceModuleV3(
          icon: Icons.monetization_on_rounded,
          label: 'Dinheiro',
          value: 'R\$ 1.250',
          color: ConnectionsColorsV3.money,
        ),
      ),
      SizedBox(
        width: 160,
        height: 54,
        child: ResourceModuleV3(
          icon: Icons.diamond_rounded,
          label: 'Cerejas',
          value: '12',
          color: ConnectionsColorsV3.cherries,
        ),
      ),
    ],
  );
}

class _BadgesPreviewV3 extends StatelessWidget {
  const _BadgesPreviewV3();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 14,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: const [
      GameIconMedallionV3(
        icon: Icons.chat_rounded,
        color: ConnectionsColorsV3.info,
      ),
      GameIconMedallionV3(
        icon: Icons.star_rounded,
        color: ConnectionsColorsV3.shop,
      ),
      GameBadgeV3(label: 'Info'),
      GameBadgeV3(label: 'Novo', kind: GameBadgeKindV3.novelty),
      GameBadgeV3(label: '3', kind: GameBadgeKindV3.quantity),
      GameBadgeV3(label: 'OK', kind: GameBadgeKindV3.complete),
    ],
  );
}

class _TokensPreviewV3 extends StatelessWidget {
  const _TokensPreviewV3();

  @override
  Widget build(BuildContext context) => Text(
    'Contornos: 1.5 / 2.5 / 3.5 px · Raios: 8 / 12 / 18 / 20 / 16 / 999 px · Movimento: 90 / 140 / 200 / 280 / 420 ms',
    style: ConnectionsTypographyV3.body(),
  );
}
