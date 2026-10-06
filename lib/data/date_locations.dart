import 'package:flutter/widgets.dart';

/// Central catalogue for the timed date activity. Assets are intentionally
/// optional: the UI has a Flutter fallback until the illustrated locations are
/// supplied.
class DateLocationDefinition {
  const DateLocationDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.baseDuration,
    required this.icon,
    this.imageAsset,
  });

  final String id;
  final String name;
  final String description;
  final int baseCost;
  final Duration baseDuration;
  final IconData icon;
  final String? imageAsset;
}

class DateRequirement {
  const DateRequirement(this.locationId, this.requiredCount);

  final String locationId;
  final int requiredCount;
}

abstract final class DateLocationCatalog {
  static const locations = <DateLocationDefinition>[
    DateLocationDefinition(
      id: 'cafe',
      name: 'Café',
      description:
          'Um encontro tranquilo para conversar e passar um tempo juntos.',
      baseCost: 250,
      baseDuration: Duration(seconds: 5),
      icon: IconData(0xe0b0, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_cafe.png',
    ),
    DateLocationDefinition(
      id: 'park',
      name: 'Parque',
      description: 'Um passeio leve ao ar livre.',
      baseCost: 1000,
      baseDuration: Duration(seconds: 8),
      icon: IconData(0xe4f1, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_park.png',
    ),
    DateLocationDefinition(
      id: 'cinema',
      name: 'Cinema',
      description: 'Um tempo juntos assistindo a alguma coisa e relaxando.',
      baseCost: 5000,
      baseDuration: Duration(seconds: 12),
      icon: IconData(0xe40f, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_cinema.png',
    ),
    DateLocationDefinition(
      id: 'arcade',
      name: 'Arcade',
      description: 'Jogos, competição e um pouco de diversão.',
      baseCost: 25000,
      baseDuration: Duration(seconds: 15),
      icon: IconData(0xe30f, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_arcade.png',
    ),
    DateLocationDefinition(
      id: 'restaurant',
      name: 'Restaurante',
      description: 'Um encontro mais especial em um bom restaurante.',
      baseCost: 100000,
      baseDuration: Duration(seconds: 20),
      icon: IconData(0xe56c, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_restaurant.png',
    ),
    DateLocationDefinition(
      id: 'amusement_park',
      name: 'Parque de Diversões',
      description: 'Um passeio maior, cheio de atrações e lembranças.',
      baseCost: 500000,
      baseDuration: Duration(seconds: 30),
      icon: IconData(0xe4de, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_amusement_park.png',
    ),
    DateLocationDefinition(
      id: 'night_viewpoint',
      name: 'Mirante Noturno',
      description: 'Um encontro tranquilo com a cidade iluminada ao fundo.',
      baseCost: 2000000,
      baseDuration: Duration(seconds: 45),
      icon: IconData(0xe3a0, fontFamily: 'MaterialIcons'),
      imageAsset: 'assets/images/dates/locations/date_night_viewpoint.png',
    ),
  ];

  static DateLocationDefinition? maybeById(String id) {
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  static DateLocationDefinition byId(String id) =>
      maybeById(id) ?? locations.first;

  static String preferredImageAsset(String characterId, String locationId) =>
      'assets/images/characters/$characterId/dates/$locationId.png';
}
