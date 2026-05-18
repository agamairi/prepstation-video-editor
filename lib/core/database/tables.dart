import 'package:drift/drift.dart';

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get filePath => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get version => text().withDefault(const Constant('0.1.0'))();

  // Composition settings
  IntColumn get compWidth => integer().withDefault(const Constant(1920))();
  IntColumn get compHeight => integer().withDefault(const Constant(1080))();
  RealColumn get compFrameRate =>
      real().withDefault(const Constant(30.0))();
  IntColumn get compDurationUs => integer().withDefault(const Constant(0))();
  IntColumn get compBackgroundColor =>
      integer().withDefault(const Constant(0xFF000000))();

  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MediaAssetRow')
class MediaAssets extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get durationUs => integer().withDefault(const Constant(0))();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();
  RealColumn get frameRate => real().withDefault(const Constant(0.0))();
  IntColumn get sampleRate => integer().withDefault(const Constant(0))();
  IntColumn get channels => integer().withDefault(const Constant(0))();
  TextColumn get videoCodec => text().withDefault(const Constant(''))();
  TextColumn get audioCodec => text().withDefault(const Constant(''))();
  IntColumn get bitRate => integer().withDefault(const Constant(0))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get colorSpace => text().withDefault(const Constant(''))();
  TextColumn get proxyPath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get binId => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  IntColumn get trackIndex => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get height =>
      real().withDefault(const Constant(56.0))();
  BoolColumn get isMuted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSoloed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isVisible =>
      boolean().withDefault(const Constant(true))();
  RealColumn get volume => real().withDefault(const Constant(1.0))();
  RealColumn get pan => real().withDefault(const Constant(0.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Clips extends Table {
  TextColumn get id => text()();
  TextColumn get trackId =>
      text().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaId =>
      text().references(MediaAssets, #id, onDelete: KeyAction.restrict)();
  TextColumn get type => text()();
  IntColumn get startOnTimelineUs => integer()();
  IntColumn get endOnTimelineUs => integer()();
  IntColumn get mediaInPointUs => integer()();
  IntColumn get mediaOutPointUs => integer()();
  RealColumn get speed => real().withDefault(const Constant(1.0))();
  RealColumn get opacity => real().withDefault(const Constant(1.0))();
  TextColumn get blendMode =>
      text().withDefault(const Constant('normal'))();
  IntColumn get labelColorIndex =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isVideoLinked =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isAudioLinked =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isMuted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked =>
      boolean().withDefault(const Constant(false))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get transitionInId => text().nullable()();
  TextColumn get transitionOutId => text().nullable()();
  IntColumn get transitionInDurationUs =>
      integer().withDefault(const Constant(0))();
  IntColumn get transitionOutDurationUs =>
      integer().withDefault(const Constant(0))();

  // Title clip columns
  TextColumn get titleText => text().nullable()();
  RealColumn get titleFontSize =>
      real().withDefault(const Constant(48.0))();
  IntColumn get titleColorValue =>
      integer().withDefault(const Constant(0xFFFFFFFF))();
  TextColumn get titleAlignment =>
      text().withDefault(const Constant('center'))();

  // Color-card clip column
  IntColumn get cardColorValue =>
      integer().withDefault(const Constant(0xFF000000))();

  // Font & animation (title, colorCard, and image clips)
  TextColumn get fontFamily =>
      text().withDefault(const Constant('Roboto'))();
  TextColumn get textAnimationType =>
      text().withDefault(const Constant('none'))();
  IntColumn get textAnimationDurationMs =>
      integer().withDefault(const Constant(600))();

  // Transform
  RealColumn get posX => real().withDefault(const Constant(0.0))();
  RealColumn get posY => real().withDefault(const Constant(0.0))();
  RealColumn get scaleX => real().withDefault(const Constant(1.0))();
  RealColumn get scaleY => real().withDefault(const Constant(1.0))();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();
  RealColumn get anchorX => real().withDefault(const Constant(0.5))();
  RealColumn get anchorY => real().withDefault(const Constant(0.5))();

  // Crop
  RealColumn get cropLeft => real().withDefault(const Constant(0.0))();
  RealColumn get cropRight => real().withDefault(const Constant(0.0))();
  RealColumn get cropTop => real().withDefault(const Constant(0.0))();
  RealColumn get cropBottom => real().withDefault(const Constant(0.0))();

  // Clip flags
  BoolColumn get isReversed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isFrozen =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get flipHorizontal =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get flipVertical =>
      boolean().withDefault(const Constant(false))();

  // Per-clip volume
  RealColumn get volume => real().withDefault(const Constant(1.0))();

  // Subject isolation (background removal)
  BoolColumn get isolationEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get isolationMode =>
      text().withDefault(const Constant('transparent'))();
  IntColumn get isolationColorValue =>
      integer().withDefault(const Constant(0xFF00FF00))();
  RealColumn get isolationBlurRadius =>
      real().withDefault(const Constant(20.0))();
  TextColumn get isolationMaskPath => text().nullable()();
  RealColumn get isolationSelectionLeft => real().nullable()();
  RealColumn get isolationSelectionTop => real().nullable()();
  RealColumn get isolationSelectionRight => real().nullable()();
  RealColumn get isolationSelectionBottom => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Keyframes extends Table {
  TextColumn get id => text()();
  TextColumn get clipId =>
      text().references(Clips, #id, onDelete: KeyAction.cascade)();
  TextColumn get parameterId => text()();
  IntColumn get timeUs => integer()();
  RealColumn get value => real()();
  TextColumn get interpolation =>
      text().withDefault(const Constant('linear'))();
  RealColumn get inTangentX => real().withDefault(const Constant(0.0))();
  RealColumn get inTangentY => real().withDefault(const Constant(0.0))();
  RealColumn get outTangentX => real().withDefault(const Constant(0.0))();
  RealColumn get outTangentY => real().withDefault(const Constant(0.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EffectInstanceRow')
class EffectInstances extends Table {
  TextColumn get id => text()();
  TextColumn get clipId =>
      text().references(Clips, #id, onDelete: KeyAction.cascade)();
  TextColumn get effectType => text()();
  IntColumn get stackIndex => integer()();
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get parametersJson =>
      text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Markers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeUs => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get color =>
      text().withDefault(const Constant('blue'))();
  IntColumn get durationUs => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectSettings extends Table {
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {projectId, key};
}
