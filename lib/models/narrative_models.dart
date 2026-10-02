class NarrativeProgress {
  const NarrativeProgress({
    this.unlockedEpisodes = const {},
    this.completedEpisodes = const {},
    this.flags = const {},
    this.choiceHistory = const {},
  });
  final Set<String> unlockedEpisodes;
  final Set<String> completedEpisodes;
  final Set<String> flags;
  final Map<String, List<String>> choiceHistory;
  NarrativeProgress copyWith({
    Set<String>? unlockedEpisodes,
    Set<String>? completedEpisodes,
    Set<String>? flags,
    Map<String, List<String>>? choiceHistory,
  }) => NarrativeProgress(
    unlockedEpisodes: unlockedEpisodes ?? this.unlockedEpisodes,
    completedEpisodes: completedEpisodes ?? this.completedEpisodes,
    flags: flags ?? this.flags,
    choiceHistory: choiceHistory ?? this.choiceHistory,
  );
  Map<String, dynamic> toJson() => {
    'unlockedEpisodes': unlockedEpisodes.toList(),
    'completedEpisodes': completedEpisodes.toList(),
    'flags': flags.toList(),
    'choiceHistory': choiceHistory,
  };
  factory NarrativeProgress.fromJson(Map<String, dynamic>? json) =>
      NarrativeProgress(
        unlockedEpisodes: (json?['unlockedEpisodes'] as List<dynamic>? ?? [])
            .cast<String>()
            .toSet(),
        completedEpisodes: (json?['completedEpisodes'] as List<dynamic>? ?? [])
            .cast<String>()
            .toSet(),
        flags: (json?['flags'] as List<dynamic>? ?? []).cast<String>().toSet(),
        choiceHistory: (json?['choiceHistory'] as Map<String, dynamic>? ?? {})
            .map(
              (id, values) =>
                  MapEntry(id, (values as List<dynamic>).cast<String>()),
            ),
      );
}

class StoryEpisodeDefinition {
  const StoryEpisodeDefinition({
    required this.id,
    required this.characterId,
    required this.title,
    required this.placeholder,
  });
  final String id, characterId, title, placeholder;
}
