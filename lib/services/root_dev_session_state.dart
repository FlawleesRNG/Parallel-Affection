import 'package:flutter/foundation.dart';

class RootDevSessionState extends ChangeNotifier {
  bool moneyInfinite = false;
  bool cherriesInfinite = false;
  bool timeInfinite = false;
  bool xpInfinite = false;
  bool giftsInfinite = false;
  bool noCooldowns = false;

  final List<String> log = [];

  bool get anyInfinite =>
      moneyInfinite ||
      cherriesInfinite ||
      timeInfinite ||
      xpInfinite ||
      giftsInfinite ||
      noCooldowns;

  void addLog(String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    log.insert(0, '[$time] $message');
    if (log.length > 80) log.removeLast();
    notifyListeners();
  }

  void toggleAll(bool enabled) {
    moneyInfinite = enabled;
    cherriesInfinite = enabled;
    timeInfinite = enabled;
    xpInfinite = enabled;
    giftsInfinite = enabled;
    noCooldowns = enabled;
    addLog(enabled ? 'Modos disponíveis ativados.' : 'Modos desativados.');
  }

  void resetSession() {
    moneyInfinite = false;
    cherriesInfinite = false;
    timeInfinite = false;
    xpInfinite = false;
    giftsInfinite = false;
    noCooldowns = false;
    log.clear();
    notifyListeners();
  }
}
