import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/title_screen.dart';
import '../services/game_storage.dart';
import '../ui_v3/design/connections_theme_v3.dart';
import 'game_controller.dart';

class ProjetoConexoesApp extends StatefulWidget {
  const ProjetoConexoesApp({super.key});
  @override
  State<ProjetoConexoesApp> createState() => _ProjetoConexoesAppState();
}

class _ProjetoConexoesAppState extends State<ProjetoConexoesApp> {
  final controller = GameController(PreferencesGameStorage.create());
  late final Future<void> _boot = controller.initialize();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Parallel Affection',
    debugShowCheckedModeBanner: false,
    theme: ConnectionsThemeV3.applyTo(AppTheme.dark()),
    home: FutureBuilder<void>(
      future: _boot,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
          ? MainMenuScreen(controller: controller)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}
