import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:fluxedit/core/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Projects,
    MediaAssets,
    Tracks,
    Clips,
    Keyframes,
    EffectInstances,
    Markers,
    ProjectSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_text TEXT',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_font_size REAL NOT NULL DEFAULT 48.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_color_value INTEGER NOT NULL DEFAULT 4294967295',
        );
        await customStatement(
          "ALTER TABLE clips ADD COLUMN title_alignment TEXT NOT NULL DEFAULT 'center'",
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN card_color_value INTEGER NOT NULL DEFAULT -16777216',
        );
      }
      if (from < 3) {
        await customStatement(
          "ALTER TABLE clips ADD COLUMN font_family TEXT NOT NULL DEFAULT 'Roboto'",
        );
        await customStatement(
          "ALTER TABLE clips ADD COLUMN text_animation_type TEXT NOT NULL DEFAULT 'none'",
        );
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE clips ADD COLUMN text_animation_duration_ms INTEGER NOT NULL DEFAULT 600',
        );
      }
      if (from < 5) {
        // Transform columns
        await customStatement(
          'ALTER TABLE clips ADD COLUMN pos_x REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN pos_y REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN scale_x REAL NOT NULL DEFAULT 1.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN scale_y REAL NOT NULL DEFAULT 1.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN rotation REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN anchor_x REAL NOT NULL DEFAULT 0.5',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN anchor_y REAL NOT NULL DEFAULT 0.5',
        );
        // Crop columns
        await customStatement(
          'ALTER TABLE clips ADD COLUMN crop_left REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN crop_right REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN crop_top REAL NOT NULL DEFAULT 0.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN crop_bottom REAL NOT NULL DEFAULT 0.0',
        );
        // Clip flags
        await customStatement(
          'ALTER TABLE clips ADD COLUMN is_reversed INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN is_frozen INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN flip_horizontal INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN flip_vertical INTEGER NOT NULL DEFAULT 0',
        );
        // Per-clip volume
        await customStatement(
          'ALTER TABLE clips ADD COLUMN volume REAL NOT NULL DEFAULT 1.0',
        );
        // Markers table
        await customStatement('''
          CREATE TABLE IF NOT EXISTS markers (
            id TEXT NOT NULL PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
            time_us INTEGER NOT NULL,
            name TEXT NOT NULL DEFAULT '',
            note TEXT NOT NULL DEFAULT '',
            color TEXT NOT NULL DEFAULT 'blue',
            duration_us INTEGER NOT NULL DEFAULT 0
          )
        ''');
      }
      if (from < 6) {
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_enabled INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          "ALTER TABLE clips ADD COLUMN isolation_mode TEXT NOT NULL DEFAULT 'transparent'",
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_color_value INTEGER NOT NULL DEFAULT ${0xFF00FF00}',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_blur_radius REAL NOT NULL DEFAULT 20.0',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_mask_path TEXT',
        );
      }
      if (from < 7) {
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_selection_left REAL',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_selection_top REAL',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_selection_right REAL',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN isolation_selection_bottom REAL',
        );
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fluxedit_db');
  }
}
