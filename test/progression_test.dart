import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/core/progression.dart';
import 'package:projeto_conexoes/models/game_state.dart';

void main() {
  test('estágio avança quando todos os requisitos são atendidos', () {
    const progress = LiaProgress(
      affinity: 7,
      trust: 3,
      respect: 3,
      completedDialogues: {'lia_1', 'lia_2', 'lia_3'},
    );
    const state = GameState(empathy: 3, charisma: 2, lia: progress);

    expect(Progression.calculateStage(state), 3);
  });

  test('estágio não avança sem a conversa exigida', () {
    const progress = LiaProgress(
      affinity: 4,
      trust: 2,
      respect: 2,
      completedDialogues: {'lia_1'},
    );
    const state = GameState(empathy: 3, lia: progress);

    expect(Progression.calculateStage(state), 1);
  });
}
