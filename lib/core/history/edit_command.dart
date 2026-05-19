import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

abstract class EditCommand {
  const EditCommand();

  String get description;

  Future<void> execute(TimelineState state, ProjectRepository repository);
  Future<void> undo(TimelineState state, ProjectRepository repository);
}
