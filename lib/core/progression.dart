import '../models/game_state.dart';

class StageRequirement {
  const StageRequirement({
    required this.affinity,
    required this.trust,
    required this.respect,
    required this.attribute,
    required this.value,
    required this.dialogue,
  });
  final int affinity;
  final int trust;
  final int respect;
  final String attribute;
  final int value;
  final String dialogue;
}

abstract final class Progression {
  static const requirements = [
    StageRequirement(
      affinity: 2,
      trust: 1,
      respect: 1,
      attribute: 'empatia',
      value: 1,
      dialogue: 'lia_1',
    ),
    StageRequirement(
      affinity: 4,
      trust: 2,
      respect: 2,
      attribute: 'empatia',
      value: 2,
      dialogue: 'lia_2',
    ),
    StageRequirement(
      affinity: 7,
      trust: 3,
      respect: 3,
      attribute: 'carisma',
      value: 2,
      dialogue: 'lia_3',
    ),
    StageRequirement(
      affinity: 10,
      trust: 5,
      respect: 5,
      attribute: 'coragem',
      value: 2,
      dialogue: 'lia_3',
    ),
  ];

  static int calculateStage(GameState state) {
    var stage = 0;
    for (var index = 0; index < requirements.length; index++) {
      final rule = requirements[index];
      final lia = state.lia;
      if (lia.affinity >= rule.affinity &&
          lia.trust >= rule.trust &&
          lia.respect >= rule.respect &&
          state.valueFor(rule.attribute) >= rule.value &&
          lia.completedDialogues.contains(rule.dialogue)) {
        stage = index + 1;
      } else {
        break;
      }
    }
    return stage;
  }

  static String nextRequirement(GameState state) {
    if (state.lia.stage >= requirements.length) {
      return 'Rota demonstrativa concluída.';
    }
    final item = requirements[state.lia.stage];
    return 'Afinidade ${item.affinity}, confiança ${item.trust}, respeito ${item.respect}, '
        '${item.attribute} ${item.value} e conversa concluída.';
  }
}
