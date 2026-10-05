import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/game_controller.dart';
import '../../core/theme/game_tokens.dart';
import '../game_shell/auxiliary_views.dart';
import 'home_screen.dart';

/// The top-level navigation surface. Gameplay is deliberately not built until
/// the player explicitly chooses Continue or New Game.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key, required this.controller});
  final GameController controller;
  static const _background =
      'assets/images/ui/parallel_affection_main_menu.jpeg';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _background,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
          _MenuNotebookPanel(controller: controller),
        ],
      ),
    ),
  );

  Future<void> _confirmNewGame(BuildContext context) async {
    if (!controller.hasPersistedSave) {
      await controller.newGame();
      if (context.mounted) _enterGame(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Já existe um progresso salvo.'),
        content: const Text(
          'Iniciar um novo jogo substituirá o progresso atual.\n\nDeseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Novo Jogo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.newGame();
      if (context.mounted) _enterGame(context);
    }
  }

  void _credits(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Créditos'),
      content: const Text('Parallel Affection\n\nDesenvolvimento:\nFlawlees'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  void _enterGame(BuildContext context) => Navigator.pushReplacement(
    context,
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => HomeScreen(controller: controller),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

/// Compatibility name for older test and development entry points.
class TitleScreen extends MainMenuScreen {
  const TitleScreen({super.key, required super.controller});
}

class _MenuNotebookPanel extends StatelessWidget {
  const _MenuNotebookPanel({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Container(
        key: const ValueKey('main_menu_panel'),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: const Color(0xfffff8ec).withValues(alpha: .90),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: GameColors.cuteStroke, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x665A354D), offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parallel\nAffection',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: .9,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'IDLE DATING CLICKER',
              style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                color: GameColors.softInk,
              ),
            ),
            const SizedBox(height: 24),
            _MenuButton(
              key: const ValueKey('main_menu_continue'),
              label: 'Continuar',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onPressed: controller.hasPersistedSave
                  ? () => _enter(context)
                  : null,
            ),
            const SizedBox(height: 10),
            _MenuButton(
              key: const ValueKey('main_menu_new_game'),
              label: 'Novo Jogo',
              icon: Icons.refresh_rounded,
              onPressed: () => _newGame(context),
            ),
            const SizedBox(height: 10),
            _MenuButton(
              key: const ValueKey('main_menu_settings'),
              label: 'Configurações',
              icon: Icons.settings_rounded,
              onPressed: () => showGameSettingsDialog(context, controller),
            ),
            const SizedBox(height: 10),
            _MenuButton(
              key: const ValueKey('main_menu_credits'),
              label: 'Créditos',
              icon: Icons.favorite_rounded,
              onPressed: () => _credits(context),
            ),
            const SizedBox(height: 10),
            _MenuButton(
              key: const ValueKey('main_menu_exit'),
              label: 'Sair',
              icon: Icons.exit_to_app_rounded,
              onPressed: SystemNavigator.pop,
            ),
          ],
        ),
      ),
    ),
  );

  void _enter(BuildContext context) => Navigator.pushReplacement(
    context,
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => HomeScreen(controller: controller),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );

  Future<void> _newGame(BuildContext context) async {
    final menu = MainMenuScreen(controller: controller);
    await menu._confirmNewGame(context);
  }

  void _credits(BuildContext context) =>
      MainMenuScreen(controller: controller)._credits(context);
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fill = !enabled
        ? const Color(0xffd8d0c7)
        : widget.primary
        ? (_hovered ? const Color(0xffcc5f67) : GameColors.coral)
        : (_hovered ? const Color(0xffffead9) : const Color(0xfffffdf7));
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: enabled ? GameColors.cuteStroke : GameColors.locked,
                width: 1.8,
              ),
              boxShadow: enabled && !_pressed
                  ? const [
                      BoxShadow(color: Color(0x555A354D), offset: Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.primary && enabled
                      ? Colors.white
                      : GameColors.ink,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                    color: widget.primary && enabled
                        ? Colors.white
                        : GameColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
