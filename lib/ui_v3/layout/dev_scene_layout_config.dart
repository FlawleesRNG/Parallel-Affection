import 'dart:ui';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DevLayoutElement {
  characterArea,
  relationship,
  actions,
  dialogue,
  selector,
}

enum DevLayoutMode { global, character }

enum DevSnap { off, four, eight, sixteen }

enum DevDesktopBreakpoint { compact, standard, large, ultra }

class DevNormalizedRect {
  const DevNormalizedRect(this.x, this.y, this.width, this.height);
  final double x;
  final double y;
  final double width;
  final double height;

  DevNormalizedRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) => DevNormalizedRect(
    x ?? this.x,
    y ?? this.y,
    width ?? this.width,
    height ?? this.height,
  ).normalized();

  DevNormalizedRect normalized() => DevNormalizedRect(
    x.isFinite ? x.clamp(-.5, 1.0).toDouble() : 0,
    y.isFinite ? y.clamp(-.5, 1.0).toDouble() : 0,
    width.isFinite ? width.clamp(.04, 1.2).toDouble() : .2,
    height.isFinite ? height.clamp(.04, 1.2).toDouble() : .2,
  );

  Map<String, double> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
  factory DevNormalizedRect.fromJson(Map<String, dynamic> json) =>
      DevNormalizedRect(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
        (json['width'] as num?)?.toDouble() ?? .2,
        (json['height'] as num?)?.toDouble() ?? .2,
      ).normalized();
}

class DevCharacterVisualOverride {
  const DevCharacterVisualOverride({
    this.scaleMultiplier = 1,
    this.offsetX = 0,
    this.offsetY = 0,
  });
  final double scaleMultiplier;
  final double offsetX;
  final double offsetY;
  DevCharacterVisualOverride copyWith({
    double? scaleMultiplier,
    double? offsetX,
    double? offsetY,
  }) => DevCharacterVisualOverride(
    scaleMultiplier: (scaleMultiplier ?? this.scaleMultiplier)
        .clamp(.25, 3.0)
        .toDouble(),
    offsetX: (offsetX ?? this.offsetX).clamp(-500, 500).toDouble(),
    offsetY: (offsetY ?? this.offsetY).clamp(-500, 500).toDouble(),
  );
  Map<String, double> toJson() => {
    'scaleMultiplier': scaleMultiplier,
    'offsetX': offsetX,
    'offsetY': offsetY,
  };
  factory DevCharacterVisualOverride.fromJson(Map<String, dynamic> json) =>
      DevCharacterVisualOverride(
        scaleMultiplier: (json['scaleMultiplier'] as num?)?.toDouble() ?? 1,
        offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
        offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
      ).copyWith();
}

class DevSceneLayoutDraft {
  const DevSceneLayoutDraft({
    required this.elements,
    this.characterOverrides = const {},
    this.locks = const {},
    this.schemaVersion = 1,
  });
  final int schemaVersion;
  final Map<DevLayoutElement, DevNormalizedRect> elements;
  final Map<String, DevCharacterVisualOverride> characterOverrides;
  final Map<DevLayoutElement, bool> locks;

  /// Canonical scene scale approved from the Roxanne reference. All roster
  /// characters inherit this exact scale unless a future art correction is
  /// explicitly approved.
  static const approvedCharacterScale = 1.45;
  static const approvedCharacterOffsetX = -154.0;
  static const approvedCharacterOffsetY = 189.0;

  /// Approved baseline promoted from Roxanne's saved DEV layout. Every new
  /// character inherits this scene geometry and only needs a visual override
  /// when its transparent canvas requires compensation.
  static DevSceneLayoutDraft currentDefaults() => const DevSceneLayoutDraft(
    elements: {
      DevLayoutElement.relationship: DevNormalizedRect(
        -.0045696203,
        .0307142857,
        .2769936709,
        .7261904762,
      ),
      DevLayoutElement.actions: DevNormalizedRect(
        .6574050633,
        .0078571429,
        .3352531646,
        .4342857143,
      ),
      DevLayoutElement.dialogue: DevNormalizedRect(.20, .7866666667, .60, .16),
      DevLayoutElement.characterArea: DevNormalizedRect(
        .1408860759,
        -.0066666667,
        .66,
        .96,
      ),
      DevLayoutElement.selector: DevNormalizedRect(
        -.0047468354,
        .0152380952,
        .20,
        1,
      ),
    },
  );

  DevSceneLayoutDraft copyWith({
    Map<DevLayoutElement, DevNormalizedRect>? elements,
    Map<String, DevCharacterVisualOverride>? characterOverrides,
    Map<DevLayoutElement, bool>? locks,
  }) => DevSceneLayoutDraft(
    elements: elements ?? this.elements,
    characterOverrides: characterOverrides ?? this.characterOverrides,
    locks: locks ?? this.locks,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'elements': {
      for (final entry in elements.entries)
        entry.key.name: entry.value.toJson(),
    },
    'characterOverrides': {
      for (final entry in characterOverrides.entries)
        entry.key: entry.value.toJson(),
    },
    'locks': {for (final entry in locks.entries) entry.key.name: entry.value},
  };
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
  factory DevSceneLayoutDraft.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    final raw = (json['elements'] as Map?)?.cast<String, dynamic>() ?? const {};
    final overrides =
        (json['characterOverrides'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final locks = (json['locks'] as Map?)?.cast<String, dynamic>() ?? const {};
    final defaults = currentDefaults().elements;
    return DevSceneLayoutDraft(
      elements: {
        for (final element in DevLayoutElement.values)
          element: raw[element.name] is Map
              ? DevNormalizedRect.fromJson(
                  (raw[element.name] as Map).cast<String, dynamic>(),
                )
              : defaults[element]!,
      },
      characterOverrides: {
        ...currentDefaults().characterOverrides,
        for (final entry in overrides.entries)
          if (entry.value is Map)
            entry.key: DevCharacterVisualOverride.fromJson(
              (entry.value as Map).cast<String, dynamic>(),
            ),
      },
      locks: {
        for (final element in DevLayoutElement.values)
          element: locks[element.name] == true,
      },
    );
  }
}

class DevSceneLayoutController extends ChangeNotifier {
  static const storageKey = 'projeto_conexoes.dev_layout_draft.v1';
  DevSceneLayoutDraft _saved = DevSceneLayoutDraft.currentDefaults();
  DevSceneLayoutDraft _draft = DevSceneLayoutDraft.currentDefaults();
  final List<DevSceneLayoutDraft> _undo = [];
  final List<DevSceneLayoutDraft> _redo = [];
  DevSceneLayoutDraft? _transactionStart;
  bool editorOpen = false;
  bool preview = false;
  bool dialogueExpanded = true;
  bool safeBounds = true;
  bool guides = true;
  DevSnap snap = DevSnap.eight;
  DevLayoutMode mode = DevLayoutMode.global;
  DevLayoutElement selected = DevLayoutElement.characterArea;
  String selectedCharacterId = 'roxanne';
  Size canvasSize = const Size(1366, 768);

  DevSceneLayoutDraft get draft => _draft;
  bool get dirty => _draft.encode() != _saved.encode();
  bool get hasCustomLayout =>
      _draft.encode() != DevSceneLayoutDraft.currentDefaults().encode();
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  DevDesktopBreakpoint breakpointFor(Size size) => switch (size.width) {
    < 1200 => DevDesktopBreakpoint.compact,
    < 1600 => DevDesktopBreakpoint.standard,
    < 2200 => DevDesktopBreakpoint.large,
    _ => DevDesktopBreakpoint.ultra,
  };
  DevCharacterVisualOverride overrideFor(String id) =>
      _draft.characterOverrides[id] ?? const DevCharacterVisualOverride();

  Future<void> load() async {
    try {
      final value = await SharedPreferencesAsync().getString(storageKey);
      if (value != null) {
        _saved = DevSceneLayoutDraft.decode(value);
        _draft = _saved;
      }
    } catch (_) {
      // Widget tests and disabled platforms may not register the async plugin.
      // The editor still works with an in-memory draft in that situation.
    }
    notifyListeners();
  }

  Future<void> save() async {
    try {
      await SharedPreferencesAsync().setString(storageKey, _draft.encode());
    } catch (_) {
      // Keep the active draft usable when persistence is unavailable.
    }
    _saved = _draft;
    notifyListeners();
  }

  String exportJson() => _draft.encode();
  void open() {
    editorOpen = true;
    preview = false;
    notifyListeners();
  }

  void selectMode(DevLayoutMode value) {
    mode = value;
    if (value == DevLayoutMode.character)
      selected = DevLayoutElement.characterArea;
    notifyListeners();
  }

  void selectElement(DevLayoutElement value) {
    selected = value;
    notifyListeners();
  }

  void selectCharacter(String value) {
    selectedCharacterId = value;
    notifyListeners();
  }

  void close() {
    editorOpen = false;
    preview = false;
    notifyListeners();
  }

  void setPreview(bool value) {
    preview = value;
    notifyListeners();
  }

  void discard() {
    _draft = _saved;
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }

  void resetAll() {
    _record();
    _draft = DevSceneLayoutDraft.currentDefaults();
    notifyListeners();
  }

  void resetSelected() {
    _record();
    if (mode == DevLayoutMode.character) {
      final map = {..._draft.characterOverrides}..remove(selectedCharacterId);
      _draft = _draft.copyWith(characterOverrides: map);
    } else {
      final map = {
        ..._draft.elements,
        selected: DevSceneLayoutDraft.currentDefaults().elements[selected]!,
      };
      _draft = _draft.copyWith(elements: map);
    }
    notifyListeners();
  }

  void setLock(DevLayoutElement element, bool value) {
    _draft = _draft.copyWith(locks: {..._draft.locks, element: value});
    notifyListeners();
  }

  void beginTransaction() => _transactionStart ??= _draft;
  void endTransaction() {
    final before = _transactionStart;
    _transactionStart = null;
    if (before != null && before.encode() != _draft.encode()) {
      _undo.add(before);
      if (_undo.length > 50) _undo.removeAt(0);
      _redo.clear();
    }
    notifyListeners();
  }

  void updateElement(DevLayoutElement element, DevNormalizedRect value) {
    if (_draft.locks[element] == true) return;
    if (_transactionStart == null) _record();
    _draft = _draft.copyWith(
      elements: {..._draft.elements, element: value.normalized()},
    );
    notifyListeners();
  }

  void updateCharacter({double? scale, double? offsetX, double? offsetY}) {
    if (_transactionStart == null) _record();
    _draft = _draft.copyWith(
      characterOverrides: {
        ..._draft.characterOverrides,
        selectedCharacterId: overrideFor(
          selectedCharacterId,
        ).copyWith(scaleMultiplier: scale, offsetX: offsetX, offsetY: offsetY),
      },
    );
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_draft);
    _draft = _undo.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_draft);
    _draft = _redo.removeLast();
    notifyListeners();
  }

  void _record() {
    _undo.add(_draft);
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
  }
}
