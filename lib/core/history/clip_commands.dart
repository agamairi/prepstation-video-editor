import 'package:prepstation/core/history/edit_command.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

/// Generic update for any single-clip property change (move, trim, opacity…).
class UpdateClipCommand extends EditCommand {
  const UpdateClipCommand({
    required this.before,
    required this.after,
    required this.description,
  });

  final ClipModel before;
  final ClipModel after;

  @override
  final String description;

  @override
  Future<void> execute(TimelineState state, ProjectRepository repository) async {
    state.updateClip(after);
    await repository.saveClip(after);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    state.updateClip(before);
    await repository.saveClip(before);
  }
}

class AddClipCommand extends EditCommand {
  const AddClipCommand(this.clip, [this.description = 'Add Clip']);

  final ClipModel clip;

  @override
  final String description;

  @override
  Future<void> execute(TimelineState state, ProjectRepository repository) async {
    state.addClip(clip);
    await repository.saveClip(clip);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    state.removeClip(clip.id);
    await repository.deleteClip(clip.id);
  }
}

class RemoveClipCommand extends EditCommand {
  const RemoveClipCommand(this.clip, [this.description = 'Delete Clip']);

  final ClipModel clip;

  @override
  final String description;

  @override
  Future<void> execute(TimelineState state, ProjectRepository repository) async {
    state.removeClip(clip.id);
    await repository.deleteClip(clip.id);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    state.addClip(clip);
    await repository.saveClip(clip);
  }
}

class SplitClipCommand extends EditCommand {
  const SplitClipCommand({
    required this.originalClip,
    required this.leftClip,
    required this.rightClip,
  });

  final ClipModel originalClip;
  final ClipModel leftClip;
  final ClipModel rightClip;

  @override
  String get description => 'Split Clip';

  @override
  Future<void> execute(TimelineState state, ProjectRepository repository) async {
    state.removeClip(originalClip.id);
    state.addClip(leftClip);
    state.addClip(rightClip);
    await repository.deleteClip(originalClip.id);
    await repository.saveClip(leftClip);
    await repository.saveClip(rightClip);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    state.removeClip(leftClip.id);
    state.removeClip(rightClip.id);
    state.addClip(originalClip);
    await repository.deleteClip(leftClip.id);
    await repository.deleteClip(rightClip.id);
    await repository.saveClip(originalClip);
  }
}

/// Deletes [deletedClip] and shifts all subsequent clips on the same track left
/// by the clip's duration. Fully reversible.
class RippleDeleteCommand extends EditCommand {
  const RippleDeleteCommand({
    required this.deletedClip,
    required this.originalSubsequentClips,
    required this.shiftedSubsequentClips,
  });

  final ClipModel deletedClip;
  final List<ClipModel> originalSubsequentClips;
  final List<ClipModel> shiftedSubsequentClips;

  @override
  String get description => 'Ripple Delete';

  @override
  Future<void> execute(TimelineState state, ProjectRepository repository) async {
    state.removeClip(deletedClip.id);
    await repository.deleteClip(deletedClip.id);
    for (final clip in shiftedSubsequentClips) {
      state.updateClip(clip);
      await repository.saveClip(clip);
    }
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    for (final clip in originalSubsequentClips) {
      state.updateClip(clip);
      await repository.saveClip(clip);
    }
    state.addClip(deletedClip);
    await repository.saveClip(deletedClip);
  }
}
