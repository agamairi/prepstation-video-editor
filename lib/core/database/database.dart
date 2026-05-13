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
    ProjectSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Raw SQL — avoids stale generated-type references before build_runner.
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_text TEXT',
        );
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_font_size REAL NOT NULL DEFAULT 48.0',
        );
        // 0xFFFFFFFF = 4294967295 (white)
        await customStatement(
          'ALTER TABLE clips ADD COLUMN title_color_value INTEGER NOT NULL DEFAULT 4294967295',
        );
        await customStatement(
          "ALTER TABLE clips ADD COLUMN title_alignment TEXT NOT NULL DEFAULT 'center'",
        );
        // 0xFF000000 = -16777216 as signed 64-bit (black)
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
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fluxedit_db');
  }
}
