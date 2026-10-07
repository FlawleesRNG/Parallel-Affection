import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/idle_rules.dart';
import 'package:projeto_conexoes/core/job_requirement_evaluator.dart';
import 'package:projeto_conexoes/data/character_routes.dart';
import 'package:projeto_conexoes/data/character_unlocks.dart';
import 'package:projeto_conexoes/data/date_locations.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';

class _MemoryStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  group('progression reachability', () {
    test('radio assistant usa exatamente o gate alcançável da Roxanne', () {
      expect(_radioUnlocked(roxanneStage: 0, oratoria: 5, musica: 4), isFalse);
      expect(_radioUnlocked(roxanneStage: 1, oratoria: 4, musica: 4), isFalse);
      expect(_radioUnlocked(roxanneStage: 1, oratoria: 5, musica: 3), isFalse);
      expect(_radioUnlocked(roxanneStage: 1, oratoria: 5, musica: 4), isTrue);
      expect(_radioUnlocked(roxanneStage: 2, oratoria: 5, musica: 4), isTrue);
    });

    test('catálogos de rotas só referenciam gifts e dates existentes', () {
      final giftIds = IdleBalance.gifts.map((gift) => gift.id).toSet();
      final jobIds = IdleBalance.jobs.map((job) => job.id).toSet();
      final hobbyIds = IdleBalance.hobbies.map((hobby) => hobby.id).toSet();
      final dateIds = DateLocationCatalog.locations
          .map((date) => date.id)
          .toSet();

      for (final route in CharacterRouteCatalog.all) {
        expect(route.routeContentReady, isTrue, reason: route.characterId);
        for (final stage in route.stageDefinitions) {
          for (final requirement in stage.requirements) {
            switch (requirement.type) {
              case CharacterRouteRequirementType.giftDelivered:
                expect(giftIds, contains(requirement.targetId));
              case CharacterRouteRequirementType.jobLevel:
                expect(jobIds, contains(requirement.targetId));
              case CharacterRouteRequirementType.hobbyLevel:
                expect(hobbyIds, contains(requirement.targetId));
              case CharacterRouteRequirementType.eventCompleted:
              case CharacterRouteRequirementType.money:
                break;
            }
            expect(requirement.isResolved, isTrue, reason: route.characterId);
          }
        }
        for (var stage = 0; stage < 10; stage++) {
          for (final requirement in CharacterDateRequirements.forStage(
            route.characterId,
            stage,
          )) {
            expect(dateIds, contains(requirement.locationId));
          }
        }
      }
    });

    test(
      'novo jogo possui caminho estrutural até Amor verdadeiro nas quatro rotas',
      () {
        var state = IdleState.fresh().copyWith(
          money: 999999999,
          totalMoneyEarned: 999999999,
          dateProgressByCharacter: {
            for (final character in PlayableCharacterCatalog.all)
              character.id: {
                for (final location in DateLocationCatalog.locations)
                  location.id: 99,
              },
          },
        );

        for (var pass = 0; pass < 100; pass++) {
          final previous = state;
          state = _unlockHobbies(state);
          state = _unlockJobs(state);
          state = _unlockCharacters(state);
          state = _satisfyCurrentRouteRequirements(state);
          state = _advanceEveryAvailableRoute(state);
          if (_allRoutesCompleted(state)) break;
          expect(state, isNot(same(previous)));
        }

        for (final character in PlayableCharacterCatalog.all) {
          final progress = state.characters[character.id]!;
          expect(progress.unlocked, isTrue, reason: character.id);
          expect(progress.stage, 9, reason: character.id);
        }
      },
    );

    test(
      'save existente reavalia radio assistant imediatamente ao carregar',
      () async {
        final stored = IdleState.fresh().copyWith(
          hobbies: {
            ...IdleState.fresh().hobbies,
            'oratoria': const ActivityProgress(level: 5, isUnlocked: true),
            'musica': const ActivityProgress(level: 4, isUnlocked: true),
          },
          characters: {
            ...IdleState.fresh().characters,
            PlayableCharacterIds.roxanne: const CharacterProgress(
              unlocked: true,
              stage: 1,
            ),
          },
        );
        final storage = _MemoryStorage()..value = stored.encode();
        final controller = GameController(storage);
        addTearDown(controller.dispose);

        await controller.initialize();

        expect(controller.state.jobs['radio_assistant']!.isUnlocked, isTrue);
      },
    );
  });
}

bool _radioUnlocked({
  required int roxanneStage,
  required int oratoria,
  required int musica,
}) {
  final fresh = IdleState.fresh();
  final state = fresh.copyWith(
    hobbies: {
      ...fresh.hobbies,
      'oratoria': ActivityProgress(level: oratoria),
      'musica': ActivityProgress(level: musica),
    },
    characters: {
      ...fresh.characters,
      PlayableCharacterIds.roxanne: CharacterProgress(
        unlocked: true,
        stage: roxanneStage,
      ),
    },
  );
  return JobRequirementEvaluator.isUnlocked(
    state,
    IdleBalance.job('radio_assistant'),
  );
}

IdleState _unlockHobbies(IdleState state) {
  var next = state;
  for (final hobby in IdleBalance.hobbies) {
    if (!IdleRules.hobbyUnlocked(next, hobby.id)) continue;
    final current = next.hobbies[hobby.id] ?? const ActivityProgress();
    next = next.copyWith(
      hobbies: {
        ...next.hobbies,
        hobby.id: current.copyWith(level: hobby.maximumLevel, isUnlocked: true),
      },
    );
  }
  return next;
}

IdleState _unlockJobs(IdleState state) {
  var next = state;
  for (final job in IdleBalance.jobs) {
    if (!JobRequirementEvaluator.isUnlocked(next, job)) continue;
    final current = next.jobs[job.id] ?? const ActivityProgress();
    next = next.copyWith(
      jobs: {
        ...next.jobs,
        job.id: current.copyWith(level: job.maximumLevel, isUnlocked: true),
      },
    );
  }
  return next;
}

IdleState _unlockCharacters(IdleState state) {
  final stages = {
    for (final entry in state.characters.entries) entry.key: entry.value.stage,
  };
  final characters = {...state.characters};
  for (final definition in CharacterUnlockCatalog.definitions) {
    if (CharacterUnlockCatalog.isSatisfiedBy(definition, stages)) {
      final current =
          characters[definition.characterId] ?? const CharacterProgress();
      characters[definition.characterId] = current.copyWith(unlocked: true);
    }
  }
  return state.copyWith(characters: characters);
}

IdleState _satisfyCurrentRouteRequirements(IdleState state) {
  final characters = {...state.characters};
  for (final route in CharacterRouteCatalog.all) {
    final current = characters[route.characterId];
    if (current == null || !current.unlocked || current.stage >= 9) continue;
    final stage = route.stageFor(current.stage);
    final deliveries = {...current.giftDeliveries};
    final scenes = {...current.scenes};
    for (final requirement in stage.requirements) {
      switch (requirement.type) {
        case CharacterRouteRequirementType.giftDelivered:
          deliveries[requirement.targetId] = requirement.requiredValue!;
        case CharacterRouteRequirementType.eventCompleted:
          scenes.add(requirement.targetId);
        case CharacterRouteRequirementType.hobbyLevel:
        case CharacterRouteRequirementType.jobLevel:
        case CharacterRouteRequirementType.money:
          break;
      }
    }
    characters[route.characterId] = current.copyWith(
      affection: stage.affectionRequired,
      giftDeliveries: deliveries,
      scenes: scenes,
    );
  }
  return state.copyWith(characters: characters);
}

IdleState _advanceEveryAvailableRoute(IdleState state) {
  final characters = {...state.characters};
  for (final route in CharacterRouteCatalog.all) {
    final current = characters[route.characterId];
    if (current == null || current.stage >= 9) continue;
    if (IdleRules.canAdvance(
      state.copyWith(characters: characters),
      route.characterId,
    )) {
      characters[route.characterId] = current.copyWith(
        stage: current.stage + 1,
      );
    }
  }
  return state.copyWith(characters: characters);
}

bool _allRoutesCompleted(IdleState state) => PlayableCharacterCatalog.all.every(
  (character) => state.characters[character.id]?.stage == 9,
);
