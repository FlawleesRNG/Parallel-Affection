import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/idle_rules.dart';
import '../../core/character_catalog.dart';
import '../../core/job_requirement_evaluator.dart';
import '../../core/number_formatter.dart';
import '../../core/player_skill_service.dart';
import '../../core/relationship_stages.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../data/character_routes.dart';
import '../../models/idle_models.dart';
import '../../services/activity_runtime_service.dart';
import '../../services/admin_auth_service.dart';
import '../../services/root_dev_session_state.dart';
import '../../services/time_reservation_service.dart';
import '../../shared/game_ui.dart';

class DevToolsView extends StatefulWidget {
  const DevToolsView({
    super.key,
    required this.controller,
    required this.adminAuth,
    required this.rootSession,
    required this.onLogout,
    required this.onOpenLayoutEditor,
  });

  final GameController controller;
  final AdminAuthService adminAuth;
  final RootDevSessionState rootSession;
  final VoidCallback onLogout;
  final VoidCallback onOpenLayoutEditor;

  @override
  State<DevToolsView> createState() => _DevToolsViewState();
}

class _DevToolsViewState extends State<DevToolsView> {
  final _moneyController = TextEditingController();
  final _cherriesController = TextEditingController();
  final _timeController = TextEditingController();
  final _affectionController = TextEditingController();
  final _customClicksController = TextEditingController(text: '25');
  final _jobXpController = TextEditingController(text: '12');
  final _jobLevelController = TextEditingController(text: '5');
  final _jobProgressController = TextEditingController(text: '50');
  final _jobBoostController = TextEditingController(text: '60');
  final _hobbyXpController = TextEditingController(text: '10');
  final _hobbyLevelController = TextEditingController(text: '5');
  final _hobbyProgressController = TextEditingController(text: '50');
  final _hobbyBoostController = TextEditingController(text: '60');
  final _giftDeliveryController = TextEditingController(text: '0');
  int _selectedStage = 0;
  String _selectedJobId = 'neighborhood_deliveries';
  String _selectedHobbyId = 'leitura';
  String _selectedCharacterId = PlayableCharacterIds.roxanne;
  String _selectedGiftId = 'coffee';
  String _lastResult = 'ROOT DEV pronto.';
  IdleState? _snapshot;

  @override
  void dispose() {
    _moneyController.dispose();
    _cherriesController.dispose();
    _timeController.dispose();
    _affectionController.dispose();
    _customClicksController.dispose();
    _jobXpController.dispose();
    _jobLevelController.dispose();
    _jobProgressController.dispose();
    _jobBoostController.dispose();
    _hobbyXpController.dispose();
    _hobbyLevelController.dispose();
    _hobbyProgressController.dispose();
    _hobbyBoostController.dispose();
    _giftDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.controller, widget.rootSession]),
    builder: (context, _) {
      if (!_hasRoot) {
        return _RootDenied(onBack: widget.onLogout);
      }
      final state = widget.controller.state;
      final ryomi = state.characters[PlayableCharacterIds.roxanne]!;
      final selectedCharacter =
          state.characters[_selectedCharacterId] ??
          const CharacterProgress(unlocked: true);
      _selectedStage = _selectedStage.clamp(
        0,
        IdleRules.totalRelationshipStages - 1,
      );
      return DecoratedBox(
        key: const ValueKey('dev_tools_view'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [GameColors.ivory, GameColors.sand]),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final sections = [
              _currentStateSection(state, ryomi),
              _resourcesSection(state),
              _infiniteModesSection(),
              _relationshipSection(state, ryomi),
              _objectivesSection(state, ryomi),
              _directClickSection(),
              _passiveAndOfflineSection(ryomi),
              _actionsSection(ryomi),
              _characterRouteInspectionSection(state, selectedCharacter),
              _dialogueSection(),
              _unlocksSection(ryomi),
              _systemsSection(),
              _saveSection(),
              _rootLogSection(),
              _layoutEditorSection(),
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RootHeader(
                  lastResult: _lastResult,
                  onLogout: _logout,
                  authenticatedAtUtc:
                      widget.adminAuth.session?.authenticatedAtUtc,
                ),
                const SizedBox(height: 12),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: sections.indexed
                              .where((item) => item.$1.isEven)
                              .map((item) => item.$2)
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: sections.indexed
                              .where((item) => item.$1.isOdd)
                              .map((item) => item.$2)
                              .toList(),
                        ),
                      ),
                    ],
                  )
                else
                  ...sections,
              ],
            );
          },
        ),
      );
    },
  );

  bool get _hasRoot => widget.adminAuth.accessLevel == AdminAccessLevel.root;

  Widget _layoutEditorSection() => _RootSection(
    title: 'Layout Editor',
    icon: Icons.dashboard_customize_rounded,
    children: [
      const _RootTypeLabel(
        'Layout Global afeta todas as personagens. Ajuste da Personagem altera apenas a arte da personagem atual.',
      ),
      _rootButton('ABRIR EDITOR DE LAYOUT', () => widget.onOpenLayoutEditor()),
    ],
  );

  Future<void> _guard(Future<void> Function() action) async {
    try {
      widget.adminAuth.requireRootAccess();
      await action();
    } on AdminAccessDenied {
      _setResult('ACESSO RECUSADO\nTipo: SESSÃO ROOT\nNenhum valor alterado.');
      widget.onLogout();
    }
  }

  Widget _currentStateSection(IdleState state, CharacterProgress ryomi) {
    final target = IdleBalance.affectionNeeded(ryomi.stage);
    final requirements = _requirements(state, ryomi, target);
    final overflow = ryomi.affection > target ? ryomi.affection - target : 0;
    final modes = [
      if (widget.rootSession.moneyInfinite) 'Dinheiro',
      if (widget.rootSession.cherriesInfinite) 'Cerejas',
      if (widget.rootSession.timeInfinite) 'Tempo',
      if (widget.rootSession.xpInfinite) 'XP',
      if (widget.rootSession.giftsInfinite) 'Presentes',
      if (widget.rootSession.noCooldowns) 'Sem cooldowns',
    ];
    return _RootSection(
      title: 'Estado atual',
      icon: Icons.monitor_heart_rounded,
      initiallyExpanded: true,
      children: [
        _MetricWrap(
          items: [
            ('Personagem', 'Roxanne'),
            (
              'Estágio',
              '${ryomi.stage + 1}/10 — ${IdleRules.stageName(ryomi.stage)}',
            ),
            ('Afeição', '${ryomi.affection} / $target'),
            ('Overflow', '$overflow'),
            ('Progresso global', '${IdleRules.routeProgressPercent(ryomi)}%'),
            (
              'Objetivos OK',
              '${requirements.where((item) => item.complete).length}',
            ),
            (
              'Objetivos pendentes',
              '${requirements.where((item) => !item.complete).length}',
            ),
            (
              'Dinheiro',
              widget.rootSession.moneyInfinite
                  ? '∞'
                  : NumberFormatter.money(state.money),
            ),
            (
              'Cerejas',
              widget.rootSession.cherriesInfinite ? '∞' : '${state.diamonds}',
            ),
            (
              'Tempo',
              widget.rootSession.timeInfinite
                  ? '∞'
                  : '${state.availableBlocks} / ${state.totalBlocks}',
            ),
            ('XP', 'Sistema de XP ainda não implementado nesta versão.'),
            (
              'Passivo',
              ryomi.stage >= IdleBalance.passiveAffectionUnlockStage
                  ? 'ativo'
                  : 'bloqueado',
            ),
            (
              'Intervalo passivo',
              '${IdleBalance.passiveAffectionInterval.inSeconds}s',
            ),
            (
              'Último cálculo UTC',
              DateTime.fromMillisecondsSinceEpoch(
                state.lastSavedAt,
              ).toUtc().toIso8601String(),
            ),
            (
              'Cooldown Conversar',
              _cooldownLabel(ryomi.lastTalkAt, IdleBalance.talkCooldown),
            ),
            (
              'Cooldown Interagir',
              _cooldownLabel(
                ryomi.lastInteractAt,
                IdleBalance.interactCooldown,
              ),
            ),
            (
              'Desbloqueios',
              '${ryomi.scenes.length + state.narrative.unlockedEpisodes.length}',
            ),
            ('Save pendente', widget.controller.savePhase.name),
            ('Modos infinitos', modes.isEmpty ? 'nenhum' : modes.join(', ')),
          ],
        ),
      ],
    );
  }

  Widget _resourcesSection(IdleState state) => _RootSection(
    title: 'Dinheiro, Cerejas e Tempo',
    icon: Icons.savings_rounded,
    children: [
      _RootTextField(controller: _moneyController, label: 'Definir dinheiro'),
      _ButtonWrap([
        _rootButton(
          'Aplicar dinheiro',
          () => _setResources(money: _intFrom(_moneyController)),
        ),
        _rootButton('+100', () => _setResources(money: state.money + 100)),
        _rootButton('+1.000', () => _setResources(money: state.money + 1000)),
        _rootButton('+10.000', () => _setResources(money: state.money + 10000)),
        _rootButton(
          '+100.000',
          () => _setResources(money: state.money + 100000),
        ),
        _rootButton(
          'Zerar dinheiro',
          () => _confirm('Zerar dinheiro?', () => _setResources(money: 0)),
        ),
      ]),
      const Divider(),
      _RootTextField(controller: _cherriesController, label: 'Definir Cerejas'),
      _ButtonWrap([
        _rootButton(
          'Aplicar Cerejas',
          () => _setResources(diamonds: _intFrom(_cherriesController)),
        ),
        _rootButton('+10', () => _setResources(diamonds: state.diamonds + 10)),
        _rootButton(
          '+100',
          () => _setResources(diamonds: state.diamonds + 100),
        ),
        _rootButton(
          '+1.000',
          () => _setResources(diamonds: state.diamonds + 1000),
        ),
        _rootButton(
          'Zerar Cerejas',
          () => _confirm('Zerar Cerejas?', () => _setResources(diamonds: 0)),
        ),
      ]),
      const Divider(),
      _RootTextField(
        controller: _timeController,
        label: 'Definir capacidade de Tempo',
      ),
      _ButtonWrap([
        _rootButton(
          'Aplicar Tempo máximo',
          () => _setResources(totalBlocks: _intFrom(_timeController)),
        ),
        _rootButton(
          'Completar Tempo',
          () => _setResources(
            totalBlocks: state.occupiedBlocks + state.availableBlocks,
          ),
        ),
        _rootButton(
          'Zerar Tempo',
          () => _confirm(
            'Zerar Tempo?',
            () => _setResources(totalBlocks: state.occupiedBlocks),
          ),
        ),
        _rootButton(
          'Restaurar capacidade padrão',
          () => _setResources(totalBlocks: 6),
        ),
      ]),
      const _RootTypeLabel(
        'PERSISTENTE para valores. SESSÃO ROOT para infinitos.',
      ),
    ],
  );

  Widget _infiniteModesSection() => _RootSection(
    title: 'Modos infinitos',
    icon: Icons.all_inclusive_rounded,
    children: [
      _RootSwitch(
        'Dinheiro infinito',
        widget.rootSession.moneyInfinite,
        (value) => _toggle(
          () => widget.rootSession.moneyInfinite = value,
          'Dinheiro infinito ${value ? 'ativado' : 'desativado'}',
        ),
      ),
      _RootSwitch(
        'Cerejas infinitas',
        widget.rootSession.cherriesInfinite,
        (value) => _setCherriesInfinite(value),
      ),
      _RootSwitch(
        'Tempo infinito',
        widget.rootSession.timeInfinite,
        (value) => _setTimeInfinite(value),
      ),
      _RootSwitch(
        'XP infinito',
        widget.rootSession.xpInfinite,
        (value) => _toggle(
          () => widget.rootSession.xpInfinite = value,
          'XP infinito ${value ? 'ativado' : 'desativado'}',
        ),
      ),
      _RootSwitch(
        'Presentes infinitos',
        widget.rootSession.giftsInfinite,
        (value) => _toggle(
          () => widget.rootSession.giftsInfinite = value,
          'Presentes infinitos ${value ? 'ativados' : 'desativados'}',
        ),
      ),
      _RootSwitch(
        'Sem cooldowns',
        widget.rootSession.noCooldowns,
        (value) => _toggle(
          () => widget.rootSession.noCooldowns = value,
          'Sem cooldowns ${value ? 'ativado' : 'desativado'}',
        ),
      ),
      _ButtonWrap([
        _rootButton(
          'ATIVAR TODOS OS MODOS DISPONÍVEIS',
          () => _guard(() async {
            widget.rootSession.toggleAll(true);
            await widget.controller.debugSetRootPrivileges(
              timeInfinite: true,
              cherriesInfinite: true,
            );
            _setResult(
              'MODOS ATIVADOS\nTipo: SESSÃO ROOT\nSave solicitado: não',
            );
          }),
        ),
        _rootButton(
          'DESATIVAR TODOS',
          () => _guard(() async {
            widget.rootSession.toggleAll(false);
            await widget.controller.debugSetRootPrivileges(
              timeInfinite: false,
              cherriesInfinite: false,
            );
            _setResult(
              'MODOS DESATIVADOS\nTipo: SESSÃO ROOT\nSave solicitado: não',
            );
          }),
        ),
      ]),
    ],
  );

  Widget _relationshipSection(IdleState state, CharacterProgress ryomi) {
    final target = IdleBalance.affectionNeeded(ryomi.stage);
    return _RootSection(
      title: 'Relacionamento da Roxanne',
      icon: Icons.favorite_rounded,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _selectedStage,
          decoration: const InputDecoration(labelText: 'Selecionar estágio'),
          items: RelationshipStageCatalog.stages
              .map(
                (stage) => DropdownMenuItem<int>(
                  value: stage.index,
                  child: Text('${stage.index + 1}. ${stage.title}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedStage = value ?? 0),
        ),
        const SizedBox(height: 8),
        _RootTextField(
          controller: _affectionController,
          label: 'Definir afeição',
        ),
        _ButtonWrap([
          _rootButton(
            'Ir para estágio selecionado',
            () => _setRoxanne(stage: _selectedStage, affection: 0),
          ),
          _rootButton(
            'Pular para próxima etapa',
            () =>
                _setRoxanne(stage: (ryomi.stage + 1).clamp(0, 9), affection: 0),
          ),
          _rootButton(
            'Voltar para etapa anterior',
            () => _confirm(
              'Voltar estágio?',
              () => _setRoxanne(
                stage: (ryomi.stage - 1).clamp(0, 9),
                affection: 0,
              ),
            ),
          ),
          _rootButton('Completar requisitos e evoluir', () async {
            await _setRoxanne(
              affection: target,
              gifts: 99,
              encounters: 99,
              totalMoneyEarned: 99999,
            );
            await _run(
              await widget.controller.advanceStage(
                PlayableCharacterIds.roxanne,
              ),
              label: 'EVOLUÇÃO NORMAL',
            );
          }),
          _rootButton(
            'Verificar evolução normalmente',
            () async => _run(
              await widget.controller.advanceStage(
                PlayableCharacterIds.roxanne,
              ),
              label: 'EVOLUÇÃO NORMAL',
            ),
          ),
          _rootButton(
            'Aplicar afeição',
            () => _setRoxanne(affection: _intFrom(_affectionController)),
          ),
          _rootButton('+1', () => _setRoxanne(affection: ryomi.affection + 1)),
          _rootButton('+5', () => _setRoxanne(affection: ryomi.affection + 5)),
          _rootButton(
            '+10',
            () => _setRoxanne(affection: ryomi.affection + 10),
          ),
          _rootButton(
            '+100',
            () => _setRoxanne(affection: ryomi.affection + 100),
          ),
          _rootButton(
            '+1.000',
            () => _setRoxanne(affection: ryomi.affection + 1000),
          ),
          _rootButton('Zerar afeição', () => _setRoxanne(affection: 0)),
          _rootButton(
            'Completar afeição da etapa',
            () => _setRoxanne(affection: target),
          ),
          _rootButton(
            'Completar todos os objetivos',
            () => _setRoxanne(
              affection: target,
              gifts: 99,
              encounters: 99,
              totalMoneyEarned: 99999,
            ),
          ),
          _rootButton(
            'Restaurar objetivos',
            () => _setRoxanne(gifts: 0, encounters: 0, totalMoneyEarned: 0),
          ),
          _rootButton(
            'Recalcular progresso global',
            () => _setResult(
              'PROGRESSO RECALCULADO\nNovo: ${IdleRules.routeProgressPercent(widget.controller.state.characters[PlayableCharacterIds.roxanne]!)}%\nTipo: PERSISTENTE\nSave solicitado: não',
            ),
          ),
        ]),
      ],
    );
  }

  Widget _characterRouteInspectionSection(
    IdleState state,
    CharacterProgress progress,
  ) {
    final definition = PlayableCharacterCatalog.byId(_selectedCharacterId);
    final route = CharacterRouteCatalog.byCharacterId(_selectedCharacterId);
    final stage = route.stageFor(progress.stage);
    return _RootSection(
      title: 'Rotas por personagem',
      icon: Icons.alt_route_rounded,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCharacterId,
          decoration: const InputDecoration(labelText: 'Personagem'),
          items: PlayableCharacterCatalog.all
              .map(
                (character) => DropdownMenuItem(
                  value: character.id,
                  child: Text('${character.visibleName} · ${character.id}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedCharacterId = value ?? PlayableCharacterIds.roxanne;
            final selected =
                widget.controller.state.characters[_selectedCharacterId];
            _selectedStage = selected?.stage ?? 0;
          }),
        ),
        const SizedBox(height: 8),
        _RootTypeLabel(
          'characterId: ${definition.id}\n'
          'routeReady: ${route.routeContentReady}\n'
          'Etapa: ${progress.stage + 1}/10 · ${IdleRules.stageName(progress.stage)}\n'
          'Afeição: ${progress.affection}/${stage.affectionRequired}',
        ),
        for (final requirement in stage.requirements)
          ListTile(
            dense: true,
            title: Text(
              '${requirement.type.name}: ${requirement.sourceLabel ?? requirement.targetId}',
            ),
            trailing: Text(
              requirement.requiredValue == null
                  ? 'pendente no documento'
                  : '${IdleRules.requirementCurrentValue(state, _selectedCharacterId, requirement)} / ${requirement.requiredValue}',
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: _selectedGiftId,
          decoration: const InputDecoration(labelText: 'Contador de presente'),
          items: IdleBalance.gifts
              .map(
                (gift) => DropdownMenuItem(
                  value: gift.id,
                  child: Text(gift.displayName),
                ),
              )
              .toList(),
          onChanged: (value) => setState(
            () => _selectedGiftId = value ?? IdleBalance.gifts.first.id,
          ),
        ),
        const SizedBox(height: 8),
        _RootTextField(
          controller: _giftDeliveryController,
          label: 'Quantidade entregue (administrativo)',
        ),
        _ButtonWrap([
          _rootButton(
            'Aplicar estágio/afeição selecionados',
            () => _guard(() async {
              await _run(
                await widget.controller.debugSetCharacterProgress(
                  _selectedCharacterId,
                  stage: _selectedStage,
                  affection: _intFrom(_affectionController),
                ),
                label: 'ROTA',
              );
            }),
          ),
          _rootButton(
            'Definir contador de presente',
            () => _guard(() async {
              await _run(
                await widget.controller.debugSetGiftDelivery(
                  _selectedCharacterId,
                  _selectedGiftId,
                  _intFrom(_giftDeliveryController),
                ),
                label: 'PRESENTE ADMIN',
              );
            }),
          ),
          _rootButton(
            'Reavaliar rota',
            () => _guard(() async {
              await _run(
                await widget.controller.advanceStage(_selectedCharacterId),
                label: 'REAVALIAÇÃO',
              );
            }),
          ),
        ]),
      ],
    );
  }

  Widget _objectivesSection(IdleState state, CharacterProgress ryomi) {
    final target = IdleBalance.affectionNeeded(ryomi.stage);
    final items = _requirements(state, ryomi, target);
    return _RootSection(
      title: 'Objetivos',
      icon: Icons.flag_rounded,
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            leading: Icon(
              item.complete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.complete ? GameColors.success : GameColors.amber,
            ),
            title: Text(item.label),
            trailing: Text(item.complete ? 'OK' : 'pendente'),
          ),
        _ButtonWrap([
          _rootButton(
            'Completar todos',
            () => _setRoxanne(
              affection: target,
              gifts: 99,
              encounters: 99,
              totalMoneyEarned: 99999,
            ),
          ),
          _rootButton(
            'Restaurar valores padrão',
            () => _setRoxanne(
              affection: 0,
              gifts: 0,
              encounters: 0,
              totalMoneyEarned: 0,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _directClickSection() => _RootSection(
    title: 'Clique direto',
    icon: Icons.touch_app_rounded,
    children: [
      const _RootTypeLabel(
        'Padrão: +1 afeição por clique. Recompensa personalizada é sessão ROOT futura.',
      ),
      _RootTextField(
        controller: _customClicksController,
        label: 'Quantidade personalizada',
      ),
      _ButtonWrap([
        _rootButton('Simular 1 clique', () => _simulateClicks(1)),
        _rootButton('Simular 10 cliques', () => _simulateClicks(10)),
        _rootButton('Simular 100 cliques', () => _simulateClicks(100)),
        _rootButton('Simular 1.000 cliques', () => _simulateClicks(1000)),
        _rootButton(
          'Simular quantidade personalizada',
          () => _simulateClicks(_intFrom(_customClicksController)),
        ),
        _rootButton(
          'Testar somente efeito visual',
          () => _setResult(
            'EFEITO VISUAL SOLICITADO\nTipo: SESSÃO ROOT\nSave solicitado: não\nUse a cena da Roxanne para validar os corações.',
          ),
        ),
      ]),
    ],
  );

  Widget _passiveAndOfflineSection(CharacterProgress ryomi) => _RootSection(
    title: 'Ganho automático e offline',
    icon: Icons.nights_stay_rounded,
    children: [
      _MetricWrap(
        items: [
          (
            'Status',
            ryomi.stage >= IdleBalance.passiveAffectionUnlockStage
                ? 'ativo'
                : 'bloqueado',
          ),
          (
            'Intervalo atual',
            '${IdleBalance.passiveAffectionInterval.inSeconds}s',
          ),
          ('Limite offline', '${IdleBalance.offlineLimit.inHours}h'),
          (
            'Ganho previsto / 10 min',
            ryomi.stage >= IdleBalance.passiveAffectionUnlockStage ? '10' : '0',
          ),
        ],
      ),
      _ButtonWrap([
        _rootButton('Processar agora', () => _runOffline(Duration.zero)),
        _rootButton(
          'Simular 10 segundos',
          () => _runOffline(const Duration(seconds: 10)),
        ),
        _rootButton(
          'Simular 30 segundos',
          () => _runOffline(const Duration(seconds: 30)),
        ),
        _rootButton(
          'Simular 1 minuto',
          () => _runOffline(const Duration(minutes: 1)),
        ),
        _rootButton(
          'Simular 10 minutos',
          () => _runOffline(const Duration(minutes: 10)),
        ),
        _rootButton(
          'Simular 1 hora',
          () => _runOffline(const Duration(hours: 1)),
        ),
        _rootButton(
          'Simular 8 horas',
          () => _runOffline(const Duration(hours: 8)),
        ),
        _rootButton(
          'Simular 12 horas (cap)',
          () => _runOffline(const Duration(hours: 12)),
        ),
        _rootButton(
          'Simular 24 horas',
          () => _runOffline(const Duration(hours: 24)),
        ),
        _rootButton(
          'Restaurar limite de 8 horas',
          () => _setResult(
            'LIMITE RESTAURADO\nTipo: SESSÃO ROOT\nValor: 8 horas\nSave solicitado: não',
          ),
        ),
      ]),
    ],
  );

  Widget _actionsSection(CharacterProgress ryomi) => _RootSection(
    title: 'Conversar e Interagir',
    icon: Icons.forum_rounded,
    children: [
      _MetricWrap(
        items: [
          (
            'Conversar',
            '+${IdleBalance.talkAffectionReward} • ${IdleBalance.talkCooldown.inSeconds}s',
          ),
          (
            'Interagir',
            '+${IdleBalance.interactAffectionReward} • ${IdleBalance.interactCooldown.inSeconds}s',
          ),
          ('Timestamp falar', '${ryomi.lastTalkAt}'),
          ('Timestamp interagir', '${ryomi.lastInteractAt}'),
        ],
      ),
      _ButtonWrap([
        _rootButton(
          'Executar Conversar',
          () async => _run(
            await widget.controller.talk(PlayableCharacterIds.roxanne),
            label: 'CONVERSAR',
          ),
        ),
        _rootButton(
          'Executar Interagir',
          () async => _run(
            await widget.controller.interact(PlayableCharacterIds.roxanne),
            label: 'INTERAGIR',
          ),
        ),
        _rootButton(
          'Liberar Conversar',
          () async => _run(
            await widget.controller.debugResetActionCooldowns(
              PlayableCharacterIds.roxanne,
            ),
            label: 'COOLDOWN',
          ),
        ),
        _rootButton(
          'Liberar todos',
          () async => _run(
            await widget.controller.debugResetActionCooldowns(
              PlayableCharacterIds.roxanne,
            ),
            label: 'COOLDOWNS',
          ),
        ),
        _rootButton(
          'Aplicar cooldowns padrão',
          () => _setResult(
            'COOLDOWNS PADRÃO\nConversar: 5s\nInteragir: 60s\nTipo: SESSÃO ROOT\nSave solicitado: não',
          ),
        ),
        _rootButton(
          'Restaurar recompensas',
          () => _setResult(
            'RECOMPENSAS RESTAURADAS\nConversar: +5\nInteragir: +15\nTipo: SESSÃO ROOT\nSave solicitado: não',
          ),
        ),
      ]),
    ],
  );

  Widget _dialogueSection() => _RootSection(
    title: 'Diálogo',
    icon: Icons.chat_bubble_rounded,
    children: const [
      _RootTypeLabel(
        'A fila real de diálogo vive no controlador da tela da Roxanne. Use Conversar e Interagir no painel ou na cena para gerar falas reais. Controles diretos de fila serão acoplados quando a fila for promovida para serviço global.',
      ),
    ],
  );

  Widget _unlocksSection(CharacterProgress ryomi) => _RootSection(
    title: 'Desbloqueios',
    icon: Icons.lock_open_rounded,
    children: [
      const _RootTypeLabel(
        'Desbloqueios reais atuais: roxanne_relationship_stage_09 e roxanne_relationship_stage_10_final.',
      ),
      _MetricWrap(
        items: [
          (
            'Cenas Roxanne',
            ryomi.scenes.join(', ').isEmpty
                ? 'nenhuma'
                : ryomi.scenes.join(', '),
          ),
          (
            'Episódios',
            widget.controller.state.narrative.unlockedEpisodes
                    .join(', ')
                    .isEmpty
                ? 'nenhum'
                : widget.controller.state.narrative.unlockedEpisodes.join(', '),
          ),
        ],
      ),
    ],
  );

  Widget _systemsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _jobsRootDevSection(),
      const SizedBox(height: 14),
      _hobbiesRootDevSection(),
    ],
  );

  Widget _hobbiesRootDevSection() {
    final state = widget.controller.state;
    final time = TimeReservationService.snapshot(state);
    if (!hobbyIds.contains(_selectedHobbyId)) {
      _selectedHobbyId = 'leitura';
    }
    final hobby = IdleBalance.hobby(_selectedHobbyId);
    final progress = state.hobbies[hobby.id] ?? const ActivityProgress();
    final skill = PlayerSkillService.skillForHobby(hobby.id);
    final skillLevel = PlayerSkillService.getSkillLevel(state, skill.id);
    final skillMastered = PlayerSkillService.isSkillMastered(state, skill.id);
    final maxed = progress.level >= hobby.maximumLevel;
    final xpNeeded = IdleBalance.hobbyXpNeeded(hobby, progress.level);
    final cycleProgress = ActivityRuntimeService.hobbyCycleProgress(
      hobby: hobby,
      progress: progress,
      state: state,
      now: DateTime.now().toUtc(),
    );
    final reserved = time.reservations
        .where(
          (item) =>
              item.ownerType == TimeReservationOwnerType.hobby &&
              item.ownerId == hobby.id,
        )
        .fold<int>(0, (total, item) => total + item.amount);
    final unlockedCount = state.hobbies.values
        .where((item) => item.isUnlocked)
        .length;
    final activeCount = state.hobbies.values
        .where((item) => item.active)
        .length;
    final dominatedCount = state.hobbies.entries.where((entry) {
      final definition = IdleBalance.hobby(entry.key);
      return entry.value.level >= definition.maximumLevel;
    }).length;
    final pausedCount = state.hobbies.values
        .where((item) => item.isUnlocked && !item.active)
        .length;
    final totalLevel = state.hobbies.values.fold<int>(
      0,
      (total, item) =>
          total + item.level.clamp(1, IdleBalance.maximumHobbyLevel),
    );
    final totalCycles = state.hobbies.values.fold<int>(
      0,
      (total, item) => total + item.cycles,
    );
    final activeBoosts = state.hobbies.values
        .where((item) => item.remainingBoostActiveTimeMs > 0)
        .length;
    final masteredSkills = PlayerSkillService.snapshots(
      state,
    ).where((item) => item.isMastered).length;
    final dependencies = IdleBalance.hobbies.where(
      (item) => item.requires.keys.contains('hobby:${hobby.id}'),
    );
    final dependentJobs = IdleBalance.jobs.where(
      (job) => job.requirements.any(
        (requirement) =>
            requirement.type == JobRequirementType.hobbyLevel &&
            requirement.targetId == hobby.id,
      ),
    );
    return _RootSection(
      title: 'HOBBIES — ROOT/DEV completo',
      icon: Icons.auto_awesome_rounded,
      children: [
        const _RootTypeLabel(
          'SIMULAÇÃO APLICARÁ O PROGRESSO AO SAVE ATUAL. Controles usam runtime, Tempo, Skills, requisitos, offline e save reais.',
        ),
        _MetricWrap(
          items: [
            ('Hobbies cadastrados', '${IdleBalance.hobbies.length}'),
            ('Desbloqueados', '$unlockedCount'),
            ('Bloqueados', '${IdleBalance.hobbies.length - unlockedCount}'),
            ('Ativos', '$activeCount'),
            ('Pausados', '$pausedCount'),
            ('Dominados', '$dominatedCount'),
            ('Nível total', '$totalLevel / 100'),
            ('Ciclos totais', '$totalCycles'),
            ('Tempo máximo', '${time.capacity}'),
            ('Tempo reservado global', '${time.reserved}'),
            ('Tempo livre', '${time.available}'),
            ('Impulsos ativos', '$activeBoosts'),
            ('Habilidades dominadas', '$masteredSkills / 10'),
            ('saveVersion', '${IdleSaveSchema.currentVersion}'),
            ('Timestamp offline', _timestampLabel(state.lastSavedAt)),
            (
              'ROOT Tempo',
              widget.rootSession.timeInfinite ? 'infinito ativo' : 'normal',
            ),
            (
              'ROOT Cerejas',
              widget.rootSession.cherriesInfinite
                  ? 'infinitas ativas'
                  : 'normal',
            ),
          ],
        ),
        _ButtonWrap([
          _rootButton(
            'Iniciar todos possíveis',
            () async => _run(
              await widget.controller.debugStartAllHobbies(),
              label: 'HOBBIES GLOBAL',
            ),
          ),
          _rootButton(
            'Pausar todos',
            () async => _run(
              await widget.controller.debugPauseAllHobbies(),
              label: 'HOBBIES GLOBAL',
            ),
          ),
          _rootButton(
            'Processar todos agora',
            () async => _run(
              await widget.controller.debugProcessHobbiesNow(),
              label: 'HOBBIES GLOBAL',
            ),
          ),
          _rootButton('Resetar todos os Hobbies', _confirmResetAllHobbies),
        ]),
        const Divider(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in IdleBalance.hobbies)
              ChoiceChip(
                selected: _selectedHobbyId == item.id,
                onSelected: (_) => setState(() => _selectedHobbyId = item.id),
                avatar: Icon(
                  (state.hobbies[item.id] ?? const ActivityProgress())
                          .isUnlocked
                      ? Icons.auto_awesome_rounded
                      : Icons.lock_rounded,
                  size: 18,
                ),
                label: Text(item.displayName),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          hobby.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          hobby.description,
          style: const TextStyle(color: GameColors.softInk),
        ),
        const SizedBox(height: 10),
        _MetricWrap(
          items: [
            ('ID', hobby.id),
            ('Habilidade associada', skill.displayName),
            ('SkillId', skill.key),
            (
              'Estado',
              maxed
                  ? 'DOMINADO'
                  : progress.active
                  ? 'TREINANDO'
                  : 'PAUSADO',
            ),
            (
              'Desbloqueio',
              IdleRules.hobbyUnlocked(state, hobby.id)
                  ? 'liberado'
                  : 'bloqueado',
            ),
            ('Ativo', progress.active ? 'sim' : 'não'),
            (
              'Pausado',
              !progress.active && !maxed && progress.hasBeenStarted
                  ? 'sim'
                  : 'não',
            ),
            ('Dominado', maxed ? 'sim' : 'não'),
            ('Nível', '${progress.level} / ${hobby.maximumLevel}'),
            ('XP', maxed ? 'Dominado' : '${progress.experience} / $xpNeeded'),
            ('XP por ciclo', '${hobby.xpPerTrainingCycle}'),
            ('Ciclos', '${progress.cycles}'),
            (
              'Progresso do ciclo',
              '${(cycleProgress * 100).clamp(0, 99).round()}%',
            ),
            (
              'Tempo usado',
              '$reserved / ${hobby.timeCostAtLevel(progress.level)}',
            ),
            ('Reserva atual', '$reserved'),
            (
              'Duração atual',
              '${hobby.trainingDurationAtLevel(progress.level).inSeconds}s',
            ),
            (
              'Multiplicador atual',
              progress.remainingBoostActiveTimeMs > 0 ? 'x2' : 'x1',
            ),
            ('completedTrainingCycles', '${progress.cycles}'),
            (
              'activePlayTime',
              _durationLabel(Duration(milliseconds: progress.activePlayTimeMs)),
            ),
            ('firstStartedAtUtc', _timestampLabel(progress.firstStartedAtUtc)),
            ('hasBeenStarted', progress.hasBeenStarted ? 'sim' : 'não'),
            (
              'activationOrder',
              '${IdleBalance.hobbies.indexWhere((item) => item.id == hobby.id) + 1}',
            ),
            ('Local futuro', hobby.futureLocationId),
            (
              'Boost',
              progress.remainingBoostActiveTimeMs > 0
                  ? '${(progress.remainingBoostActiveTimeMs / 1000).round()}s'
                  : 'sem impulso',
            ),
            (
              'Dependentes Hobby',
              dependencies.isEmpty
                  ? 'nenhum'
                  : dependencies.map((item) => item.displayName).join(', '),
            ),
            (
              'Jobs dependentes',
              dependentJobs.isEmpty
                  ? 'nenhum'
                  : dependentJobs.map((item) => item.displayName).join(', '),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricWrap(
          items: [
            ('HABILIDADE DERIVADA', skill.displayName),
            ('Hobby', '${hobby.displayName} — nível ${progress.level}'),
            ('Skill', '${skill.displayName} — nível $skillLevel'),
            ('Dominada', skillMastered ? 'sim' : 'não'),
            ('Editável diretamente', 'não'),
          ],
        ),
        const SizedBox(height: 10),
        _RootProgressBar(
          label: maxed ? 'Hobby dominado' : 'XP do nível',
          value: maxed || xpNeeded <= 0
              ? 1
              : (progress.experience / xpNeeded).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 8),
        _RootProgressBar(label: 'Ciclo de treino', value: cycleProgress),
        const SizedBox(height: 10),
        _ButtonWrap([
          _rootButton(
            'Desbloquear',
            () async => _run(
              await widget.controller.debugUnlockHobby(hobby.id),
              label: 'HOBBY DESBLOQUEIO',
            ),
          ),
          _rootButton(
            'Bloquear',
            () => _confirm(
              'Bloquear ${hobby.displayName}?',
              () async => _run(
                await widget.controller.debugLockHobby(hobby.id),
                label: 'HOBBY DESBLOQUEIO',
              ),
            ),
          ),
          _rootButton(
            progress.active ? 'Pausar' : 'Iniciar/retomar',
            () async => _run(
              progress.active
                  ? await widget.controller.debugPauseHobby(hobby.id)
                  : await widget.controller.debugStartHobby(hobby.id),
              label: 'HOBBY ESTADO',
            ),
          ),
          _rootButton(
            'Completar 1 ciclo',
            () async => _run(
              await widget.controller.debugCompleteHobbyCycle(hobby.id),
              label: 'HOBBY CICLO',
            ),
          ),
          _rootButton(
            'Completar nível',
            () async => _run(
              await widget.controller.debugCompleteHobbyLevel(hobby.id),
              label: 'HOBBY XP',
            ),
          ),
          _rootButton(
            'Zerar XP',
            () async => _run(
              await widget.controller.debugZeroHobbyXp(hobby.id),
              label: 'HOBBY XP',
            ),
          ),
          _rootButton(
            'Processar 1s',
            () async => _run(
              await widget.controller.debugProcessHobbyTime(
                hobby.id,
                const Duration(seconds: 1),
              ),
              label: 'HOBBY SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 10s',
            () async => _run(
              await widget.controller.debugProcessHobbyTime(
                hobby.id,
                const Duration(seconds: 10),
              ),
              label: 'HOBBY SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 10min',
            () async => _run(
              await widget.controller.debugProcessHobbyTime(
                hobby.id,
                const Duration(minutes: 10),
              ),
              label: 'HOBBY SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 1h',
            () async => _run(
              await widget.controller.debugProcessHobbyTime(
                hobby.id,
                const Duration(hours: 1),
              ),
              label: 'HOBBY SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 1min',
            () async => _run(
              await widget.controller.debugProcessHobbyTime(
                hobby.id,
                const Duration(minutes: 1),
              ),
              label: 'HOBBY SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Boost grátis',
            () async => _run(
              await widget.controller.debugActivateHobbyBoost(hobby.id),
              label: 'HOBBY BOOST',
            ),
          ),
          _rootButton(
            'Remover boost',
            () async => _run(
              await widget.controller.debugRemoveHobbyBoost(hobby.id),
              label: 'HOBBY BOOST',
            ),
          ),
          _rootButton(
            'Expirar boost',
            () async => _run(
              await widget.controller.debugExpireHobbyBoost(hobby.id),
              label: 'HOBBY BOOST',
            ),
          ),
          _rootButton(
            'Processar até expirar',
            () async => _run(
              await widget.controller.debugProcessHobbyUntilBoostExpires(
                hobby.id,
              ),
              label: 'HOBBY BOOST',
            ),
          ),
          _rootButton(
            'Reset individual',
            () => _confirm(
              'Resetar ${hobby.displayName}?',
              () async => _run(
                await widget.controller.debugResetHobby(hobby.id),
                label: 'HOBBY RESET',
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _ButtonWrap([
          for (final percent in [0, 25, 50, 75, 90])
            _rootButton(
              'Ciclo $percent%',
              () async => _run(
                await widget.controller.debugSetHobbyCycleFraction(
                  hobby.id,
                  percent / 100,
                ),
                label: 'HOBBY CICLO',
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 150,
              child: _RootTextField(
                controller: _hobbyXpController,
                label: 'XP a adicionar',
              ),
            ),
            _rootButton(
              'Aplicar XP',
              () async => _run(
                await widget.controller.debugAddHobbyXp(
                  hobby.id,
                  _intFrom(_hobbyXpController),
                ),
                label: 'HOBBY XP',
              ),
            ),
            SizedBox(
              width: 150,
              child: _RootTextField(
                controller: _hobbyLevelController,
                label: 'Nível 1-10',
              ),
            ),
            _rootButton(
              'Definir nível',
              () async => _run(
                await widget.controller.debugSetHobbyLevel(
                  hobby.id,
                  _intFrom(_hobbyLevelController),
                ),
                label: 'HOBBY NÍVEL',
              ),
            ),
            SizedBox(
              width: 150,
              child: _RootTextField(
                controller: _hobbyProgressController,
                label: 'Ciclo %',
              ),
            ),
            _rootButton(
              'Definir ciclo',
              () async => _run(
                await widget.controller.debugSetHobbyCycleFraction(
                  hobby.id,
                  _intFrom(_hobbyProgressController) / 100,
                ),
                label: 'HOBBY CICLO',
              ),
            ),
            SizedBox(
              width: 180,
              child: _RootTextField(
                controller: _hobbyBoostController,
                label: 'Impulso restante s',
              ),
            ),
            _rootButton(
              'Definir impulso',
              () async => _run(
                await widget.controller.debugSetHobbyBoostRemaining(
                  hobby.id,
                  Duration(seconds: _intFrom(_hobbyBoostController)),
                ),
                label: 'HOBBY BOOST',
              ),
            ),
            for (final option in [
              const Duration(seconds: 10),
              const Duration(seconds: 30),
              const Duration(minutes: 1),
              const Duration(minutes: 5),
              const Duration(minutes: 10),
            ])
              _rootButton(
                'Boost ${option.inMinutes > 0 ? '${option.inMinutes}min' : '${option.inSeconds}s'}',
                () async => _run(
                  await widget.controller.debugSetHobbyBoostRemaining(
                    hobby.id,
                    option,
                  ),
                  label: 'HOBBY BOOST',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _jobsRootDevSection() {
    final state = widget.controller.state;
    final time = TimeReservationService.snapshot(state);
    if (!jobIds.contains(_selectedJobId)) {
      _selectedJobId = 'neighborhood_deliveries';
    }
    final selectedJob = IdleBalance.job(_selectedJobId);
    final progress = state.jobs[selectedJob.id] ?? const ActivityProgress();
    return _RootSection(
      title: 'Empregos — ROOT/DEV completo',
      icon: Icons.inventory_2_rounded,
      initiallyExpanded: true,
      children: [
        const _RootTypeLabel(
          'SIMULAÇÃO APLICARÁ O PROGRESSO AO SAVE ATUAL. A DEV usa controller, runtime, avaliador de requisitos, Tempo e save reais.',
        ),
        _jobsGlobalSummary(state, time),
        const Divider(),
        _jobSelector(state),
        const Divider(),
        _jobInspector(selectedJob, progress, state, time),
        const Divider(),
        _jobControls(selectedJob),
        const Divider(),
        _jobRequirementTools(selectedJob, state),
        const Divider(),
        _timeDiagnostics(state, time),
        const Divider(),
        _saveDiagnostics(state),
      ],
    );
  }

  Widget _jobsGlobalSummary(IdleState state, TimeBudgetSnapshot time) {
    final unlocked = state.jobs.values.where((item) => item.isUnlocked).length;
    final active = state.jobs.values.where((item) => item.active).length;
    final maximum = state.jobs.entries.where((entry) {
      final job = IdleBalance.job(entry.key);
      return entry.value.level >= job.maximumLevel;
    }).length;
    final boostCount = state.jobs.values
        .where((item) => item.remainingBoostActiveTimeMs > 0)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(
          items: [
            ('Empregos', '${IdleBalance.jobs.length} cadastrados'),
            ('Desbloqueados', '$unlocked / ${IdleBalance.jobs.length}'),
            ('Ativos', '$active simultâneo(s)'),
            ('Domínio máximo', '$maximum'),
            ('Impulsos ativos', '$boostCount'),
            ('Tempo', '${time.available} livre / ${time.capacity} total'),
            ('Tempo reservado', '${time.reserved}'),
            (
              'ROOT Tempo',
              widget.rootSession.timeInfinite ? 'infinito ativo' : 'normal',
            ),
            (
              'ROOT Cerejas',
              widget.rootSession.cherriesInfinite ? 'infinita ativa' : 'normal',
            ),
          ],
        ),
        _ButtonWrap([
          _rootButton(
            'Processar agora',
            () async => _run(
              await widget.controller.debugProcessJobsNow(),
              label: 'EMPREGOS SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Reavaliar desbloqueios',
            () async => _run(
              await widget.controller.debugReevaluateJobUnlocks(),
              label: 'EMPREGOS REQUISITOS',
            ),
          ),
          _rootButton(
            'Reconciliar Tempo',
            () async => _run(
              await widget.controller.debugReconcileTime(),
              label: 'EMPREGOS TEMPO',
            ),
          ),
          _rootButton(
            'Resetar todos os empregos',
            () => _confirm(
              'Resetar todos os empregos?',
              () async => _run(
                await widget.controller.debugResetAllJobs(),
                label: 'EMPREGOS RESET',
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _jobSelector(IdleState state) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final job in IdleBalance.jobs)
        ChoiceChip(
          selected: _selectedJobId == job.id,
          onSelected: (_) => setState(() => _selectedJobId = job.id),
          avatar: Icon(
            (state.jobs[job.id] ?? const ActivityProgress()).isUnlocked
                ? Icons.work_rounded
                : Icons.lock_rounded,
            size: 18,
          ),
          label: Text(job.displayName),
        ),
    ],
  );

  Widget _jobInspector(
    JobDefinition job,
    ActivityProgress progress,
    IdleState state,
    TimeBudgetSnapshot time,
  ) {
    final now = DateTime.now().toUtc();
    final xpNeeded = IdleBalance.jobXpNeeded(job, progress.level);
    final maxed = progress.level >= job.maximumLevel;
    final cycleMs = ActivityRuntimeService.effectiveJobCycleMillis(
      job: job,
      level: progress.level,
      state: state,
    );
    final progressMs = progress.accumulatedCycleProgressMs.clamp(
      0,
      cycleMs <= 0 ? 0 : cycleMs - 1,
    );
    final cyclePercent = cycleMs <= 0 ? 0.0 : progressMs / cycleMs;
    final xpPercent = maxed || xpNeeded <= 0
        ? 1.0
        : (progress.experience / xpNeeded).clamp(0.0, 1.0);
    final nextPayment = ActivityRuntimeService.timeUntilNextJobCycle(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final boostRemaining = ActivityRuntimeService.remainingJobBoostTime(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final evaluation = JobRequirementEvaluator.evaluate(state, job);
    final reserved = time.reservations
        .where((item) => item.ownerId == job.id)
        .fold<int>(0, (total, item) => total + item.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          job.description,
          style: const TextStyle(color: GameColors.softInk),
        ),
        const SizedBox(height: 10),
        _MetricWrap(
          items: [
            ('ID', job.id),
            ('Estado', progress.active ? 'ativo' : 'pausado'),
            ('Desbloqueio', evaluation.isUnlocked ? 'liberado' : 'bloqueado'),
            ('Nível', '${progress.level} / ${job.maximumLevel}'),
            ('Cargo', job.rankAtLevel(progress.level)),
            (
              'XP',
              maxed ? 'Domínio Máximo' : '${progress.experience} / $xpNeeded',
            ),
            ('Ciclos', '${progress.cycles}'),
            (
              'Tempo usado',
              '$reserved / ${job.timeCostAtLevel(progress.level)}',
            ),
            (
              'Próximo pagamento',
              progress.active ? _durationLabel(nextPayment) : 'pausado',
            ),
            (
              'Renda por ciclo',
              NumberFormatter.money(
                ActivityRuntimeService.jobIncomePerCycle(
                  job: job,
                  progress: progress,
                  state: state,
                ).round(),
              ),
            ),
            (
              'Produção contínua',
              maxed
                  ? '1 pagamento/s em x1.0'
                  : 'após nível ${job.maximumLevel}',
            ),
            (
              'Impulso x2',
              boostRemaining > Duration.zero
                  ? _durationLabel(boostRemaining)
                  : 'inativo',
            ),
            (
              'Total ganho',
              NumberFormatter.money(progress.lifetimeMoneyEarned),
            ),
            ('Último ciclo', _timestampLabel(progress.lastProcessedAtUtc)),
          ],
        ),
        const SizedBox(height: 10),
        _RootProgressBar(
          label: maxed ? 'XP visual vivo — Domínio Máximo' : 'XP do nível',
          value: xpPercent,
        ),
        const SizedBox(height: 8),
        _RootProgressBar(label: 'Ciclo de produção', value: cyclePercent),
      ],
    );
  }

  Widget _jobControls(JobDefinition job) {
    final progress =
        widget.controller.state.jobs[job.id] ?? const ActivityProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RootTypeLabel('Controles persistentes do emprego selecionado.'),
        _ButtonWrap([
          _rootButton(
            progress.active ? 'Pausar emprego' : 'Iniciar emprego',
            () async => _run(
              progress.active
                  ? await widget.controller.debugPauseJob(job.id)
                  : await widget.controller.debugStartJob(job.id),
              label: 'EMPREGO ESTADO',
            ),
          ),
          _rootButton(
            'Desbloquear',
            () async => _run(
              await widget.controller.debugUnlockJob(job.id),
              label: 'EMPREGO DESBLOQUEIO',
            ),
          ),
          _rootButton(
            'Bloquear',
            () async => _run(
              await widget.controller.debugLockJob(job.id),
              label: 'EMPREGO DESBLOQUEIO',
            ),
          ),
          _rootButton(
            'Completar 1 ciclo',
            () async => _run(
              await widget.controller.debugCompleteJobCycle(job.id),
              label: 'EMPREGO CICLO',
            ),
          ),
          _rootButton(
            'Processar 1s',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(seconds: 1),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 10s',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(seconds: 10),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 60s',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(minutes: 1),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 10min',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(minutes: 10),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 1h',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(hours: 1),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Processar 8h',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(hours: 8),
              ),
              label: 'EMPREGO SIMULAÇÃO',
            ),
          ),
          _rootButton(
            'Completar nível atual',
            () async => _run(
              await widget.controller.debugCompleteJobLevel(job.id),
              label: 'EMPREGO XP',
            ),
          ),
          _rootButton(
            'Zerar XP',
            () async => _run(
              await widget.controller.debugZeroJobXp(job.id),
              label: 'EMPREGO XP',
            ),
          ),
          _rootButton(
            'Resetar emprego',
            () => _confirm(
              'Resetar ${job.displayName}?',
              () async => _run(
                await widget.controller.debugResetJob(job.id),
                label: 'EMPREGO RESET',
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _ButtonWrap([
          for (final percent in [0, 25, 50, 75, 90])
            _rootButton(
              'Ciclo $percent%',
              () async => _run(
                await widget.controller.debugSetJobCycleFraction(
                  job.id,
                  percent / 100,
                ),
                label: 'EMPREGO CICLO',
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 150,
              child: _RootTextField(
                controller: _jobXpController,
                label: 'XP a adicionar',
              ),
            ),
            _rootButton(
              'Aplicar XP',
              () async => _run(
                await widget.controller.debugAddJobXp(
                  job.id,
                  _intFrom(_jobXpController),
                ),
                label: 'EMPREGO XP',
              ),
            ),
            SizedBox(
              width: 150,
              child: _RootTextField(
                controller: _jobLevelController,
                label: 'Nível 1-10',
              ),
            ),
            _rootButton(
              'Definir nível',
              () async => _run(
                await widget.controller.debugSetJobLevel(
                  job.id,
                  _intFrom(_jobLevelController),
                ),
                label: 'EMPREGO NÍVEL',
              ),
            ),
            SizedBox(
              width: 170,
              child: _RootTextField(
                controller: _jobProgressController,
                label: 'Ciclo %',
              ),
            ),
            _rootButton(
              'Definir ciclo',
              () async => _run(
                await widget.controller.debugSetJobCycleFraction(
                  job.id,
                  _intFrom(_jobProgressController) / 100,
                ),
                label: 'EMPREGO CICLO',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _rootButton(
              'Comprar impulso real',
              () async => _run(
                await widget.controller.purchaseJobBoost(job.id),
                label: 'EMPREGO IMPULSO',
              ),
            ),
            _rootButton(
              'Ativar impulso grátis',
              () async => _run(
                await widget.controller.debugActivateJobBoost(job.id),
                label: 'EMPREGO IMPULSO',
              ),
            ),
            _rootButton(
              'Remover impulso',
              () async => _run(
                await widget.controller.debugRemoveJobBoost(job.id),
                label: 'EMPREGO IMPULSO',
              ),
            ),
            SizedBox(
              width: 180,
              child: _RootTextField(
                controller: _jobBoostController,
                label: 'Impulso restante s',
              ),
            ),
            _rootButton(
              'Definir impulso',
              () async => _run(
                await widget.controller.debugSetJobBoostRemaining(
                  job.id,
                  Duration(seconds: _intFrom(_jobBoostController)),
                ),
                label: 'EMPREGO IMPULSO',
              ),
            ),
            _rootButton(
              'Expirar impulso',
              () async => _run(
                await widget.controller.debugExpireJobBoost(job.id),
                label: 'EMPREGO IMPULSO',
              ),
            ),
            _rootButton(
              'Processar até expirar',
              () async => _run(
                await widget.controller.debugProcessJobUntilBoostExpires(
                  job.id,
                ),
                label: 'EMPREGO IMPULSO',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _jobRequirementTools(JobDefinition job, IdleState state) {
    final evaluation = JobRequirementEvaluator.evaluate(state, job);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RootTypeLabel('Requisitos oficiais do catálogo.'),
        if (evaluation.requirements.isEmpty)
          const Text('Disponível desde o início.')
        else
          for (final requirement in evaluation.requirements)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                requirement.isMet
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: requirement.isMet
                    ? GameColors.success
                    : GameColors.coral,
              ),
              title: Text(requirement.displayLabel),
              subtitle: Text(
                requirement.safeMessage ?? requirement.progressLabel,
              ),
              trailing: Text(
                requirement.consumesResource ? 'consome' : 'não consome',
                style: const TextStyle(fontSize: 11),
              ),
            ),
        _ButtonWrap([
          for (final requirement in evaluation.requirements.where(
            (item) => item.type == JobRequirementType.jobLevel,
          ))
            _rootButton(
              'Definir ${IdleBalance.job(requirement.targetId).displayName} no mínimo',
              () async => _run(
                await widget.controller.debugSetJobLevel(
                  requirement.targetId,
                  requirement.requiredValue,
                ),
                label: 'REQUISITO EMPREGO',
              ),
            ),
          _rootButton(
            'Reavaliar todos',
            () async => _run(
              await widget.controller.debugReevaluateJobUnlocks(),
              label: 'REQUISITOS',
            ),
          ),
        ]),
      ],
    );
  }

  Widget _timeDiagnostics(IdleState state, TimeBudgetSnapshot time) {
    final reservations = time.reservations;
    final issues = <String>[
      for (final hobby in IdleBalance.hobbies)
        if ((state.hobbies[hobby.id] ?? const ActivityProgress()).level >=
                hobby.maximumLevel &&
            TimeReservationService.reservedByHobby(state, hobby.id) > 0)
          '${hobby.displayName}: dominado com reserva',
      for (final hobby in IdleBalance.hobbies)
        if ((state.hobbies[hobby.id] ?? const ActivityProgress()).active &&
            hobby.timeCostAtLevel(
                  (state.hobbies[hobby.id] ?? const ActivityProgress()).level,
                ) >
                0 &&
            TimeReservationService.reservedByHobby(state, hobby.id) <= 0)
          '${hobby.displayName}: ativo sem reserva',
      if (!widget.rootSession.timeInfinite && time.reserved > time.capacity)
        'Total reservado acima da capacidade sem ROOT',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RootTypeLabel(
          'Diagnóstico do Tempo real reservado por Empregos e Hobbies.',
        ),
        _MetricWrap(
          items: [
            ('Capacidade', '${time.capacity}'),
            ('Reservado', '${time.reserved}'),
            ('Livre', '${time.available}'),
            (
              'Reservas Job',
              '${reservations.where((item) => item.ownerType == TimeReservationOwnerType.job).length}',
            ),
            (
              'Reservas Hobby',
              '${reservations.where((item) => item.ownerType == TimeReservationOwnerType.hobby).length}',
            ),
            (
              'ROOT Tempo infinito',
              widget.rootSession.timeInfinite ? 'ON' : 'OFF',
            ),
            (
              'Reservas inválidas',
              issues.isEmpty ? 'nenhuma' : issues.join('; '),
            ),
          ],
        ),
        if (reservations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Nenhuma atividade reservando Tempo.'),
          )
        else
          for (final reservation in reservations)
            Text(
              '${_reservationLabel(reservation)}: '
              '${reservation.amount} Tempo • prioridade ${reservation.priorityOrder + 1}',
            ),
        _ButtonWrap([
          _rootButton(
            'RECONCILIAR TEMPO',
            () async => _run(
              await widget.controller.debugReconcileTime(),
              label: 'TEMPO',
            ),
          ),
        ]),
      ],
    );
  }

  Widget _saveDiagnostics(IdleState state) {
    final migration = widget.controller.lastMigrationReport;
    final recentJobFeedbacks = widget.controller.jobFeedbacks.values.toList()
      ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    final recentHobbyFeedbacks =
        widget.controller.hobbyFeedbacks.values.toList()
          ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RootTypeLabel(
          'Save, offline e últimas ações de Empregos/Hobbies.',
        ),
        _MetricWrap(
          items: [
            ('Schema save', '${IdleSaveSchema.currentVersion}'),
            (
              'Migração',
              migration == null
                  ? 'sem relatório'
                  : '${migration.fromVersion} → ${migration.toVersion}',
            ),
            ('Backup usado', migration?.backupUsed == true ? 'sim' : 'não'),
            ('Campos saneados', '${migration?.sanitizedFields ?? 0}'),
            (
              'Hobbies recuperados',
              '${migration?.recoveredHobbies.length ?? 0}',
            ),
            (
              'Hobbies ausentes',
              '${migration?.missingHobbiesCreated.length ?? 0}',
            ),
            (
              'Hobbies ignorados',
              '${migration?.ignoredUnknownHobbies.length ?? 0}',
            ),
            ('Último save', _timestampLabel(state.lastSavedAt)),
            ('Último save solicitado', widget.controller.savePhase.name),
            ('Último save concluído', _timestampLabel(state.lastSavedAt)),
            ('Dinheiro atual', NumberFormatter.money(state.money)),
            ('Total ganho', NumberFormatter.money(state.totalMoneyEarned)),
            (
              'Hobbies carregados',
              '${state.hobbies.length} / ${IdleBalance.hobbies.length}',
            ),
            ('Aliases migrados', '${migration?.aliasesConverted.length ?? 0}'),
            (
              'Offline sem timestamp',
              migration?.hobbyOfflineSkippedDueToMissingTimestamp == true
                  ? 'sim'
                  : 'não',
            ),
            (
              'Avisos de Tempo',
              '${widget.controller.jobTimeWarnings.length + widget.controller.hobbyTimeWarnings.length}',
            ),
            (
              'Avisos de impulso',
              '${widget.controller.jobBoostWarnings.length + widget.controller.hobbyBoostWarnings.length}',
            ),
          ],
        ),
        _ButtonWrap([
          _rootButton(
            'Salvar agora',
            () async =>
                _run(await widget.controller.debugForceSave(), label: 'SAVE'),
          ),
          _rootButton(
            'Offline 10s',
            () => _runOffline(const Duration(seconds: 10)),
          ),
          _rootButton(
            'Offline 1min',
            () => _runOffline(const Duration(minutes: 1)),
          ),
          _rootButton(
            'Offline 10min',
            () => _runOffline(const Duration(minutes: 10)),
          ),
          _rootButton(
            'Simular offline 1h',
            () => _runOffline(const Duration(hours: 1)),
          ),
          _rootButton(
            'Offline 8h',
            () => _runOffline(const Duration(hours: 8)),
          ),
          _rootButton(
            'Offline 12h',
            () => _runOffline(const Duration(hours: 12)),
          ),
          _rootButton(
            'Simular offline máximo',
            () => _runOffline(IdleBalance.defaultJobOfflineLimit),
          ),
        ]),
        const SizedBox(height: 8),
        if (recentJobFeedbacks.isEmpty && recentHobbyFeedbacks.isEmpty)
          const Text('Nenhum feedback recente de Empregos ou Hobbies.')
        else
          for (final feedback in recentJobFeedbacks.take(4))
            Text(
              '${IdleBalance.job(feedback.jobId).displayName}: '
              '+${NumberFormatter.money(feedback.moneyEarned)} • '
              '${feedback.cyclesCompleted} ciclo(s) • '
              '+${feedback.levelsGained} nível(is)',
              style: const TextStyle(fontSize: 12),
            ),
        for (final feedback in recentHobbyFeedbacks.take(4))
          Text(
            '${IdleBalance.hobby(feedback.hobbyId).displayName}: '
            '+${feedback.xpEarned} XP • '
            '${feedback.cyclesCompleted} ciclo(s) • '
            '+${feedback.levelsGained} nível(is)'
            '${feedback.reachedMaximumLevel ? ' • Dominado' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _legacySystemsSection() {
    final state = widget.controller.state;
    final job = IdleBalance.job('neighborhood_deliveries');
    final progress = state.jobs[job.id] ?? const ActivityProgress();
    final xpNeeded = IdleBalance.jobXpNeeded(job, progress.level);
    final now = DateTime.now().toUtc();
    final nextPayment = ActivityRuntimeService.timeUntilNextJobCycle(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final income = ActivityRuntimeService.jobIncomePerCycle(
      job: job,
      progress: progress,
      state: state,
    ).round();
    final boostRemaining = ActivityRuntimeService.remainingJobBoostTime(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );

    return _RootSection(
      title: 'Empregos, Hobbies, Inventário, Presentes, Loja e Encontros',
      icon: Icons.inventory_2_rounded,
      children: [
        const _RootTypeLabel(
          'Empregos e hobbies possuem níveis reais. Nesta rodada, a DEV controla o piloto oficial de Empregos usando o mesmo motor central da tela normal.',
        ),
        _MetricWrap(
          items: [
            ('Piloto', job.displayName),
            ('Estado', progress.active ? 'ativo' : 'pausado'),
            ('Nível', '${progress.level} / ${job.maximumLevel}'),
            ('Cargo', job.rankAtLevel(progress.level)),
            (
              'XP',
              progress.level >= job.maximumLevel
                  ? 'máximo'
                  : '${progress.experience} / $xpNeeded',
            ),
            ('Ciclos', '${progress.cycles}'),
            ('Tempo reservado', '${job.timeCostAtLevel(progress.level)}'),
            (
              'Próximo pagamento',
              progress.active ? _durationLabel(nextPayment) : 'pausado',
            ),
            ('Renda por ciclo', NumberFormatter.money(income)),
            (
              'Impulso',
              boostRemaining > Duration.zero
                  ? 'x2 por ${_durationLabel(boostRemaining)}'
                  : 'inativo',
            ),
            (
              'Total ganho',
              NumberFormatter.money(progress.lifetimeMoneyEarned),
            ),
          ],
        ),
        _ButtonWrap([
          _rootButton(
            progress.active ? 'Pausar Entregas' : 'Iniciar/retomar Entregas',
            () async => _run(
              await widget.controller.toggle(ActivityKind.job, job.id),
              label: 'ENTREGAS',
            ),
          ),
          _rootButton(
            'Completar 1 ciclo',
            () async => _run(
              await widget.controller.debugCompleteJobCycle(job.id),
              label: 'ENTREGAS CICLO',
            ),
          ),
          _rootButton(
            'Processar 10s',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(seconds: 10),
              ),
              label: 'ENTREGAS TEMPO',
            ),
          ),
          _rootButton(
            'Ativar impulso grátis',
            () async => _run(
              await widget.controller.debugActivateJobBoost(job.id),
              label: 'ENTREGAS IMPULSO',
            ),
          ),
          _rootButton(
            'Remover impulso',
            () async => _run(
              await widget.controller.debugRemoveJobBoost(job.id),
              label: 'ENTREGAS IMPULSO',
            ),
          ),
          _rootButton(
            'Impulso restante 3s',
            () async => _run(
              await widget.controller.debugSetJobBoostRemaining(
                job.id,
                const Duration(seconds: 3),
              ),
              label: 'ENTREGAS IMPULSO',
            ),
          ),
          _rootButton(
            'Expirar impulso',
            () async => _run(
              await widget.controller.debugExpireJobBoost(job.id),
              label: 'ENTREGAS IMPULSO',
            ),
          ),
          _rootButton(
            'Processar até expirar',
            () async => _run(
              await widget.controller.debugProcessJobUntilBoostExpires(job.id),
              label: 'ENTREGAS IMPULSO',
            ),
          ),
          _rootButton(
            'Processar 60s',
            () async => _run(
              await widget.controller.debugProcessJobTime(
                job.id,
                const Duration(minutes: 1),
              ),
              label: 'ENTREGAS TEMPO',
            ),
          ),
          _rootButton(
            '+2 XP Entregas',
            () async => _run(
              await widget.controller.debugAddJobXp(job.id, 2),
              label: 'ENTREGAS XP',
            ),
          ),
          _rootButton(
            '+12 XP Entregas',
            () async => _run(
              await widget.controller.debugAddJobXp(job.id, 12),
              label: 'ENTREGAS XP',
            ),
          ),
          _rootButton(
            'Nível 5',
            () async => _run(
              await widget.controller.debugSetJobLevel(job.id, 5),
              label: 'ENTREGAS NÍVEL',
            ),
          ),
          _rootButton(
            'Nível 10',
            () async => _run(
              await widget.controller.debugSetJobLevel(job.id, 10),
              label: 'ENTREGAS NÍVEL',
            ),
          ),
          _rootButton(
            'Resetar Entregas',
            () => _confirm(
              'Resetar Entregas de Bairro?',
              () async => _run(
                await widget.controller.debugResetJob(job.id),
                label: 'ENTREGAS RESET',
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _saveSection() => _RootSection(
    title: 'Save e Snapshot',
    icon: Icons.save_rounded,
    children: [
      _ButtonWrap([
        _rootButton(
          'Salvar agora',
          () async =>
              _run(await widget.controller.debugForceSave(), label: 'SAVE'),
        ),
        _rootButton(
          'Criar snapshot',
          () => _guard(() async {
            _snapshot = widget.controller.state;
            _log('Snapshot criado.');
            _setResult(
              'SNAPSHOT CRIADO\nTipo: SESSÃO ROOT\nSave solicitado: não',
            );
          }),
        ),
        _rootButton(
          'Restaurar snapshot',
          () => _confirm('Restaurar snapshot?', () async {
            if (_snapshot == null) {
              _setResult('SNAPSHOT INDISPONÍVEL\nNenhum valor alterado.');
            } else {
              _setResult(
                'RESTAURAÇÃO DE SNAPSHOT preparada.\nA aplicação direta será habilitada quando o controller expuser restore seguro.',
              );
            }
          }),
        ),
        _rootButton(
          'Validar save',
          () => _setResult(
            'SAVE VALIDADO\nFormato atual: decodificável\nTipo: SESSÃO ROOT\nSave solicitado: não',
          ),
        ),
        _rootButton(
          'Resetar cooldowns',
          () async => _run(
            await widget.controller.debugResetActionCooldowns(
              PlayableCharacterIds.roxanne,
            ),
            label: 'RESET',
          ),
        ),
        _rootButton('Resetar tudo', () => _confirmTypedReset()),
      ]),
    ],
  );

  Widget _rootLogSection() => _RootSection(
    title: 'Log ROOT',
    icon: Icons.receipt_long_rounded,
    initiallyExpanded: false,
    children: [
      if (widget.rootSession.log.isEmpty)
        const Text('Nenhuma operação ROOT registrada nesta sessão.')
      else
        for (final item in widget.rootSession.log.take(18))
          Text(
            item,
            style: const TextStyle(fontSize: 12, color: GameColors.softInk),
          ),
    ],
  );

  Future<void> _setResources({int? money, int? diamonds, int? totalBlocks}) =>
      _guard(
        () async => _run(
          await widget.controller.debugSetResources(
            money: money,
            diamonds: diamonds,
            totalBlocks: totalBlocks,
          ),
          label: 'RECURSOS',
        ),
      );

  Future<void> _setRoxanne({
    int? stage,
    int? affection,
    int? gifts,
    int? encounters,
    int? totalMoneyEarned,
  }) => _guard(
    () async => _run(
      await widget.controller.debugSetRoxanneProgress(
        stage: stage,
        affection: affection,
        gifts: gifts,
        encounters: encounters,
        totalMoneyEarned: totalMoneyEarned,
      ),
      label: 'RYOMI',
    ),
  );

  Future<void> _simulateClicks(int count) => _guard(() async {
    final safeCount = count.clamp(0, 1000);
    final before = widget
        .controller
        .state
        .characters[PlayableCharacterIds.roxanne]!
        .affection;
    for (var i = 0; i < safeCount; i++) {
      await widget.controller.tapCharacter(PlayableCharacterIds.roxanne);
    }
    final after = widget
        .controller
        .state
        .characters[PlayableCharacterIds.roxanne]!
        .affection;
    _setResult(
      'CLIQUES SIMULADOS\nAnterior: $before\nNovo: $after\nTipo: PERSISTENTE\nSave solicitado: sim\nEfeitos visuais gerados: 0',
    );
    _log('$safeCount clique(s) simulados.');
  });

  Future<void> _runOffline(Duration duration) => _guard(
    () async => _run(
      await widget.controller.debugSimulateOffline(duration),
      label: 'OFFLINE',
    ),
  );

  Future<void> _run(ActionResult result, {String label = 'OPERAÇÃO'}) async {
    _setResult(
      '$label\n${result.message}\nTipo: PERSISTENTE\nSave solicitado: sim',
    );
    _log('$label executada.');
  }

  void _toggle(VoidCallback change, String message) {
    _guard(() async {
      change();
      widget.rootSession.addLog(message);
      _setResult('$message\nTipo: SESSÃO ROOT\nSave solicitado: não');
    });
  }

  Future<void> _setCherriesInfinite(bool value) => _guard(() async {
    widget.rootSession.cherriesInfinite = value;
    final result = await widget.controller.debugSetRootPrivileges(
      cherriesInfinite: value,
    );
    _setResult(
      '${result.message}\nCerejas infinitas ${value ? 'ativadas' : 'desativadas'}.\nTipo: SESSÃO ROOT\nSave solicitado: não',
    );
    _log('Cerejas infinitas ${value ? 'ativadas' : 'desativadas'}.');
  });

  Future<void> _setTimeInfinite(bool value) => _guard(() async {
    widget.rootSession.timeInfinite = value;
    final result = await widget.controller.debugSetRootPrivileges(
      timeInfinite: value,
    );
    _setResult(
      '${result.message}\nTempo infinito ${value ? 'ativado' : 'desativado'}.\nTipo: SESSÃO ROOT\nSave solicitado: ${value ? 'não' : 'sim, se houve reconciliação'}',
    );
    _log('Tempo infinito ${value ? 'ativado' : 'desativado'}.');
  });

  Future<void> _confirm(String title, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Confirme a operação ROOT.'),
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
    if (ok == true) await _guard(action);
  }

  Future<void> _confirmTypedReset() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar tudo?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Digite RESETAR'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text == 'RESETAR') {
      await _guard(() async {
        await widget.controller.eraseProgress();
        _setResult('RESET TOTAL\nTipo: PERSISTENTE\nSave solicitado: sim');
        _log('Reset total executado.');
      });
    }
    controller.dispose();
  }

  Future<void> _confirmResetAllHobbies() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RESETAR TODOS OS HOBBIES?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Isso apagará níveis, XP, ciclos, boosts e progresso dos Hobbies.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Dinheiro, Cerejas, Empregos, Roxanne e Kai serão preservados.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Digite RESETAR TODOS OS HOBBIES',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar Hobbies'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text == 'RESETAR TODOS OS HOBBIES') {
      await _guard(
        () async => _run(
          await widget.controller.debugResetAllHobbies(),
          label: 'HOBBIES RESET GLOBAL',
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _logout() async {
    await widget.controller.debugProcessHobbiesNow();
    await widget.controller.debugSetRootPrivileges(
      timeInfinite: false,
      cherriesInfinite: false,
    );
    widget.rootSession.addLog('ROOT encerrado.');
    widget.rootSession.resetSession();
    widget.onLogout();
  }

  void _setResult(String value) {
    if (!mounted) return;
    setState(() => _lastResult = value);
  }

  void _log(String value) => widget.rootSession.addLog(value);

  int _intFrom(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String _cooldownLabel(int lastAt, Duration cooldown) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = lastAt + cooldown.inMilliseconds - now;
    if (widget.rootSession.noCooldowns || remaining <= 0) return 'Disponível';
    final seconds = (remaining / 1000).ceil();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _durationLabel(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 9999);
    return '${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _reservationLabel(TimeReservation reservation) {
    switch (reservation.ownerType) {
      case TimeReservationOwnerType.job:
        return 'Job ${IdleBalance.job(reservation.ownerId).displayName}';
      case TimeReservationOwnerType.hobby:
        return 'Hobby ${IdleBalance.hobby(reservation.ownerId).displayName}';
      case TimeReservationOwnerType.futureActivity:
        return 'Atividade futura ${reservation.ownerId}';
    }
  }

  String _timestampLabel(int timestampUtc) {
    if (timestampUtc <= 0) return 'nunca';
    return DateTime.fromMillisecondsSinceEpoch(
      timestampUtc,
      isUtc: true,
    ).toLocal().toString().split('.').first;
  }

  List<_Requirement> _requirements(
    IdleState state,
    CharacterProgress progress,
    int needed,
  ) {
    final hobbyTarget = 1 + progress.stage ~/ 2;
    final moneyTarget = progress.stage * 80;
    final giftTarget = progress.stage ~/ 2;
    final encounterTarget = progress.stage ~/ 3;
    return [
      _Requirement(
        'Afeição ${progress.affection} / $needed',
        progress.affection >= needed,
      ),
      _Requirement(
        'Música ${state.hobbies[IdleRules.favoriteHobby(PlayableCharacterIds.roxanne)]!.level} / $hobbyTarget',
        state
                .hobbies[IdleRules.favoriteHobby(PlayableCharacterIds.roxanne)]!
                .level >=
            hobbyTarget,
      ),
      if (moneyTarget > 0)
        _Requirement(
          'Renda ${NumberFormatter.money(state.totalMoneyEarned)} / ${NumberFormatter.money(moneyTarget)}',
          state.totalMoneyEarned >= moneyTarget,
        ),
      if (giftTarget > 0)
        _Requirement(
          'Presentes ${progress.gifts} / $giftTarget',
          progress.gifts >= giftTarget,
        ),
      if (encounterTarget > 0)
        _Requirement(
          'Encontros ${progress.encounters} / $encounterTarget',
          progress.encounters >= encounterTarget,
        ),
    ];
  }
}

class _Requirement {
  const _Requirement(this.label, this.complete);
  final String label;
  final bool complete;
}

class _RootDenied extends StatelessWidget {
  const _RootDenied({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Center(
    child: GamePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Acesso ROOT necessário.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onBack, child: const Text('Voltar')),
        ],
      ),
    ),
  );
}

class _RootHeader extends StatelessWidget {
  const _RootHeader({
    required this.lastResult,
    required this.onLogout,
    this.authenticatedAtUtc,
  });
  final String lastResult;
  final VoidCallback onLogout;
  final DateTime? authenticatedAtUtc;
  @override
  Widget build(BuildContext context) => GamePanel(
    key: const ValueKey('root_dev_header'),
    color: GameColors.blush.withValues(alpha: .92),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ROOT DEV — ACESSO TOTAL',
                key: ValueKey('dev_tools_title'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('SAIR DO MODO ADMIN'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Ferramentas administrativas para edição e teste do estado do jogo.',
          style: TextStyle(color: GameColors.softInk),
        ),
        const SizedBox(height: 6),
        Text(
          'Sessão atual: ROOT${authenticatedAtUtc == null ? '' : ' • ${authenticatedAtUtc!.toIso8601String()}'}',
          style: const TextStyle(
            color: GameColors.danger,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(GameRadii.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              lastResult,
              key: const ValueKey('dev_last_result'),
              style: const TextStyle(color: GameColors.ink),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RootSection extends StatelessWidget {
  const _RootSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GamePanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GameRadii.large),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: GameColors.coral),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: children,
        ),
      ),
    ),
  );
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in items)
        Container(
          width: 190,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(GameRadii.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  color: GameColors.softInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(item.$2, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
    ],
  );
}

class _ButtonWrap extends StatelessWidget {
  const _ButtonWrap(this.children);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(spacing: 8, runSpacing: 8, children: children),
  );
}

class _RootTextField extends StatelessWidget {
  const _RootTextField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class _RootProgressBar extends StatelessWidget {
  const _RootProgressBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: GameColors.softInk,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 10,
          value: value.clamp(0.0, 1.0),
          backgroundColor: GameColors.paper,
          valueColor: const AlwaysStoppedAnimation(GameColors.coral),
        ),
      ),
    ],
  );
}

class _RootSwitch extends StatelessWidget {
  const _RootSwitch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true,
    value: value,
    onChanged: onChanged,
    title: Text(label),
    subtitle: const Text('SESSÃO ROOT'),
  );
}

class _RootTypeLabel extends StatelessWidget {
  const _RootTypeLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: const TextStyle(color: GameColors.softInk)),
  );
}

Widget _rootButton(String label, FutureOr<void> Function() onPressed) =>
    FilledButton.tonal(onPressed: () async => onPressed(), child: Text(label));
