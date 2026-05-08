import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/history/edit_command.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';

class AddEffectCommand extends EditCommand {
  const AddEffectCommand(this.effect);

  final EffectInstance effect;

  @override
  String get description => 'Add ${effect.displayName}';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await repository.saveEffect(effect);
    state.addEffect(effect);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await repository.deleteEffect(effect.id);
    state.removeEffect(effect);
  }
}

class RemoveEffectCommand extends EditCommand {
  const RemoveEffectCommand(this.effect);

  final EffectInstance effect;

  @override
  String get description => 'Remove ${effect.displayName}';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await repository.deleteEffect(effect.id);
    state.removeEffect(effect);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await repository.saveEffect(effect);
    state.addEffect(effect);
  }
}

class UpdateEffectCommand extends EditCommand {
  const UpdateEffectCommand({required this.before, required this.after});

  final EffectInstance before;
  final EffectInstance after;

  @override
  String get description => 'Update ${after.displayName}';

  @override
  Future<void> execute(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await repository.saveEffect(after);
    state.updateEffect(after);
  }

  @override
  Future<void> undo(TimelineState state, ProjectRepository repository) async {
    await repository.saveEffect(before);
    state.updateEffect(before);
  }
}
