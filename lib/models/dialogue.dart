class DialogueChoice {
  const DialogueChoice({
    required this.id,
    required this.label,
    required this.effects,
    this.requirements = const {},
    this.unlockScene,
  });
  final String id;
  final String label;
  final Map<String, int> effects;
  final Map<String, int> requirements;
  final String? unlockScene;

  factory DialogueChoice.fromJson(Map<String, dynamic> json) => DialogueChoice(
    id: json['id'] as String,
    label: json['label'] as String,
    effects: (json['effects'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    ),
    requirements: (json['requirements'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, value as int),
    ),
    unlockScene: json['unlockScene'] as String?,
  );
}

class Dialogue {
  const Dialogue({
    required this.id,
    required this.title,
    required this.text,
    required this.choices,
  });
  final String id;
  final String title;
  final String text;
  final List<DialogueChoice> choices;

  factory Dialogue.fromJson(Map<String, dynamic> json) => Dialogue(
    id: json['id'] as String,
    title: json['title'] as String,
    text: json['text'] as String,
    choices: (json['choices'] as List<dynamic>)
        .map((item) => DialogueChoice.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
