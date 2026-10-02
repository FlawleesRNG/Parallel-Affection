import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/game_controller.dart';
import '../../core/theme/game_tokens.dart';
import '../game_shell/auxiliary_views.dart';
import 'home_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, required this.controller});
  final GameController controller;
  static const _background =
      'assets/images/ui/parallel_affection_main_menu.jpeg';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _background,
          fit: BoxFit.cover,
          alignment: Alignment.centerLeft,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.sizeOf(context).width < 680
                ? double.infinity
                : 430,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xfffff8ec).withValues(alpha: .88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: GameColors.cuteStroke, width: 2),
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
                _button(
                  context,
                  key: 'continue_game',
                  label: 'Continuar',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  onPressed: () => _enterGame(context),
                ),
                const SizedBox(height: 10),
                _button(
                  context,
                  label: 'Novo Jogo',
                  icon: Icons.refresh_rounded,
                  onPressed: () => _confirmNewGame(context),
                ),
                const SizedBox(height: 10),
                _button(
                  context,
                  label: 'Configurações',
                  icon: Icons.settings_rounded,
                  onPressed: () => showGameSettingsDialog(context, controller),
                ),
                const SizedBox(height: 10),
                _button(
                  context,
                  label: 'Créditos',
                  icon: Icons.favorite_rounded,
                  onPressed: () => _credits(context),
                ),
                const SizedBox(height: 10),
                _button(
                  context,
                  label: 'Sair',
                  icon: Icons.exit_to_app_rounded,
                  onPressed: SystemNavigator.pop,
                ),
                const SizedBox(height: 14),
                const Text(
                  'VERSÃO DE TESTE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: GameColors.locked,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    String? key,
    bool primary = false,
  }) => SizedBox(
    height: 48,
    child: primary
        ? FilledButton.icon(
            key: key == null ? null : ValueKey(key),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: GameColors.coral,
              foregroundColor: Colors.white,
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: GameColors.ink,
              backgroundColor: Colors.white.withValues(alpha: .7),
              side: const BorderSide(color: GameColors.cuteStroke),
            ),
          ),
  );

  Future<void> _confirmNewGame(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar novo jogo?'),
        content: const Text('O progresso atual será substituído.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
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
      content: const Text(
        'Parallel Affection\nProjeto Conexões\nVersão de teste',
      ),
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
