import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dialogue.dart';

class DialogueRepository {
  List<Dialogue> _dialogues = const [];
  List<Dialogue> get dialogues => _dialogues;

  Future<void> load() async {
    final source = await rootBundle.loadString(
      'assets/data/lia_dialogues.json',
    );
    final decoded = jsonDecode(source) as List<dynamic>;
    _dialogues = decoded
        .map((item) => Dialogue.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Dialogue? nextAvailable(Set<String> completed) {
    for (final dialogue in _dialogues) {
      if (!completed.contains(dialogue.id)) return dialogue;
    }
    return null;
  }
}
