import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/database/database.dart';
import 'package:fluxedit/core/database/database_provider.dart';
import 'package:fluxedit/core/timeline/keyframe_model.dart';

final keyframeRepositoryProvider = Provider<KeyframeRepository>(
  (ref) => KeyframeRepository(ref.watch(databaseProvider)),
);

class KeyframeRepository {
  KeyframeRepository(this._db);

  final AppDatabase _db;

  Future<List<KeyframeModel>> getKeyframesForClip(String clipId) async {
    final rows = await (_db.select(_db.keyframes)
          ..where((t) => t.clipId.equals(clipId))
          ..orderBy([(t) => OrderingTerm.asc(t.timeUs)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<KeyframeModel>> getKeyframesForParameter(
    String clipId,
    String parameterId,
  ) async {
    final rows = await (_db.select(_db.keyframes)
          ..where(
            (t) =>
                t.clipId.equals(clipId) & t.parameterId.equals(parameterId),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timeUs)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> saveKeyframe(String clipId, KeyframeModel kf) async {
    await _db.into(_db.keyframes).insertOnConflictUpdate(
      KeyframesCompanion(
        id: Value(kf.id),
        clipId: Value(clipId),
        parameterId: Value(kf.parameterId),
        timeUs: Value(kf.time.inMicroseconds),
        value: Value(kf.value),
        interpolation: Value(kf.interpolation.name),
        inTangentX: Value(kf.inTangentX),
        inTangentY: Value(kf.inTangentY),
        outTangentX: Value(kf.outTangentX),
        outTangentY: Value(kf.outTangentY),
      ),
    );
  }

  Future<void> deleteKeyframe(String id) async {
    await (_db.delete(_db.keyframes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteKeyframesForClip(String clipId) async {
    await (_db.delete(_db.keyframes)..where((t) => t.clipId.equals(clipId)))
        .go();
  }

  KeyframeModel _fromRow(Keyframe row) {
    return KeyframeModel(
      id: row.id,
      parameterId: row.parameterId,
      time: Duration(microseconds: row.timeUs),
      value: row.value,
      interpolation: KeyframeInterpolation.values.firstWhere(
        (e) => e.name == row.interpolation,
        orElse: () => KeyframeInterpolation.linear,
      ),
      inTangentX: row.inTangentX,
      inTangentY: row.inTangentY,
      outTangentX: row.outTangentX,
      outTangentY: row.outTangentY,
    );
  }
}
