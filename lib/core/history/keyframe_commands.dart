import 'package:prepstation/core/history/edit_command.dart';
import 'package:prepstation/core/keyframes/keyframe_repository.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/keyframe_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

class AddKeyframeCommand extends EditCommand {
  const AddKeyframeCommand({
    required this.clipId,
    required this.keyframe,
    required this.keyframeRepo,
  });

  final String clipId;
  final KeyframeModel keyframe;
  final KeyframeRepository keyframeRepo;

  @override
  String get description => 'Add Keyframe';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await keyframeRepo.saveKeyframe(clipId, keyframe);
    state.addKeyframe(clipId, keyframe);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await keyframeRepo.deleteKeyframe(keyframe.id);
    state.removeKeyframe(clipId, keyframe.id);
  }
}

class RemoveKeyframeCommand extends EditCommand {
  const RemoveKeyframeCommand({
    required this.clipId,
    required this.keyframe,
    required this.keyframeRepo,
  });

  final String clipId;
  final KeyframeModel keyframe;
  final KeyframeRepository keyframeRepo;

  @override
  String get description => 'Remove Keyframe';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await keyframeRepo.deleteKeyframe(keyframe.id);
    state.removeKeyframe(clipId, keyframe.id);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await keyframeRepo.saveKeyframe(clipId, keyframe);
    state.addKeyframe(clipId, keyframe);
  }
}

class UpdateKeyframeCommand extends EditCommand {
  const UpdateKeyframeCommand({
    required this.clipId,
    required this.before,
    required this.after,
    required this.keyframeRepo,
  });

  final String clipId;
  final KeyframeModel before;
  final KeyframeModel after;
  final KeyframeRepository keyframeRepo;

  @override
  String get description => 'Update Keyframe';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await keyframeRepo.saveKeyframe(clipId, after);
    state.updateKeyframe(clipId, after);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await keyframeRepo.saveKeyframe(clipId, before);
    state.updateKeyframe(clipId, before);
  }
}
