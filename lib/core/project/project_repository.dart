import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/database/database.dart';
import 'package:prepstation/core/database/database_provider.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/composition_model.dart';
import 'package:prepstation/core/timeline/marker_model.dart';
import 'package:prepstation/core/timeline/track_model.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(databaseProvider)),
);

class ProjectRepository {
  ProjectRepository(this._db);

  final AppDatabase _db;

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<List<ProjectModel>> getAllProjects() async {
    final rows = await _db.select(_db.projects).get();
    return rows.map(_projectFromRow).toList();
  }

  Future<ProjectModel?> getProject(String id) async {
    final row = await (_db.select(_db.projects)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _projectFromRow(row) : null;
  }

  Future<void> saveProject(ProjectModel project) async {
    await _db.into(_db.projects).insertOnConflictUpdate(
      ProjectsCompanion(
        id: Value(project.id),
        name: Value(project.name),
        filePath: Value(project.filePath),
        description: Value(project.description),
        version: Value(project.version),
        compWidth: Value(project.composition.width),
        compHeight: Value(project.composition.height),
        compFrameRate: Value(project.composition.frameRate),
        compDurationUs: Value(
          project.composition.duration.inMicroseconds,
        ),
        compBackgroundColor: Value(project.composition.backgroundColor),
        dateCreated: Value(project.dateCreated),
        dateModified: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProject(String id) async {
    await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
  }

  // ── Media Assets ──────────────────────────────────────────────────────────

  Future<List<MediaAsset>> getMediaAssets(String projectId) async {
    final rows = await (_db.select(_db.mediaAssets)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.dateAdded)]))
        .get();
    return rows.map(_mediaAssetFromRow).toList();
  }

  Future<MediaAsset?> getMediaAsset(String id) async {
    final row = await (_db.select(_db.mediaAssets)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _mediaAssetFromRow(row) : null;
  }

  Future<void> saveMediaAsset(MediaAsset asset) async {
    await _db.into(_db.mediaAssets).insertOnConflictUpdate(
      MediaAssetsCompanion(
        id: Value(asset.id),
        projectId: Value(asset.projectId),
        filePath: Value(asset.filePath),
        name: Value(asset.name),
        type: Value(asset.type),
        durationUs: Value(asset.duration.inMicroseconds),
        width: Value(asset.width),
        height: Value(asset.height),
        frameRate: Value(asset.frameRate),
        sampleRate: Value(asset.sampleRate),
        channels: Value(asset.channels),
        videoCodec: Value(asset.videoCodec),
        audioCodec: Value(asset.audioCodec),
        bitRate: Value(asset.bitRate),
        fileSize: Value(asset.fileSize),
        colorSpace: Value(asset.colorSpace),
        proxyPath: Value(asset.proxyPath),
        thumbnailPath: Value(asset.thumbnailPath),
        binId: Value(asset.binId),
        dateAdded: Value(asset.dateAdded),
      ),
    );
  }

  Future<void> deleteMediaAsset(String id) async {
    await (_db.delete(_db.mediaAssets)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateThumbnailPath(String assetId, String thumbnailPath) async {
    await (_db.update(_db.mediaAssets)..where((t) => t.id.equals(assetId)))
        .write(MediaAssetsCompanion(thumbnailPath: Value(thumbnailPath)));
  }

  Future<void> updateProxyPath(String assetId, String proxyPath) async {
    await (_db.update(_db.mediaAssets)..where((t) => t.id.equals(assetId)))
        .write(MediaAssetsCompanion(proxyPath: Value(proxyPath)));
  }

  // ── Tracks ────────────────────────────────────────────────────────────────

  Future<List<TrackModel>> getTracks(String projectId) async {
    final rows = await (_db.select(_db.tracks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.trackIndex)]))
        .get();
    return rows.map(_trackFromRow).toList();
  }

  Future<void> saveTrack(TrackModel track) async {
    await _db.into(_db.tracks).insertOnConflictUpdate(
      TracksCompanion(
        id: Value(track.id),
        projectId: Value(track.projectId),
        type: Value(track.type.name),
        trackIndex: Value(track.index),
        name: Value(track.name),
        height: Value(track.height),
        isMuted: Value(track.isMuted),
        isSoloed: Value(track.isSoloed),
        isLocked: Value(track.isLocked),
        isVisible: Value(track.isVisible),
        volume: Value(track.volume),
        pan: Value(track.pan),
      ),
    );
  }

  Future<void> deleteTrack(String id) async {
    await (_db.delete(_db.tracks)..where((t) => t.id.equals(id))).go();
  }

  // ── Clips ─────────────────────────────────────────────────────────────────

  Future<List<ClipModel>> getClips(String trackId) async {
    final rows = await (_db.select(_db.clips)
          ..where((t) => t.trackId.equals(trackId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.startOnTimelineUs),
          ]))
        .get();
    return rows.map(_clipFromRow).toList();
  }

  Future<List<ClipModel>> getClipsForProject(String projectId) async {
    final tracks = await getTracks(projectId);
    final clips = <ClipModel>[];
    for (final track in tracks) {
      clips.addAll(await getClips(track.id));
    }
    return clips;
  }

  Future<void> saveClip(ClipModel clip) async {
    await _db.into(_db.clips).insertOnConflictUpdate(
      ClipsCompanion(
        id: Value(clip.id),
        trackId: Value(clip.trackId),
        mediaId: Value(clip.mediaId),
        type: Value(clip.type.name),
        startOnTimelineUs: Value(clip.startOnTimeline.inMicroseconds),
        endOnTimelineUs: Value(clip.endOnTimeline.inMicroseconds),
        mediaInPointUs: Value(clip.mediaInPoint.inMicroseconds),
        mediaOutPointUs: Value(clip.mediaOutPoint.inMicroseconds),
        speed: Value(clip.speed),
        opacity: Value(clip.opacity),
        blendMode: Value(clip.blendMode.name),
        labelColorIndex: Value(clip.labelColorIndex),
        isVideoLinked: Value(clip.isVideoLinked),
        isAudioLinked: Value(clip.isAudioLinked),
        isMuted: Value(clip.isMuted),
        isLocked: Value(clip.isLocked),
        name: Value(clip.name),
        transitionInId: Value(clip.transitionInId),
        transitionOutId: Value(clip.transitionOutId),
        transitionInDurationUs: Value(
          clip.transitionInDuration.inMicroseconds,
        ),
        transitionOutDurationUs: Value(
          clip.transitionOutDuration.inMicroseconds,
        ),
        titleText: Value(clip.titleText),
        titleFontSize: Value(clip.titleFontSize),
        titleColorValue: Value(clip.titleColorValue),
        titleAlignment: Value(clip.titleAlignment),
        cardColorValue: Value(clip.cardColorValue),
        fontFamily: Value(clip.fontFamily),
        textAnimationType: Value(clip.textAnimationType.name),
        textAnimationDurationMs: Value(clip.textAnimationDurationMs),
        posX: Value(clip.posX),
        posY: Value(clip.posY),
        scaleX: Value(clip.scaleX),
        scaleY: Value(clip.scaleY),
        rotation: Value(clip.rotation),
        anchorX: Value(clip.anchorX),
        anchorY: Value(clip.anchorY),
        cropLeft: Value(clip.cropLeft),
        cropRight: Value(clip.cropRight),
        cropTop: Value(clip.cropTop),
        cropBottom: Value(clip.cropBottom),
        isReversed: Value(clip.isReversed),
        isFrozen: Value(clip.isFrozen),
        flipHorizontal: Value(clip.flipHorizontal),
        flipVertical: Value(clip.flipVertical),
        volume: Value(clip.volume),
        isolationEnabled: Value(clip.isolationEnabled),
        isolationMode: Value(clip.isolationMode.name),
        isolationColorValue: Value(clip.isolationColorValue),
        isolationBlurRadius: Value(clip.isolationBlurRadius),
        isolationEdgeFeather: Value(clip.isolationEdgeFeather),
        isolationMaskPath: Value(clip.isolationMaskPath),
        isolationSelectionLeft: Value(clip.isolationSelectionLeft),
        isolationSelectionTop: Value(clip.isolationSelectionTop),
        isolationSelectionRight: Value(clip.isolationSelectionRight),
        isolationSelectionBottom: Value(clip.isolationSelectionBottom),
      ),
    );
  }

  Future<void> deleteClip(String id) async {
    await (_db.delete(_db.clips)..where((t) => t.id.equals(id))).go();
  }

  // ── Effects ───────────────────────────────────────────────────────────────

  Future<List<EffectInstance>> getEffectsForClip(String clipId) async {
    final rows = await (_db.select(_db.effectInstances)
          ..where((t) => t.clipId.equals(clipId))
          ..orderBy([(t) => OrderingTerm.asc(t.stackIndex)]))
        .get();
    return rows.map(_effectFromRow).toList();
  }

  Future<void> saveEffect(EffectInstance effect) async {
    await _db.into(_db.effectInstances).insertOnConflictUpdate(
      EffectInstancesCompanion(
        id: Value(effect.id),
        clipId: Value(effect.clipId),
        effectType: Value(effect.type.name),
        stackIndex: Value(effect.stackIndex),
        isEnabled: Value(effect.isEnabled),
        parametersJson: Value(effect.parametersToJson()),
      ),
    );
  }

  Future<void> deleteEffect(String id) async {
    await (_db.delete(_db.effectInstances)..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Markers ──────────────────────────────────────────────────────────────

  Future<List<MarkerModel>> getMarkers(String projectId) async {
    final rows = await (_db.select(_db.markers)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.timeUs)]))
        .get();
    return rows.map(_markerFromRow).toList();
  }

  Future<void> saveMarker(MarkerModel marker) async {
    await _db.into(_db.markers).insertOnConflictUpdate(
      MarkersCompanion(
        id: Value(marker.id),
        projectId: Value(marker.projectId),
        timeUs: Value(marker.time.inMicroseconds),
        name: Value(marker.name),
        note: Value(marker.note),
        color: Value(marker.color.name),
        durationUs: Value(marker.durationUs),
      ),
    );
  }

  Future<void> deleteMarker(String id) async {
    await (_db.delete(_db.markers)..where((t) => t.id.equals(id))).go();
  }

  // ── Private converters ────────────────────────────────────────────────────

  ProjectModel _projectFromRow(Project row) {
    return ProjectModel(
      id: row.id,
      name: row.name,
      filePath: row.filePath,
      description: row.description,
      version: row.version,
      composition: CompositionModel(
        id: 'comp_${row.id}',
        name: 'Main Composition',
        width: row.compWidth,
        height: row.compHeight,
        frameRate: row.compFrameRate,
        duration: Duration(microseconds: row.compDurationUs),
        backgroundColor: row.compBackgroundColor,
      ),
      dateCreated: row.dateCreated,
      dateModified: row.dateModified,
    );
  }

  MediaAsset _mediaAssetFromRow(MediaAssetRow row) {
    return MediaAsset(
      id: row.id,
      projectId: row.projectId,
      filePath: row.filePath,
      name: row.name,
      type: row.type,
      duration: Duration(microseconds: row.durationUs),
      width: row.width,
      height: row.height,
      frameRate: row.frameRate,
      sampleRate: row.sampleRate,
      channels: row.channels,
      videoCodec: row.videoCodec,
      audioCodec: row.audioCodec,
      bitRate: row.bitRate,
      fileSize: row.fileSize,
      colorSpace: row.colorSpace,
      proxyPath: row.proxyPath,
      thumbnailPath: row.thumbnailPath,
      binId: row.binId,
      dateAdded: row.dateAdded,
    );
  }

  TrackModel _trackFromRow(Track row) {
    return TrackModel(
      id: row.id,
      projectId: row.projectId,
      type: TrackType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => TrackType.video,
      ),
      index: row.trackIndex,
      name: row.name,
      height: row.height,
      isMuted: row.isMuted,
      isSoloed: row.isSoloed,
      isLocked: row.isLocked,
      isVisible: row.isVisible,
      volume: row.volume,
      pan: row.pan,
    );
  }

  EffectInstance _effectFromRow(EffectInstanceRow row) {
    return EffectInstance(
      id: row.id,
      clipId: row.clipId,
      type: EffectType.values.firstWhere(
        (e) => e.name == row.effectType,
        orElse: () => EffectType.colorCorrection,
      ),
      stackIndex: row.stackIndex,
      isEnabled: row.isEnabled,
      parameters: EffectInstance.parametersFromJson(row.parametersJson),
    );
  }

  ClipModel _clipFromRow(Clip row) {
    return ClipModel(
      id: row.id,
      trackId: row.trackId,
      mediaId: row.mediaId,
      type: ClipType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => ClipType.video,
      ),
      startOnTimeline: Duration(microseconds: row.startOnTimelineUs),
      endOnTimeline: Duration(microseconds: row.endOnTimelineUs),
      mediaInPoint: Duration(microseconds: row.mediaInPointUs),
      mediaOutPoint: Duration(microseconds: row.mediaOutPointUs),
      speed: row.speed,
      opacity: row.opacity,
      blendMode: BlendMode2.values.firstWhere(
        (e) => e.name == row.blendMode,
        orElse: () => BlendMode2.normal,
      ),
      labelColorIndex: row.labelColorIndex,
      isVideoLinked: row.isVideoLinked,
      isAudioLinked: row.isAudioLinked,
      isMuted: row.isMuted,
      isLocked: row.isLocked,
      name: row.name,
      transitionInId: row.transitionInId,
      transitionOutId: row.transitionOutId,
      transitionInDuration: Duration(
        microseconds: row.transitionInDurationUs,
      ),
      transitionOutDuration: Duration(
        microseconds: row.transitionOutDurationUs,
      ),
      titleText: row.titleText,
      titleFontSize: row.titleFontSize,
      titleColorValue: row.titleColorValue,
      titleAlignment: row.titleAlignment,
      cardColorValue: row.cardColorValue,
      fontFamily: row.fontFamily,
      textAnimationType: TextAnimationType.fromId(row.textAnimationType),
      textAnimationDurationMs: row.textAnimationDurationMs,
      posX: row.posX,
      posY: row.posY,
      scaleX: row.scaleX,
      scaleY: row.scaleY,
      rotation: row.rotation,
      anchorX: row.anchorX,
      anchorY: row.anchorY,
      cropLeft: row.cropLeft,
      cropRight: row.cropRight,
      cropTop: row.cropTop,
      cropBottom: row.cropBottom,
      isReversed: row.isReversed,
      isFrozen: row.isFrozen,
      flipHorizontal: row.flipHorizontal,
      flipVertical: row.flipVertical,
      volume: row.volume,
      isolationEnabled: row.isolationEnabled,
      isolationMode: IsolationMode.fromName(row.isolationMode),
      isolationColorValue: row.isolationColorValue,
      isolationBlurRadius: row.isolationBlurRadius,
      isolationEdgeFeather: row.isolationEdgeFeather,
      isolationMaskPath: row.isolationMaskPath,
      isolationSelectionLeft: row.isolationSelectionLeft,
      isolationSelectionTop: row.isolationSelectionTop,
      isolationSelectionRight: row.isolationSelectionRight,
      isolationSelectionBottom: row.isolationSelectionBottom,
    );
  }

  MarkerModel _markerFromRow(Marker row) {
    return MarkerModel(
      id: row.id,
      projectId: row.projectId,
      time: Duration(microseconds: row.timeUs),
      name: row.name,
      note: row.note,
      color: MarkerColor.fromName(row.color),
      durationUs: row.durationUs,
    );
  }
}
