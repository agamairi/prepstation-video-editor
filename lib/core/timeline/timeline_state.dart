import 'package:flutter/foundation.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/track_model.dart';

/// The canonical timeline state. Uses [ChangeNotifier] so timeline widgets
/// can subscribe at fine-grained granularity without rebuilding the full
/// Riverpod tree for every playhead tick.
class TimelineState extends ChangeNotifier {
  TimelineState({
    List<TrackModel>? tracks,
    List<ClipModel>? clips,
    Duration? duration,
    double? zoom,
    Duration? scrollOffset,
  })  : _tracks = tracks ?? [],
        _clips = clips ?? [],
        _duration = duration ?? Duration.zero,
        _zoom = zoom ?? AppConstants.defaultTimelineZoom,
        _scrollOffset = scrollOffset ?? Duration.zero;

  // ── Core state ────────────────────────────────────────────────────────────

  List<TrackModel> _tracks;
  List<ClipModel> _clips;
  Duration _duration;
  double _zoom; // pixels per second
  Duration _scrollOffset;
  Duration _playhead = Duration.zero;
  Duration? _inPoint;
  Duration? _outPoint;

  final Set<String> _selectedClipIds = {};
  String? _selectedTrackId;

  bool _isPlaying = false;
  bool _isScrubbing = false;
  bool _snapEnabled = true;

  final Map<String, List<EffectInstance>> _effectsByClipId = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<TrackModel> get tracks => List.unmodifiable(_tracks);
  List<ClipModel> get clips => List.unmodifiable(_clips);
  Duration get duration => _duration;
  double get zoom => _zoom;
  Duration get scrollOffset => _scrollOffset;
  Duration get playhead => _playhead;
  Duration? get inPoint => _inPoint;
  Duration? get outPoint => _outPoint;
  Set<String> get selectedClipIds => Set.unmodifiable(_selectedClipIds);
  String? get selectedTrackId => _selectedTrackId;
  bool get isPlaying => _isPlaying;
  bool get isScrubbing => _isScrubbing;
  bool get snapEnabled => _snapEnabled;

  List<EffectInstance> effectsForClip(String clipId) =>
      List.unmodifiable(_effectsByClipId[clipId] ?? []);

  List<TrackModel> get videoTracks =>
      _tracks.where((t) => t.isVideo).toList();
  List<TrackModel> get audioTracks =>
      _tracks.where((t) => t.isAudio).toList();

  List<ClipModel> clipsForTrack(String trackId) =>
      _clips.where((c) => c.trackId == trackId).toList()
        ..sort((a, b) => a.startOnTimeline.compareTo(b.startOnTimeline));

  ClipModel? clipAt(String trackId, Duration time) {
    for (final clip in clipsForTrack(trackId)) {
      if (time >= clip.startOnTimeline && time < clip.endOnTimeline) {
        return clip;
      }
    }
    return null;
  }

  // ── Pixel / time conversion ───────────────────────────────────────────────

  double timeToPixel(Duration time) {
    final offsetSeconds = _scrollOffset.inMicroseconds / 1000000.0;
    final timeSeconds = time.inMicroseconds / 1000000.0;
    return (timeSeconds - offsetSeconds) * _zoom;
  }

  Duration pixelToTime(double pixel) {
    final seconds = pixel / _zoom + (_scrollOffset.inMicroseconds / 1000000.0);
    return Duration(microseconds: (seconds * 1000000).round());
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void setTracks(List<TrackModel> tracks) {
    _tracks = List.from(tracks);
    notifyListeners();
  }

  void setClips(List<ClipModel> clips) {
    _clips = List.from(clips);
    _recalculateDuration();
    notifyListeners();
  }

  void addTrack(TrackModel track) {
    _tracks = [..._tracks, track];
    notifyListeners();
  }

  void removeTrack(String trackId) {
    _tracks = _tracks.where((t) => t.id != trackId).toList();
    _clips = _clips.where((c) => c.trackId != trackId).toList();
    _selectedClipIds.removeWhere(
      (id) => _clips.every((c) => c.id != id),
    );
    _recalculateDuration();
    notifyListeners();
  }

  void updateTrack(TrackModel track) {
    _tracks = _tracks.map((t) => t.id == track.id ? track : t).toList();
    notifyListeners();
  }

  void addClip(ClipModel clip) {
    _clips = [..._clips, clip];
    _recalculateDuration();
    notifyListeners();
  }

  void removeClip(String clipId) {
    _clips = _clips.where((c) => c.id != clipId).toList();
    _selectedClipIds.remove(clipId);
    _recalculateDuration();
    notifyListeners();
  }

  void updateClip(ClipModel clip) {
    _clips = _clips.map((c) => c.id == clip.id ? clip : c).toList();
    _recalculateDuration();
    notifyListeners();
  }

  void setPlayhead(Duration time) {
    _playhead = _clampDuration(time, Duration.zero, _duration);
    notifyListeners();
  }

  void setScrollOffset(Duration offset) {
    _scrollOffset = _clampDuration(offset, Duration.zero, _duration);
    notifyListeners();
  }

  static Duration _clampDuration(Duration d, Duration min, Duration max) {
    if (d < min) return min;
    if (max > Duration.zero && d > max) return max;
    return d;
  }

  void setZoom(double zoom) {
    const min = AppConstants.minTimelineZoom;
    const max = AppConstants.maxTimelineZoom;
    _zoom = zoom < min ? min : (zoom > max ? max : zoom);
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setScrubbing(bool scrubbing) {
    _isScrubbing = scrubbing;
    notifyListeners();
  }

  void setSnapEnabled(bool enabled) {
    _snapEnabled = enabled;
    notifyListeners();
  }

  void selectClip(String clipId, {bool addToSelection = false}) {
    if (!addToSelection) _selectedClipIds.clear();
    _selectedClipIds.add(clipId);
    notifyListeners();
  }

  void deselectClip(String clipId) {
    _selectedClipIds.remove(clipId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedClipIds.clear();
    _selectedTrackId = null;
    notifyListeners();
  }

  void selectTrack(String? trackId) {
    _selectedTrackId = trackId;
    notifyListeners();
  }

  void setInPoint(Duration? time) {
    _inPoint = time;
    notifyListeners();
  }

  void setOutPoint(Duration? time) {
    _outPoint = time;
    notifyListeners();
  }

  Duration? snapToNearestPoint(
    Duration time,
    String? excludeClipId, {
    double thresholdPixels = AppConstants.snapThreshold,
  }) {
    if (!_snapEnabled) return null;
    final thresholdUs = thresholdPixels / _zoom * 1000000;

    Duration? nearest;
    double minDist = thresholdUs;

    void check(Duration candidate) {
      final dist = (time - candidate).inMicroseconds.abs().toDouble();
      if (dist < minDist) {
        minDist = dist;
        nearest = candidate;
      }
    }

    // Snap to playhead
    check(_playhead);

    // Snap to clip edges
    for (final clip in _clips) {
      if (clip.id == excludeClipId) continue;
      check(clip.startOnTimeline);
      check(clip.endOnTimeline);
    }

    // Snap to markers (future)
    return nearest;
  }

  void setEffectsForClip(String clipId, List<EffectInstance> effects) {
    _effectsByClipId[clipId] = List.from(effects);
    notifyListeners();
  }

  void addEffect(EffectInstance effect) {
    final list = <EffectInstance>[
      ...(_effectsByClipId[effect.clipId] ?? []),
      effect,
    ];
    _effectsByClipId[effect.clipId] = list;
    notifyListeners();
  }

  void removeEffect(EffectInstance effect) {
    final list = (_effectsByClipId[effect.clipId] ?? [])
        .where((e) => e.id != effect.id)
        .toList();
    _effectsByClipId[effect.clipId] = list;
    notifyListeners();
  }

  void updateEffect(EffectInstance effect) {
    final list = (_effectsByClipId[effect.clipId] ?? [])
        .map((e) => e.id == effect.id ? effect : e)
        .toList();
    _effectsByClipId[effect.clipId] = list;
    notifyListeners();
  }

  void _recalculateDuration() {
    if (_clips.isEmpty) {
      _duration = Duration.zero;
      return;
    }
    final maxEnd = _clips.map((c) => c.endOnTimeline).reduce(
      (a, b) => a > b ? a : b,
    );
    _duration = maxEnd;
  }

  @override
  void dispose() {
    // base dispose
    super.dispose();
  }
}
