import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/history/edit_command.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

final historyManagerProvider = ChangeNotifierProvider<HistoryManager>(
  (ref) => HistoryManager(),
);

class HistoryManager extends ChangeNotifier {
  final _undoStack = <EditCommand>[];
  final _redoStack = <EditCommand>[];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  String? get nextUndoDescription =>
      _undoStack.isEmpty ? null : _undoStack.last.description;
  String? get nextRedoDescription =>
      _redoStack.isEmpty ? null : _redoStack.last.description;

  Future<void> execute(
    EditCommand command,
    TimelineState state,
    ProjectRepository repository,
  ) async {
    await command.execute(state, repository);
    _undoStack.add(command);
    if (_undoStack.length > AppConstants.maxUndoSteps) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  Future<void> undo(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    if (_undoStack.isEmpty) return;
    final command = _undoStack.removeLast();
    await command.undo(state, repository);
    _redoStack.add(command);
    notifyListeners();
  }

  Future<void> redo(
    TimelineState state,
    ProjectRepository repository,
  ) async {
    if (_redoStack.isEmpty) return;
    final command = _redoStack.removeLast();
    await command.execute(state, repository);
    _undoStack.add(command);
    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
