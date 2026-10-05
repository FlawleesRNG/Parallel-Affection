import 'package:flutter/foundation.dart';

import '../../core/character_catalog.dart';
import '../../services/conversation_dialogue_selector.dart';
import '../dialogue/dialogue_message_v3.dart';
import '../dialogue/dialogue_queue_v3.dart';
import '../dialogue/ryomi_dialogue_catalog_v3.dart';

class RyomiWindowsControllerV3 extends ChangeNotifier {
  RyomiWindowsControllerV3({ConversationDialogueSelector? conversationSelector})
    : dialogueQueue = DialogueQueueV3(
        initialMessage: RyomiDialogueCatalogV3.initial(),
      ),
      _conversationSelector =
          conversationSelector ?? ConversationDialogueSelector() {
    dialogueQueue.addListener(notifyListeners);
  }

  final DialogueQueueV3 dialogueQueue;
  final ConversationDialogueSelector _conversationSelector;

  bool relationshipOpen = true;
  bool objectivesExpanded = false;
  bool interactionOpen = true;
  bool dialogueOpen = true;
  bool hasUnreadDialogue = false;
  int _interactSequence = 0;
  int _idleSequence = 0;

  String get currentDialogue => dialogueQueue.current.text;
  String get speakerName => dialogueQueue.current.speakerName;
  DialogueMessage get currentDialogueMessage => dialogueQueue.current;
  int get queuedDialogueCount => dialogueQueue.queuedCount;

  @override
  void dispose() {
    dialogueQueue.removeListener(notifyListeners);
    super.dispose();
  }

  void minimizeRelationship() {
    if (!relationshipOpen) return;
    relationshipOpen = false;
    notifyListeners();
  }

  void restoreRelationship() {
    if (relationshipOpen) return;
    relationshipOpen = true;
    notifyListeners();
  }

  void toggleObjectives() {
    objectivesExpanded = !objectivesExpanded;
    notifyListeners();
  }

  void minimizeInteraction() {
    if (!interactionOpen) return;
    interactionOpen = false;
    notifyListeners();
  }

  void restoreInteraction() {
    if (interactionOpen) return;
    interactionOpen = true;
    notifyListeners();
  }

  void minimizeDialogue() {
    if (!dialogueOpen) return;
    dialogueOpen = false;
    notifyListeners();
  }

  void restoreDialogue() {
    if (dialogueOpen && !hasUnreadDialogue) return;
    dialogueOpen = true;
    hasUnreadDialogue = false;
    notifyListeners();
  }

  void advanceDialogue() {
    final advanced = dialogueQueue.advance();
    if (!advanced) {
      _idleSequence++;
      dialogueQueue.showNow(
        _idleSequence.isEven
            ? RyomiDialogueCatalogV3.initial()
            : RyomiDialogueCatalogV3.fallback(),
      );
    }
    hasUnreadDialogue = false;
    notifyListeners();
  }

  void completeDialogueText() {
    notifyListeners();
  }

  void showTalkDialogue({
    required String characterId,
    required int relationshipStage,
  }) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    final dialogue = _conversationSelector.select(
      characterId: canonicalId,
      stage: relationshipStage,
    );
    dialogueQueue.showNow(
      DialogueMessage.create(
        id: dialogue.id,
        characterId: canonicalId,
        speakerName: PlayableCharacterCatalog.visibleName(canonicalId),
        text: dialogue.text,
        context: DialogueContext.talk,
        relationshipStage: relationshipStage,
      ),
    );
    _markUnreadWhenClosed();
  }

  String? lastConversationDialogueId({
    required String characterId,
    required int relationshipStage,
  }) => _conversationSelector.lastDialogueIdFor(
    characterId: characterId,
    stage: relationshipStage,
  );

  void showCharacterFallback(String characterId) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    if (canonicalId == PlayableCharacterIds.roxanne) return;
    final dialogue = _conversationSelector.select(
      characterId: canonicalId,
      stage: 0,
    );
    dialogueQueue.showNow(
      DialogueMessage.create(
        id: '${canonicalId}_${dialogue.id}',
        characterId: canonicalId,
        speakerName: PlayableCharacterCatalog.visibleName(canonicalId),
        text: dialogue.text,
        context: DialogueContext.systemFallback,
      ),
    );
    _markUnreadWhenClosed();
  }

  void showInteractDialogue(int relationshipStage) {
    dialogueQueue.showNow(
      RyomiDialogueCatalogV3.interact(relationshipStage, _interactSequence++),
    );
    _markUnreadWhenClosed();
  }

  void enqueueRelationshipAdvance(int relationshipStage) {
    dialogueQueue.enqueue(
      RyomiDialogueCatalogV3.relationshipAdvance(relationshipStage),
    );
    _markUnreadWhenClosed();
  }

  void enqueueUnlockDialogue(String id, String text) {
    dialogueQueue.enqueue(RyomiDialogueCatalogV3.unlock(id, text));
    _markUnreadWhenClosed();
  }

  void _markUnreadWhenClosed() {
    if (!dialogueOpen) hasUnreadDialogue = true;
    notifyListeners();
  }
}
