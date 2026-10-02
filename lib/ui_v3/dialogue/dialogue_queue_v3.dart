import 'package:flutter/foundation.dart';

import 'dialogue_message_v3.dart';

class DialogueQueueV3 extends ChangeNotifier {
  DialogueQueueV3({required DialogueMessage initialMessage})
    : _current = initialMessage;

  DialogueMessage _current;
  final List<DialogueMessage> _pending = [];

  DialogueMessage get current => _current;
  List<DialogueMessage> get pending => List.unmodifiable(_pending);
  int get queuedCount => _pending.length;
  bool get hasQueuedMessages => _pending.isNotEmpty;

  void showNow(DialogueMessage message) {
    if (!_canAccept(message)) return;
    _current = message;
    notifyListeners();
  }

  void enqueue(DialogueMessage message) {
    if (!_canAccept(message)) return;
    switch (message.priority) {
      case DialoguePriority.normal:
        _pending.add(message);
      case DialoguePriority.important:
        _pending.insert(0, message);
      case DialoguePriority.critical:
        _pending
          ..clear()
          ..add(message);
    }
    notifyListeners();
  }

  bool advance() {
    if (_pending.isEmpty) return false;
    _current = _pending.removeAt(0);
    notifyListeners();
    return true;
  }

  bool _canAccept(DialogueMessage message) {
    if (message.canRepeat) return true;
    if (_current.id == message.id) return false;
    return !_pending.any((item) => item.id == message.id);
  }
}
