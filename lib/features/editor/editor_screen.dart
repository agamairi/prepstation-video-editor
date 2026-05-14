import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/features/editor/panels/inspector_panel.dart';
import 'package:fluxedit/features/editor/panels/media_panel.dart';
import 'package:fluxedit/features/editor/panels/preview_panel.dart';
import 'package:fluxedit/features/editor/panels/timeline_panel.dart';
import 'package:fluxedit/features/export/export_dialog.dart';
import 'package:fluxedit/widgets/help_overlay.dart';

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

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  final _focusNode = FocusNode();
  Timer? _autoSaveTimer;
  bool _savedIndicator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(timelineControllerProvider);
      controller.loadProject(widget.projectId).then((_) {
        controller.ensureDefaultTracks(widget.projectId);
      });
      _focusNode.requestFocus();
    });

    _autoSaveTimer = Timer.periodic(AppConstants.autoSaveInterval, (_) {
      _saveProjectMeta();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveProjectMeta();
    }
  }

  Future<void> _saveProjectMeta() async {
    final project = ref.read(_projectProvider(widget.projectId)).value;
    if (project == null || !mounted) return;
    await ref.read(projectRepositoryProvider).saveProject(
          project.copyWith(dateModified: DateTime.now()),
        );
    if (!mounted) return;
    setState(() => _savedIndicator = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedIndicator = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    final controller = ref.read(timelineControllerProvider);
    final timelineState = ref.read(timelineStateProvider);

    if ((isMeta || HardwareKeyboard.instance.isControlPressed) &&
        key == LogicalKeyboardKey.keyZ &&
        !isShift) {
      controller.undo();
      return KeyEventResult.handled;
    }

    if ((isMeta || HardwareKeyboard.instance.isControlPressed) &&
        key == LogicalKeyboardKey.keyZ &&
        isShift) {
      controller.redo();
      return KeyEventResult.handled;
    }

    if ((isMeta || HardwareKeyboard.instance.isControlPressed) &&
        key == LogicalKeyboardKey.keyB) {
      controller.splitAtPlayhead();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.space) {
      timelineState.setPlaying(!timelineState.isPlaying);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyJ) {
      final fps = ref
              .read(_projectProvider(widget.projectId))
              .value
              ?.composition
              .frameRate ??
          30.0;
      final frameDur = Duration(microseconds: (1000000 / fps).round());
      timelineState.setPlayhead(timelineState.playhead - frameDur);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyK) {
      timelineState.setPlaying(false);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyL) {
      final fps = ref
              .read(_projectProvider(widget.projectId))
              .value
              ?.composition
              .frameRate ??
          30.0;
      final frameDur = Duration(microseconds: (1000000 / fps).round());
      timelineState.setPlayhead(timelineState.playhead + frameDur);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      final selected = timelineState.selectedClipIds;
      if (selected.isNotEmpty) {
        controller.rippleDelete(selected.first);
        timelineState.clearSelection();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyV) {
      ref.read(timelineToolProvider.notifier).state = TimelineTool.select;
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyB) {
      ref.read(timelineToolProvider.notifier).state = TimelineTool.blade;
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      timelineState.clearSelection();
      ref.read(timelineToolProvider.notifier).state = TimelineTool.select;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(_projectProvider(widget.projectId));

    return projectAsync.when(
      data: (project) => project != null
          ? Focus(
              focusNode: _focusNode,
              onKeyEvent: _handleKey,
              child: _EditorLayout(
                project: project,
                savedIndicator: _savedIndicator,
              ),
            )
          : const Scaffold(
              body: Center(child: Text('Project not found')),
            ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Layout ────────────────────────────────────────────────────────────────────

class _EditorLayout extends ConsumerWidget {
  const _EditorLayout({required this.project, required this.savedIndicator});

  final ProjectModel project;
  final bool savedIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: ColorTokens.backgroundDeep,
      appBar: _EditorAppBar(project: project, savedIndicator: savedIndicator),
      body: isDesktop
          ? _DesktopLayout(project: project)
          : _MobileLayout(project: project),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _EditorAppBar({required this.project, required this.savedIndicator});

  final ProjectModel project;
  final bool savedIndicator;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          bottom: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          // Left zone — project name + save state
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text(
                    project.name,
                    style: AppTypography.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: savedIndicator ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorTokens.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Saved',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.success,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Center zone — transport controls
          _TransportPill(timelineState: timelineState),
          // Right zone — timecode, help, export
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TimecodeDisplay(
                  playhead: timelineState.playhead,
                  frameRate: project.composition.frameRate,
                ),
                const SizedBox(width: 4),
                _AppBarIconButton(
                  icon: Icons.help_outline_rounded,
                  tooltip: 'Help & Shortcuts (?)',
                  onPressed: () => showHelpDialog(context),
                ),
                const SizedBox(width: 4),
                _ExportButton(project: project),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportPill extends ConsumerWidget {
  const _TransportPill({required this.timelineState});

  final TimelineState timelineState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TransportBtn(
            icon: Icons.skip_previous_rounded,
            tooltip: 'Go to Start',
            onPressed: () =>
                ref.read(timelineStateProvider).setPlayhead(Duration.zero),
          ),
          _TransportBtn(
            icon: timelineState.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip:
                timelineState.isPlaying ? 'Pause (Space)' : 'Play (Space)',
            size: 22,
            onPressed: () => ref
                .read(timelineStateProvider)
                .setPlaying(!timelineState.isPlaying),
          ),
          _TransportBtn(
            icon: Icons.skip_next_rounded,
            tooltip: 'Go to End',
            onPressed: () => ref
                .read(timelineStateProvider)
                .setPlayhead(timelineState.duration),
          ),
        ],
      ),
    );
  }
}

class _TransportBtn extends StatelessWidget {
  const _TransportBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 18,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: size, color: ColorTokens.textPrimary),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 17, color: ColorTokens.textSecondary),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => ExportDialog(project: project),
      ),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ColorTokens.accentPrimary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'Export',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timecode ──────────────────────────────────────────────────────────────────

class _TimecodeDisplay extends StatelessWidget {
  const _TimecodeDisplay({required this.playhead, required this.frameRate});

  final Duration playhead;
  final double frameRate;

  @override
  Widget build(BuildContext context) {
    final h = playhead.inHours;
    final m = playhead.inMinutes.remainder(60);
    final s = playhead.inSeconds.remainder(60);
    final f =
        (playhead.inMilliseconds.remainder(1000) / (1000 / frameRate)).floor();

    final timecode = '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}:'
        '${f.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(timecode, style: AppTypography.timecode),
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────

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
                child: PreviewPanel(project: project),
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

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerStatefulWidget {
  const _MobileLayout({required this.project});

  final ProjectModel project;

  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showInspector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: ColorTokens.inspectorBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorTokens.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: InspectorPanel(projectId: widget.project.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(timelineStateProvider).selectedClipIds;

    return Column(
      children: [
        Container(
          color: ColorTokens.backgroundPanel,
          child: TabBar(
            controller: _tabs,
            labelStyle: AppTypography.labelLarge,
            indicatorColor: ColorTokens.accentPrimary,
            labelColor: ColorTokens.accentPrimary,
            unselectedLabelColor: ColorTokens.textSecondary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                icon: Icon(Icons.perm_media_outlined, size: 16),
                text: 'Media',
              ),
              Tab(
                icon: Icon(Icons.play_circle_outline, size: 16),
                text: 'Preview',
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              TabBarView(
                controller: _tabs,
                children: [
                  MediaPanel(projectId: widget.project.id),
                  PreviewPanel(project: widget.project),
                ],
              ),
              if (selectedIds.isNotEmpty)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'inspector_fab',
                    backgroundColor: ColorTokens.accentPrimary,
                    tooltip: 'Edit Clip',
                    onPressed: _showInspector,
                    child: const Icon(Icons.tune, size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 5,
          child: TimelinePanel(project: widget.project),
        ),
      ],
    );
  }
}
