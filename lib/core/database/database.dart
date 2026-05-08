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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {},
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fluxedit_db');
  }
}
