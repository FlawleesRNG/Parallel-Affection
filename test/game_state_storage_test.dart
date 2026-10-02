import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/models/game_state.dart';
import 'package:projeto_conexoes/services/game_storage.dart';

class MemoryStorage implements GameStorage {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test('salvamento preserva recursos e progresso de Lia', () async {
    final storage = MemoryStorage();
    const original = GameState(
      day: 4,
      money: 220,
      empathy: 3,
      lia: LiaProgress(
        affinity: 5,
        trust: 2,
        completedDialogues: {'lia_1'},
        choices: {'lia_1': 'sincerity'},
        unlockedScenes: {'end_of_day'},
      ),
    );

    await storage.write(original.encode());
    final restored = GameState.decode((await storage.read())!);

    expect(restored.day, 4);
    expect(restored.money, 220);
    expect(restored.empathy, 3);
    expect(restored.lia.choices['lia_1'], 'sincerity');
    expect(restored.lia.unlockedScenes, contains('end_of_day'));
  });
}
