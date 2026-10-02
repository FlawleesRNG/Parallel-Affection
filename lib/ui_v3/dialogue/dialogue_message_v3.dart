enum DialogueContext {
  idle,
  talk,
  interact,
  relationshipAdvance,
  gift,
  date,
  unlock,
  systemFallback,
}

enum DialoguePriority { normal, important, critical }

class DialogueMessage {
  DialogueMessage({
    required this.id,
    required this.characterId,
    required this.speakerName,
    required this.text,
    required this.context,
    required this.priority,
    required this.createdAt,
    this.relationshipStage,
    this.canRepeat = true,
  });

  factory DialogueMessage.create({
    required String id,
    required String characterId,
    required String speakerName,
    required String text,
    required DialogueContext context,
    DialoguePriority priority = DialoguePriority.normal,
    int? relationshipStage,
    bool canRepeat = true,
  }) => DialogueMessage(
    id: id,
    characterId: characterId,
    speakerName: speakerName,
    text: text,
    context: context,
    priority: priority,
    relationshipStage: relationshipStage,
    createdAt: DateTime.now(),
    canRepeat: canRepeat,
  );

  final String id;
  final String characterId;
  final String speakerName;
  final String text;
  final DialogueContext context;
  final DialoguePriority priority;
  final int? relationshipStage;
  final DateTime createdAt;
  final bool canRepeat;
}
