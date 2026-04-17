import 'package:flutter/material.dart';

/// Master list of every icon used by the Tracker / Todo presets & picker.
/// Keep everything referenced as const IconData so the Flutter icon
/// tree-shaker keeps the glyphs, and dynamic codePoints resolve back
/// to the original const value (important on web where arbitrary
/// IconData(codePoint) may fail to render).
const List<IconData> _iconCatalog = <IconData>[
  // General
  Icons.check_circle_rounded,
  Icons.circle_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.auto_awesome_rounded,
  Icons.mood_rounded,

  // Body / health
  Icons.water_drop_rounded,
  Icons.coffee_rounded,
  Icons.fitness_center_rounded,
  Icons.smoking_rooms_rounded,
  Icons.local_fire_department_rounded,
  Icons.medication_rounded,
  Icons.self_improvement_rounded,
  Icons.accessibility_new_rounded,
  Icons.sports_gymnastics_rounded,
  Icons.directions_walk_rounded,
  Icons.brush_rounded,

  // Time / productivity
  Icons.timer_rounded,
  Icons.book_rounded,
  Icons.edit_note_rounded,
  Icons.school_rounded,
  Icons.nightlight_round,
  Icons.wb_sunny_rounded,

  // Places
  Icons.home_rounded,
  Icons.work_rounded,
  Icons.pets_rounded,
];

final Map<int, IconData> _byCode = {
  for (final i in _iconCatalog) i.codePoint: i,
};

IconData iconFromCode(int code) =>
    _byCode[code] ?? Icons.circle_rounded;
