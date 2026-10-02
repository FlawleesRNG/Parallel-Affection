import 'package:flutter/material.dart';

import '../controllers/ryomi_windows_controller_v3.dart';
import 'character_dialogue_window_v3.dart';

class DialogueWindowV3 extends StatelessWidget {
  const DialogueWindowV3({
    super.key,
    required this.windowsController,
    required this.selectedCharacterName,
    this.compact = false,
  });

  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterName;
  final bool compact;

  @override
  Widget build(BuildContext context) => CharacterDialogueWindowV3(
    // Dialogue content may still originate from a shared queue, but the scene
    // chrome must always identify the character currently on stage.
    speakerName: selectedCharacterName,
    text: windowsController.currentDialogue,
    queuedCount: windowsController.queuedDialogueCount,
    minimized: !windowsController.dialogueOpen,
    hasUnread: windowsController.hasUnreadDialogue,
    compact: compact,
    onAdvance: windowsController.advanceDialogue,
    onCompleteText: windowsController.completeDialogueText,
    onMinimize: windowsController.minimizeDialogue,
    onRestore: windowsController.restoreDialogue,
  );
}
