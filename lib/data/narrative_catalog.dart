import '../models/narrative_models.dart';

abstract final class NarrativeCatalog {
  static const episodes = [
    StoryEpisodeDefinition(
      id: 'roxanne_after_hours',
      characterId: 'roxanne',
      title: 'Depois do programa',
      placeholder:
          'Episódio narrativo de Roxanne preparado para uma etapa futura.',
    ),
  ];
  static StoryEpisodeDefinition? byId(String? id) =>
      id == null ? null : episodes.where((item) => item.id == id).firstOrNull;
}
