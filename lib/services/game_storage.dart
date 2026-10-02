import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GameStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

abstract interface class RecoverableGameStorage implements GameStorage {
  Future<String?> readBackup();
  Future<void> writeBackup(String value);
}

class PreferencesGameStorage implements RecoverableGameStorage {
  PreferencesGameStorage(this._preferences);
  final SharedPreferencesAsync _preferences;
  static const _key = 'projeto_conexoes.save.v2';
  static const _legacyKey = 'projeto_conexoes.save.v1';
  static const _backupKey = 'projeto_conexoes.save.v2.backup';
  factory PreferencesGameStorage.create() =>
      PreferencesGameStorage(SharedPreferencesAsync());
  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
    await _preferences.remove(_legacyKey);
    await _preferences.remove(_backupKey);
  }

  @override
  Future<String?> read() async =>
      await _preferences.getString(_key) ??
      await _preferences.getString(_legacyKey);
  @override
  Future<void> write(String value) async {
    final current = await _preferences.getString(_key);
    if (current != null && current.isNotEmpty) {
      await writeBackup(current);
    }
    await _preferences.setString(_key, value);
  }

  @override
  Future<String?> readBackup() => _preferences.getString(_backupKey);

  @override
  Future<void> writeBackup(String value) =>
      _preferences.setString(_backupKey, value);
}
