/// Pontos de integração para áudio futuro.
///
/// A implementação permanece intencionalmente silenciosa nesta versão e não
/// cria dependência de assets ou bibliotecas de áudio inexistentes.
enum GameAudioCue {
  click,
  reward,
  stageAdvance,
  gift,
  encounter,
  menu,
  jobCycle,
}

abstract final class GameAudioHooks {
  static void emit(GameAudioCue cue) {
    // No-op até o sistema de áudio ser implementado.
  }
}
