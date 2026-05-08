import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/features/editor/panels/inspector_panel.dart';
import 'package:fluxedit/features/editor/panels/media_panel.dart';
import 'package:fluxedit/features/editor/panels/preview_panel.dart';
import 'package:fluxedit/features/editor/panels/timeline_panel.dart';
import 'package:fluxedit/features/export/export_dialog.dart';

final _projectProvider = FutureProvider.family<ProjectModel?, String>(
  (ref, projectId) =>
      ref.watch(projectRepositoryProvider).getProject(projectId),
);

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(timelineControllerProvider);
      controller.loadProject(widget.projectId).then((_) {
        controller.ensureDefaultTracks(widget.projectId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(_projectProvider(widget.projectId));

    return projectAsync.when(
      data: (project) => project != null
          ? _EditorLayout(project: project)
          : const Scaffold(
              body: Center(child: Text('Project not found')),
            ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EditorLayout extends ConsumerWidget {
  const _EditorLayout({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: ColorTokens.backgroundDeep,
      appBar: _EditorAppBar(project: project),
      body: isDesktop
          ? _DesktopLayout(project: project)
          : _MobileLayout(project: project),
    );
  }
}

class _EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _EditorAppBar({required this.project});

  final ProjectModel project;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);

    return AppBar(
      backgroundColor: ColorTokens.backgroundPanel,
      titleSpacing: 8,
      title: Row(
        children: [
          Text(project.name, style: AppTypography.headlineSmall),
          const SizedBox(width: 16),
          _TimecodeDisplay(playhead: timelineState.playhead),
        ],
      ),
      actions: [
        _TransportControls(timelineState: timelineState),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _showExportDialog(context, ref),
          icon: const Icon(Icons.upload, size: 16),
          label: const Text('Export'),
          style: TextButton.styleFrom(
            foregroundColor: ColorTokens.accentPrimary,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => ExportDialog(project: project),
    );
  }
}

class _TimecodeDisplay extends StatelessWidget {
  const _TimecodeDisplay({required this.playhead});

  final Duration playhead;

  @override
  Widget build(BuildContext context) {
    final h = playhead.inHours;
    final m = playhead.inMinutes.remainder(60);
    final s = playhead.inSeconds.remainder(60);
    final f = (playhead.inMilliseconds.remainder(1000) / (1000 / 30)).floor();

    final timecode =
        '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}:'
        '${f.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(timecode, style: AppTypography.timecode),
    );
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({required this.timelineState});

  final TimelineState timelineState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 18),
          tooltip: 'Go to Start',
          onPressed: () =>
              ref.read(timelineStateProvider).setPlayhead(Duration.zero),
        ),
        IconButton(
          icon: Icon(
            timelineState.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 20,
          ),
          tooltip: timelineState.isPlaying ? 'Pause' : 'Play',
          onPressed: () => ref
              .read(timelineStateProvider)
              .setPlaying(!timelineState.isPlaying),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 18),
          tooltip: 'Go to End',
          onPressed: () => ref
              .read(timelineStateProvider)
              .setPlayhead(timelineState.duration),
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: MediaPanel(projectId: project.id),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 5,
                child: PreviewPanel(
                  project: project,
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 280,
                child: InspectorPanel(projectId: project.id),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 4,
          child: TimelinePanel(project: project),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: PreviewPanel(project: project),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 5,
          child: TimelinePanel(project: project),
        ),
      ],
    );
  }
}
