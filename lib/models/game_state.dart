import 'dart:convert';

const relationshipStages = [
  'Desconhecida',
  'Conhecida',
  'Colega',
  'Amiga',
  'Pessoa especial',
];

class LiaProgress {
  const LiaProgress({
    this.affinity = 0,
    this.trust = 0,
    this.interest = 0,
    this.respect = 0,
    this.stage = 0,
    this.completedDialogues = const {},
    this.choices = const {},
    this.unlockedScenes = const {},
    this.chocolatesGiven = 0,
  });

  final int affinity;
  final int trust;
  final int interest;
  final int respect;
  final int stage;
  final Set<String> completedDialogues;
  final Map<String, String> choices;
  final Set<String> unlockedScenes;
  final int chocolatesGiven;

  String get stageName => relationshipStages[stage];
  int get completion =>
      ((affinity + trust + interest + respect).clamp(0, 40) * 1.25 +
              completedDialogues.length * 10 +
              unlockedScenes.length * 10)
          .round()
          .clamp(0, 100);

  LiaProgress copyWith({
    int? affinity,
    int? trust,
    int? interest,
    int? respect,
    int? stage,
    Set<String>? completedDialogues,
    Map<String, String>? choices,
    Set<String>? unlockedScenes,
    int? chocolatesGiven,
  }) => LiaProgress(
    affinity: affinity ?? this.affinity,
    trust: trust ?? this.trust,
    interest: interest ?? this.interest,
    respect: respect ?? this.respect,
    stage: stage ?? this.stage,
    completedDialogues: completedDialogues ?? this.completedDialogues,
    choices: choices ?? this.choices,
    unlockedScenes: unlockedScenes ?? this.unlockedScenes,
    chocolatesGiven: chocolatesGiven ?? this.chocolatesGiven,
  );

  Map<String, dynamic> toJson() => {
    'affinity': affinity,
    'trust': trust,
    'interest': interest,
    'respect': respect,
    'stage': stage,
    'completedDialogues': completedDialogues.toList(),
    'choices': choices,
    'unlockedScenes': unlockedScenes.toList(),
    'chocolatesGiven': chocolatesGiven,
  };

  factory LiaProgress.fromJson(Map<String, dynamic> json) => LiaProgress(
    affinity: json['affinity'] as int? ?? 0,
    trust: json['trust'] as int? ?? 0,
    interest: json['interest'] as int? ?? 0,
    respect: json['respect'] as int? ?? 0,
    stage: json['stage'] as int? ?? 0,
    completedDialogues: (json['completedDialogues'] as List<dynamic>? ?? [])
        .cast<String>()
        .toSet(),
    choices: (json['choices'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, value as String),
    ),
    unlockedScenes: (json['unlockedScenes'] as List<dynamic>? ?? [])
        .cast<String>()
        .toSet(),
    chocolatesGiven: json['chocolatesGiven'] as int? ?? 0,
  );
}

class GameState {
  const GameState({
    this.day = 1,
    this.money = 100,
    this.energy = 10,
    this.charisma = 1,
    this.empathy = 1,
    this.courage = 1,
    this.lia = const LiaProgress(),
  });

  final int day;
  final int money;
  final int energy;
  final int charisma;
  final int empathy;
  final int courage;
  final LiaProgress lia;

  int valueFor(String key) => switch (key) {
    'charisma' || 'carisma' => charisma,
    'empathy' || 'empatia' => empathy,
    'courage' || 'coragem' => courage,
    _ => 0,
  };

  GameState copyWith({
    int? day,
    int? money,
    int? energy,
    int? charisma,
    int? empathy,
    int? courage,
    LiaProgress? lia,
  }) => GameState(
    day: day ?? this.day,
    money: money ?? this.money,
    energy: energy ?? this.energy,
    charisma: charisma ?? this.charisma,
    empathy: empathy ?? this.empathy,
    courage: courage ?? this.courage,
    lia: lia ?? this.lia,
  );

  String encode() => jsonEncode({
    'day': day,
    'money': money,
    'energy': energy,
    'charisma': charisma,
    'empathy': empathy,
    'courage': courage,
    'lia': lia.toJson(),
  });

  factory GameState.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return GameState(
      day: json['day'] as int? ?? 1,
      money: json['money'] as int? ?? 100,
      energy: json['energy'] as int? ?? 10,
      charisma: json['charisma'] as int? ?? 1,
      empathy: json['empathy'] as int? ?? 1,
      courage: json['courage'] as int? ?? 1,
      lia: LiaProgress.fromJson(json['lia'] as Map<String, dynamic>? ?? {}),
    );
  }
}
