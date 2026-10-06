import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
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
  test('catálogo oficial possui vinte presentes com valores publicados', () {
    expect(IdleBalance.gifts, hasLength(20));
    expect(IdleBalance.gift('love_letter').unitPrice, 10);
    expect(IdleBalance.gift('coffee').affectionPerUnit, 3);
    expect(IdleBalance.gift('cake').unitPrice, 1000);
    expect(IdleBalance.gift('wedding_ring').unitPrice, 200000000);
    expect(IdleBalance.gift('wedding_ring').affectionPerUnit, 20000000);
  });

  test('entrega é atômica e isolada por personagem', () async {
    final controller = GameController(_MemoryStorage());
    await controller.initialize();
    await controller.debugMoney(1000);
    await controller.debugSetCharacterUnlocked('sofia', true);

    await controller.gift('sofia', 'coffee', 10);

    expect(controller.state.money, 750);
    expect(controller.state.characters['sofia']!.affection, 30);
    expect(controller.state.characters['sofia']!.giftDeliveries['coffee'], 10);
    expect(
      controller.state.characters['roxanne']!.giftDeliveries['coffee'],
      isNull,
    );
  });

  test('saldo insuficiente não altera a transação', () async {
    final controller = GameController(_MemoryStorage());
    await controller.initialize();
    await controller.debugMoney(100);
    final result = await controller.gift('roxanne', 'coffee', 10);

    expect(result.message, contains('insuficiente'));
    expect(controller.state.money, 100);
    expect(controller.state.characters['roxanne']!.affection, 0);
    expect(controller.state.characters['roxanne']!.giftDeliveries, isEmpty);
  });
}
