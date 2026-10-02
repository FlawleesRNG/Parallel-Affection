import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../game_shell/idle_dating_game_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => widget.controller.tick(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOfflineSummary());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _showOfflineSummary() {
    final summary = widget.controller.takeOfflineSummary();
    if (summary == null || !mounted) return;
    final lines = <String>[
      if (summary.affection > 0) 'Roxanne: +${summary.affection} afeição',
      if (summary.money > 0)
        'Empregos: +${NumberFormatter.money(summary.money)}',
      if (summary.totalJobCompletions > 0)
        '${summary.totalJobCompletions} ciclos/pagamentos concluídos',
      if (summary.jobLevels > 0)
        '${summary.jobLevels} nível${summary.jobLevels == 1 ? '' : 's'} alcançado${summary.jobLevels == 1 ? '' : 's'}',
      if (summary.jobsReachedMaximumLevel > 0)
        summary.jobsReachedMaximumLevel == 1
            ? 'DOMÍNIO ALCANÇADO'
            : '${summary.jobsReachedMaximumLevel} novos Domínios alcançados',
      if (summary.hobbyExperience > 0)
        'Hobbies: +${summary.hobbyExperience} XP',
      if (summary.totalHobbyTrainingCompletions > 0)
        '${summary.totalHobbyTrainingCompletions} treino${summary.totalHobbyTrainingCompletions == 1 ? '' : 's'} concluído${summary.totalHobbyTrainingCompletions == 1 ? '' : 's'}',
      if (summary.hobbyLevels > 0)
        '${summary.hobbyLevels} nível${summary.hobbyLevels == 1 ? '' : 's'} de hobby',
      if (summary.hobbiesReachedMaximumLevel > 0)
        summary.hobbiesReachedMaximumLevel == 1
            ? 'HOBBY DOMINADO'
            : '${summary.hobbiesReachedMaximumLevel} Hobbies dominados',
      if (summary.jobUnlocks.isNotEmpty)
        'Novo emprego desbloqueado: ${summary.jobUnlocks.map((id) => IdleBalance.job(id).displayName).join(', ')}',
      if (summary.hobbyUnlocks.isNotEmpty)
        'Novos Hobbies disponíveis: ${summary.hobbyUnlocks.map((id) => IdleBalance.hobby(id).displayName).join(', ')}',
      if (summary.unlocked.isNotEmpty)
        'Desbloqueado: ${summary.unlocked.join(', ')}',
      if (summary.boostsExpired > 0)
        '${summary.boostsExpired} impulso${summary.boostsExpired == 1 ? '' : 's'} expirado${summary.boostsExpired == 1 ? '' : 's'}',
      if (summary.discardedByLimit > Duration.zero)
        'Limite de progresso offline: ${summary.elapsed.inHours}h',
      'Tempo ausente: ${_offlineDurationLabel(summary.actualAwayDuration == Duration.zero ? summary.elapsed : summary.actualAwayDuration)}',
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.nights_stay_rounded,
                  color: GameColors.amber,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enquanto você estava fora',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  lines.join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameColors.softInk,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Voltar ao jogo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      IdleDatingGameShell(controller: widget.controller);
}

String _offlineDurationLabel(Duration duration) {
  if (duration.inHours >= 1) {
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0
        ? '${duration.inHours}h'
        : '${duration.inHours}h ${minutes}min';
  }
  if (duration.inMinutes >= 1) return '${duration.inMinutes} min';
  return '${duration.inSeconds}s';
}
