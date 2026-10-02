import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/idle_rules.dart';
import '../../core/character_catalog.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../services/admin_auth_service.dart';
import '../../services/root_dev_session_state.dart';
import '../../shared/game_ui.dart';

class AchievementsView extends StatelessWidget {
  const AchievementsView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final scenes =
        controller.state.characters[PlayableCharacterIds.roxanne]!.scenes;
    const achievements = [
      ('primeiro_encontro', 'Primeiro encontro', 'Complete um encontro.'),
      ('vozes_madrugada', 'Memória da madrugada', 'Aproxime-se de Roxanne.'),
      ('cidade_meia_noite', 'Cidade acesa', 'Continue avançando a rota.'),
      ('sem_esconder', 'Coração aberto', 'Chegue perto do final da rota.'),
    ];
    return _SectionPage(
      title: 'Conquistas',
      subtitle: '${scenes.length} de ${achievements.length} memórias reveladas',
      accent: GameColors.violet,
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          itemCount: achievements.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.15,
          ),
          itemBuilder: (context, index) {
            final item = achievements[index];
            final unlocked = scenes.contains(item.$1);
            return GamePanel(
              color: unlocked
                  ? GameColors.lavender.withValues(alpha: .88)
                  : Colors.white.withValues(alpha: .72),
              child: Row(
                children: [
                  Icon(
                    unlocked
                        ? Icons.emoji_events_rounded
                        : Icons.lock_outline_rounded,
                    size: 38,
                    color: unlocked ? GameColors.amber : GameColors.locked,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unlocked ? item.$2 : 'Conquista bloqueada',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: GameColors.softInk,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final ryomi = state.characters[PlayableCharacterIds.roxanne]!;
    final routeProgress = IdleRules.routeProgressPercent(ryomi);
    final stageTitle = IdleRules.stageName(ryomi.stage);
    final affectionTarget = IdleBalance.affectionNeeded(ryomi.stage);
    final activeJobs = state.jobs.values.where((item) => item.active).length;
    final activeHobbies = state.hobbies.values
        .where((item) => item.active)
        .length;
    return _SectionPage(
      title: 'Estatísticas',
      subtitle: 'Números reais registrados pelo estado atual do jogo.',
      accent: GameColors.blue,
      child: ListView(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth >= 560 ? 2.35 : 3.2,
              children: [
                _StatisticCard(
                  icon: Icons.favorite_rounded,
                  title: 'Progresso da Roxanne',
                  value: '$routeProgress%',
                  detail: 'Etapa ${ryomi.stage + 1} de 10 • $stageTitle',
                  color: GameColors.relation,
                ),
                _StatisticCard(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Afeição atual',
                  value: '${ryomi.affection} / $affectionTarget',
                  detail: 'Fonte: relacionamento atual',
                  color: GameColors.coral,
                ),
                _StatisticCard(
                  icon: Icons.savings_rounded,
                  title: 'Dinheiro acumulado',
                  value: '${state.totalMoneyEarned}',
                  detail: 'Total real registrado no save',
                  color: GameColors.money,
                ),
                _StatisticCard(
                  icon: Icons.work_rounded,
                  title: 'Empregos ativos',
                  value: '$activeJobs',
                  detail: 'Atividades profissionais ligadas agora',
                  color: GameColors.jobs,
                ),
                _StatisticCard(
                  icon: Icons.palette_rounded,
                  title: 'Hobbies ativos',
                  value: '$activeHobbies',
                  detail: 'Atividades pessoais ligadas agora',
                  color: GameColors.hobbies,
                ),
                _StatisticCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Prestígios',
                  value: '${state.prestiges}',
                  detail: 'Reinícios permanentes realizados',
                  color: GameColors.prestige,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GamePanel(
            color: Colors.white.withValues(alpha: .72),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: GameColors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tempo total jogado, total de cliques, histórico detalhado '
                    'e recordes serão registrados em uma etapa futura.',
                    style: TextStyle(color: GameColors.softInk, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoreView extends StatelessWidget {
  const StoreView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => _SectionPage(
    title: 'Loja',
    subtitle: 'Compras futuras de presentes, itens e melhorias.',
    accent: GameColors.gold,
    child: ListView(
      children: [
        const _StoreCategoryStrip(),
        const SizedBox(height: 14),
        GamePanel(
          color: GameColors.blush.withValues(alpha: .9),
          child: LayoutBuilder(
            builder: (context, constraints) => Flex(
              direction: constraints.maxWidth >= 620
                  ? Axis.horizontal
                  : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: GameColors.coral,
                  size: 58,
                ),
                const SizedBox(width: 18, height: 12),
                Expanded(
                  flex: constraints.maxWidth >= 620 ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Presentes e itens',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Comprar ficará aqui. Entregar presentes continuará '
                        'sendo uma ação da personagem em Paixões.',
                        style: TextStyle(color: GameColors.softInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18, height: 12),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Compras futuras'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GamePanel(
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: GameColors.amber,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prestígio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recomece com um bônus permanente. Atual: '
                      '+${((controller.state.prestigeBonus - 1) * 100).round()}%',
                      style: const TextStyle(color: GameColors.softInk),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final result = await controller.prestige();
                  if (context.mounted) showGameResult(context, result);
                },
                child: const Text('Prestigiar'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => GamePanel(
    color: Colors.white.withValues(alpha: .78),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(GameRadii.medium),
            border: Border.all(color: color.withValues(alpha: .34)),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameColors.softInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: GameColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: GameColors.softInk, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StoreCategoryStrip extends StatelessWidget {
  const _StoreCategoryStrip();

  @override
  Widget build(BuildContext context) => GamePanel(
    color: Colors.white.withValues(alpha: .72),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StoreCategoryChip(
          icon: Icons.card_giftcard_rounded,
          label: 'Presentes',
          color: GameColors.relation,
        ),
        _StoreCategoryChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Melhorias',
          color: GameColors.shop,
        ),
        _StoreCategoryChip(
          icon: Icons.schedule_rounded,
          label: 'Blocos',
          color: GameColors.timeBlocks,
        ),
        _StoreCategoryChip(
          icon: Icons.style_rounded,
          label: 'Cosméticos futuros',
          color: GameColors.achievements,
        ),
      ],
    ),
  );
}

class _StoreCategoryChip extends StatelessWidget {
  const _StoreCategoryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: color.withValues(alpha: .32), width: 1.4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Color.lerp(color, GameColors.ink, .35),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class MoreView extends StatefulWidget {
  const MoreView({
    super.key,
    required this.controller,
    required this.adminAuth,
    required this.rootDevSession,
    required this.onOpenDev,
  });

  final GameController controller;
  final AdminAuthService adminAuth;
  final RootDevSessionState rootDevSession;
  final VoidCallback onOpenDev;

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  bool _showAdminLogin = false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.adminAuth,
    builder: (context, _) => _SectionPage(
      title: 'Extras',
      subtitle: 'Galeria, dados locais e ferramentas da demonstração.',
      accent: GameColors.rose,
      child: ListView(
        children: [
          _MoreTile(
            icon: Icons.photo_library_outlined,
            title: 'Galeria da Roxanne',
            subtitle:
                '${widget.controller.state.characters[PlayableCharacterIds.roxanne]!.scenes.length} cenas desbloqueadas',
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _GalleryDialog(controller: widget.controller),
            ),
          ),
          const SizedBox(height: 10),
          _MoreTile(
            icon: Icons.settings_outlined,
            title: 'Configurações',
            subtitle: 'Salvamento, privacidade e progresso local',
            onTap: () => showGameSettingsDialog(context, widget.controller),
          ),
          const SizedBox(height: 10),
          widget.adminAuth.accessLevel == AdminAccessLevel.root
              ? _AdminAuthenticatedCard(
                  onOpenDev: widget.onOpenDev,
                  onLogout: () async {
                    await widget.controller.debugSetRootPrivileges(
                      timeInfinite: false,
                      cherriesInfinite: false,
                    );
                    widget.rootDevSession.addLog('ROOT encerrado.');
                    widget.rootDevSession.resetSession();
                    await widget.adminAuth.logout();
                    if (mounted) setState(() => _showAdminLogin = false);
                  },
                )
              : _showAdminLogin
              ? _AdminLoginPanel(
                  auth: widget.adminAuth,
                  onCancel: () => setState(() => _showAdminLogin = false),
                  onAuthenticated: () {
                    widget.rootDevSession.addLog('ROOT autenticado.');
                    setState(() => _showAdminLogin = false);
                  },
                )
              : _AdminAccessCard(
                  onOpen: () => setState(() => _showAdminLogin = true),
                ),
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            GamePanel(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'DEBUG',
                    style: TextStyle(
                      color: GameColors.softInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.controller.debugMoney(1000),
                    child: const Text('+1.000 moedas'),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.controller.debugAdvance(
                      PlayableCharacterIds.roxanne,
                    ),
                    child: const Text('Preparar avanço'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _AdminAccessCard extends StatelessWidget {
  const _AdminAccessCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => GamePanel(
    key: const ValueKey('admin_access_card'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACESSO ADMINISTRATIVO',
          style: TextStyle(
            color: GameColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Entre para acessar ferramentas internas de desenvolvimento e edição do jogo.',
          style: TextStyle(color: GameColors.softInk),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('admin_open_login'),
          onPressed: onOpen,
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: const Text('ENTRAR COMO ADMINISTRADOR'),
        ),
      ],
    ),
  );
}

class _AdminLoginPanel extends StatefulWidget {
  const _AdminLoginPanel({
    required this.auth,
    required this.onCancel,
    required this.onAuthenticated,
  });

  final AdminAuthService auth;
  final VoidCallback onCancel;
  final VoidCallback onAuthenticated;

  @override
  State<_AdminLoginPanel> createState() => _AdminLoginPanelState();
}

class _AdminLoginPanelState extends State<_AdminLoginPanel> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GamePanel(
    key: const ValueKey('admin_login_panel'),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACESSO ADMINISTRATIVO',
            style: TextStyle(
              color: GameColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('admin_username_field'),
            controller: _username,
            enabled: !_submitting,
            autofillHints: null,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Usuário'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('admin_password_field'),
            controller: _password,
            enabled: !_submitting,
            obscureText: _hidePassword,
            autofillHints: null,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Senha',
              suffixIcon: IconButton(
                key: const ValueKey('admin_toggle_password'),
                onPressed: _submitting
                    ? null
                    : () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              key: const ValueKey('admin_login_message'),
              style: const TextStyle(
                color: GameColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('admin_submit_login'),
                onPressed: _submitting ? null : _submit,
                child: const Text('ENTRAR'),
              ),
              OutlinedButton(
                key: const ValueKey('admin_cancel_login'),
                onPressed: _submitting
                    ? null
                    : () {
                        _password.clear();
                        widget.onCancel();
                      },
                child: const Text('CANCELAR'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_submitting) return;
    final username = _username.text;
    final password = _password.text;
    if (username.isEmpty) {
      setState(() => _message = 'Informe o usuário.');
      _password.clear();
      return;
    }
    if (password.isEmpty) {
      setState(() => _message = 'Informe a senha.');
      _password.clear();
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    final result = await widget.auth.authenticate(
      username: username,
      password: password,
    );
    _password.clear();
    if (!mounted) return;
    if (result.success) {
      widget.onAuthenticated();
      return;
    }
    setState(() {
      _submitting = false;
      _message = result.message ?? 'Usuário ou senha incorretos.';
    });
  }
}

class _AdminAuthenticatedCard extends StatelessWidget {
  const _AdminAuthenticatedCard({
    required this.onOpenDev,
    required this.onLogout,
  });

  final VoidCallback onOpenDev;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => GamePanel(
    key: const ValueKey('admin_authenticated_card'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADMINISTRADOR AUTENTICADO',
          style: TextStyle(
            color: GameColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nível de acesso',
          style: TextStyle(color: GameColors.softInk),
        ),
        const Text(
          'ROOT',
          key: ValueKey('admin_root_label'),
          style: TextStyle(
            color: GameColors.danger,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ferramentas internas liberadas.',
          style: TextStyle(color: GameColors.softInk),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('admin_open_dev_panel'),
              onPressed: onOpenDev,
              icon: const Icon(Icons.bug_report_rounded),
              label: const Text('ABRIR PAINEL DEV'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('admin_logout'),
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('SAIR DO MODO ADMIN'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(GameSpacing.md),
    child: Column(
      children: [
        SectionHeading(title: title, subtitle: subtitle, accent: accent),
        const SizedBox(height: 16),
        Expanded(child: child),
      ],
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(GameRadii.medium),
    child: GamePanel(
      child: Row(
        children: [
          Icon(icon, color: GameColors.amber, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: const TextStyle(color: GameColors.softInk),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: GameColors.softInk),
        ],
      ),
    ),
  );
}

Future<void> showGameSettingsDialog(
  BuildContext context,
  GameController controller,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(GameSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Configurações',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SettingLine(
              icon: Icons.cloud_done_outlined,
              title: 'Salvamento automático',
              subtitle: 'O progresso é salvo após cada ação.',
            ),
            const SizedBox(height: 10),
            const _SettingLine(
              icon: Icons.shield_outlined,
              title: 'Dados locais',
              subtitle: 'Nenhuma conta ou conexão externa é usada.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmErase(dialogContext, controller),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Apagar progresso'),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

Future<void> _confirmErase(
  BuildContext context,
  GameController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) => AlertDialog(
      title: const Text('Apagar progresso?'),
      content: const Text(
        'Recursos, atividades e progresso da Roxanne serão removidos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(confirmContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(confirmContext, true),
          child: const Text('Apagar'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.eraseProgress();
    if (context.mounted) Navigator.pop(context);
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: GameColors.success),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              subtitle,
              style: const TextStyle(color: GameColors.softInk, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class _GalleryDialog extends StatelessWidget {
  const _GalleryDialog({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
      child: Padding(
        padding: const EdgeInsets.all(GameSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Galeria da Roxanne',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: Center(
                child: Text(
                  'As cenas desbloqueadas serão apresentadas aqui.\n'
                  'A camada narrativa permanece separada do ciclo idle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameColors.softInk),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
