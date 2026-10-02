import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/models/narrative_models.dart';
import 'package:projeto_conexoes/services/narrative_service.dart';

void main() {
  test('episódio é desbloqueado uma única vez e preserva flags futuras', () {
    final progress = const NarrativeProgress(flags: {'conheceu_lia'});
    final service = LocalNarrativeService();
    final first = service.unlockEpisode(progress, 'lia_after_hours');
    final second = service.unlockEpisode(first, 'lia_after_hours');
    expect(second.unlockedEpisodes, {'lia_after_hours'});
    expect(second.flags, {'conheceu_lia'});
  });
}
