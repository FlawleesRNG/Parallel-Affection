import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/activity_runtime_service.dart';
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

void main() {
  test('upgrade permanente custa cinco Cerejas uma única vez', () async {
    final controller = GameController(_MemoryStorage());
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugSetResources(diamonds: 5);

    await controller.purchaseActivityUpgrade(ActivityKind.hobby, 'leitura');
    expect(controller.state.diamonds, 0);
    expect(controller.state.hobbies['leitura']!.upgraded, isTrue);

    await controller.purchaseActivityUpgrade(ActivityKind.hobby, 'leitura');
    expect(controller.state.diamonds, 0);
  });

  test('saldo insuficiente não aprimora atividade', () async {
    final controller = GameController(_MemoryStorage());
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugSetResources(diamonds: 4);

    final result = await controller.purchaseActivityUpgrade(
      ActivityKind.job,
      'neighborhood_deliveries',
    );
    expect(result.message, contains('Cerejas insuficientes'));
    expect(controller.state.jobs['neighborhood_deliveries']!.upgraded, isFalse);
    expect(controller.state.diamonds, 4);
  });

  test('Job aprimorado exibe renda x2 sem mudar a XP', () {
    final job = IdleBalance.job('neighborhood_deliveries');
    final state = IdleState.fresh();
    final normal = ActivityRuntimeService.jobIncomePerCycle(
      job: job,
      progress: const ActivityProgress(isUnlocked: true),
      state: state,
    );
    final upgraded = ActivityRuntimeService.jobIncomePerCycle(
      job: job,
      progress: const ActivityProgress(isUnlocked: true, upgraded: true),
      state: state,
    );
    expect(upgraded, normal * 2);
  });
}
