import '../models/narrative_models.dart';

abstract interface class NarrativeService {
  NarrativeProgress unlockEpisode(NarrativeProgress progress, String episodeId);
}

class LocalNarrativeService implements NarrativeService {
  @override
  NarrativeProgress unlockEpisode(
    NarrativeProgress progress,
    String episodeId,
  ) => progress.unlockedEpisodes.contains(episodeId)
      ? progress
      : progress.copyWith(
          unlockedEpisodes: {...progress.unlockedEpisodes, episodeId},
        );
}
