import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/game_controller.dart';
import '../../core/theme/visual_themes.dart';
import '../../services/admin_auth_service.dart';
import '../../services/root_dev_session_state.dart';
import '../../shared/game_ui.dart';
import '../../ui_v2/design/connections_design.dart';
import '../../ui_v2/screens/ryomi_screen_v2.dart';
import '../../ui_v2/shell/connections_bottom_menu_v2.dart';
import '../../ui_v2/shell/connections_hud_v2.dart';
import '../../ui_v3/components/bottom_dock_v3.dart';
import '../../ui_v3/components/top_hud_v3.dart';
import '../../ui_v3/debug/design_system_preview_v3.dart';
import '../../ui_v3/debug/ui_debug_settings_v3.dart';
import '../../ui_v3/design/connections_colors_v3.dart';
import '../../ui_v3/layout/ryomi_breakpoints_v3.dart';
import '../../ui_v3/layout/dev_scene_layout_config.dart';
import '../../ui_v3/screens/ryomi_screen_v3.dart';
import '../activities/hobbies_view.dart';
import '../activities/jobs_view.dart';
import '../characters/ryomi_gameplay_view.dart';
import '../dev/dev_tools_view.dart';
import 'auxiliary_views.dart';

class IdleDatingGameShell extends StatefulWidget {
  const IdleDatingGameShell({super.key, required this.controller});

  final GameController controller;

  @override
  State<IdleDatingGameShell> createState() => _IdleDatingGameShellState();
}

class _IdleDatingGameShellState extends State<IdleDatingGameShell> {
  int selectedIndex = 0;
  bool useUiV2 = kDebugMode;
  bool useUiV3 = !kDebugMode || const bool.fromEnvironment('RYOMI_UI_V3');
  late final LocalAdminAuthService _adminAuth;
  late final RootDevSessionState _rootDevSession;
  late final DevSceneLayoutController _layoutEditor;

  @override
  void initState() {
    super.initState();
    _adminAuth = LocalAdminAuthService();
    _rootDevSession = RootDevSessionState();
    _layoutEditor = DevSceneLayoutController();
    unawaited(_layoutEditor.load());
    widget.controller.addListener(_onControllerChanged);
    _adminAuth.addListener(_onAdminChanged);
  }

  @override
  void didUpdateWidget(covariant IdleDatingGameShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _adminAuth.removeListener(_onAdminChanged);
    _adminAuth.dispose();
    _rootDevSession.dispose();
    _layoutEditor.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onAdminChanged() {
    if (!mounted) return;
    if (!_adminAuth.isAuthenticated) {
      _rootDevSession.resetSession();
      unawaited(
        widget.controller.debugSetRootPrivileges(
          timeInfinite: false,
          cherriesInfinite: false,
        ),
      );
      if (selectedIndex >= _basePageCount) selectedIndex = _extrasIndex;
      _layoutEditor.close();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const visual = GameVisualTheme.current;
    final rootActive = _adminAuth.accessLevel == AdminAccessLevel.root;
    final pages = <Widget>[
      useUiV2
          ? RyomiScreenV2(controller: widget.controller)
          : RyomiGameplayView(controller: widget.controller),
      JobsView(controller: widget.controller),
      HobbiesView(controller: widget.controller),
      StatisticsView(controller: widget.controller),
      AchievementsView(controller: widget.controller),
      StoreView(controller: widget.controller),
      MoreView(
        controller: widget.controller,
        adminAuth: _adminAuth,
        rootDevSession: _rootDevSession,
        onOpenDev: () {
          if (_adminAuth.accessLevel != AdminAccessLevel.root) return;
          setState(() => selectedIndex = _devIndex);
        },
      ),
      if (rootActive)
        DevToolsView(
          controller: widget.controller,
          adminAuth: _adminAuth,
          rootSession: _rootDevSession,
          onLogout: () => _adminAuth.logout(),
          onOpenLayoutEditor: () => setState(() {
            _layoutEditor.open();
            selectedIndex = 0;
          }),
        ),
    ];
    if (selectedIndex >= pages.length) selectedIndex = 0;
    return Scaffold(
      body: SafeArea(
        child: _withDeveloperShortcuts(
          Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: useUiV2
                        ? useUiV3
                              ? const LinearGradient(
                                  colors: [
                                    ConnectionsColorsV3.background,
                                    ConnectionsColorsV3.backgroundSecondary,
                                  ],
                                )
                              : ConnectionsThemeV2.backgroundGradient
                        : visual.backgroundGradient,
                  ),
                  child: Stack(
                    children: [
                      if (!useUiV2 && !useUiV3) const CuteBackdropPattern(),
                      useUiV3
                          ? _buildV3Shell(pages)
                          : _buildCurrentShell(pages),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withDeveloperShortcuts(Widget child) {
    if (!kDebugMode) return child;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
            _ToggleUiV3Intent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true):
            _OpenDesignSystemPreviewIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true, shift: true):
            _ToggleUiDebugLabelsIntent(),
      },
      child: Actions(
        actions: {
          _ToggleUiV3Intent: CallbackAction<_ToggleUiV3Intent>(
            onInvoke: (_) {
              setState(() => useUiV3 = !useUiV3);
              return null;
            },
          ),
          _OpenDesignSystemPreviewIntent:
              CallbackAction<_OpenDesignSystemPreviewIntent>(
                onInvoke: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DesignSystemPreviewV3(),
                    ),
                  );
                  return null;
                },
              ),
          _ToggleUiDebugLabelsIntent:
              CallbackAction<_ToggleUiDebugLabelsIntent>(
                onInvoke: (_) {
                  UiDebugSettingsV3.toggleLabels();
                  return null;
                },
              ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  Widget _buildCurrentShell(List<Widget> pages) => Column(
    children: [
      useUiV2
          ? ConnectionsHudV2(
              state: widget.controller.state,
              onSettings: () =>
                  showGameSettingsDialog(context, widget.controller),
            )
          : GameResourceBar(
              state: widget.controller.state,
              onSettings: () =>
                  showGameSettingsDialog(context, widget.controller),
            ),
      Expanded(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      useUiV2
          ? ConnectionsBottomMenuV2(
              selectedIndex: selectedIndex,
              onSelected: (value) => setState(() => selectedIndex = value),
            )
          : GameBottomDock(
              selectedIndex: selectedIndex,
              onSelected: (value) => setState(() => selectedIndex = value),
            ),
    ],
  );

  Widget _buildV3Shell(List<Widget> pages) {
    return Column(
      key: const ValueKey('ryomi_ui_v3_shell'),
      children: [
        Builder(
          builder: (context) {
            final spec = RyomiLayoutSpec.fromSize(MediaQuery.sizeOf(context));
            return TopHudV3(
              state: widget.controller.state,
              spec: spec,
              savePhase: widget.controller.savePhase,
              saveError: widget.controller.saveError,
              saveSequence: widget.controller.saveSequence,
              onSettings: () =>
                  showGameSettingsDialog(context, widget.controller),
            );
          },
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final spec = RyomiLayoutSpec.fromSize(MediaQuery.sizeOf(context));
              return selectedIndex == 0
                  ? RyomiScreenV3(
                      controller: widget.controller,
                      spec: spec,
                      // The approved scene draft is a gameplay layout, not a
                      // ROOT-only visual. ROOT only controls whether its
                      // editor overlay can be opened.
                      layoutEditor: _layoutEditor,
                    )
                  : pages[selectedIndex];
            },
          ),
        ),
        Builder(
          builder: (context) {
            final spec = RyomiLayoutSpec.fromSize(MediaQuery.sizeOf(context));
            final rootActive = _adminAuth.accessLevel == AdminAccessLevel.root;
            return BottomDockV3(
              selectedIndex: selectedIndex,
              spec: spec,
              showDev: rootActive,
              onSelected: (value) {
                if (value == _devIndex &&
                    _adminAuth.accessLevel != AdminAccessLevel.root) {
                  setState(() => selectedIndex = _extrasIndex);
                  return;
                }
                setState(() => selectedIndex = value);
              },
            );
          },
        ),
      ],
    );
  }

  static const _basePageCount = 7;
  static const _extrasIndex = 6;
  static const _devIndex = 7;
}

class _ToggleUiV3Intent extends Intent {
  const _ToggleUiV3Intent();
}

class _OpenDesignSystemPreviewIntent extends Intent {
  const _OpenDesignSystemPreviewIntent();
}

class _ToggleUiDebugLabelsIntent extends Intent {
  const _ToggleUiDebugLabelsIntent();
}
