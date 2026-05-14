import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/features/editor/panels/inspector_panel.dart';
import 'package:fluxedit/features/editor/panels/media_panel.dart';
import 'package:fluxedit/features/editor/panels/portrait_timeline_strip.dart';
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

    // Frame-accurate navigation: Left/Right arrows ±1 frame, Shift ±10 frames
    if (key == LogicalKeyboardKey.arrowLeft) {
      final fps = ref
              .read(_projectProvider(widget.projectId))
              .value
              ?.composition
              .frameRate ??
          30.0;
      controller.stepFrames(isShift ? -10 : -1, frameRate: fps);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      final fps = ref
              .read(_projectProvider(widget.projectId))
              .value
              ?.composition
              .frameRate ??
          30.0;
      controller.stepFrames(isShift ? 10 : 1, frameRate: fps);
      return KeyEventResult.handled;
    }

    // Home/End: go to start/end
    if (key == LogicalKeyboardKey.home) {
      controller.goToStart();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      controller.goToEnd();
      return KeyEventResult.handled;
    }

    // Up/Down: seek to prev/next edit point
    if (key == LogicalKeyboardKey.arrowUp) {
      controller.seekToPreviousEdit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      controller.seekToNextEdit();
      return KeyEventResult.handled;
    }

    // M: add marker at playhead
    if (key == LogicalKeyboardKey.keyM) {
      controller.addMarker(projectId: widget.projectId);
      return KeyEventResult.handled;
    }

    // Shift+M: seek to next marker; Ctrl+Shift+M: prev marker
    // (handled by M with modifiers above is simpler — separate shortcuts below)

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConstants.desktopBreakpoint;
    final isPortrait =
        size.width < AppConstants.portraitBreakpointWidth &&
        size.height > size.width;

    return Scaffold(
      backgroundColor: ColorTokens.backgroundDeep,
      appBar: _EditorAppBar(
        project: project,
        savedIndicator: savedIndicator,
        isPortrait: isPortrait,
      ),
      body: isDesktop
          ? _DesktopLayout(project: project)
          : isPortrait
              ? _MobilePortraitLayout(project: project)
              : _MobileLayout(project: project),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _EditorAppBar({
    required this.project,
    required this.savedIndicator,
    this.isPortrait = false,
  });

  final ProjectModel project;
  final bool savedIndicator;
  final bool isPortrait;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);

    const decoration = BoxDecoration(
      color: ColorTokens.backgroundPanel,
      border: Border(bottom: BorderSide(color: ColorTokens.borderSubtle)),
    );

    // Portrait: strip AppBar down to name + export only; transport lives in body
    if (isPortrait) {
      return Container(
        height: 48,
        decoration: decoration,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                project.name,
                style: AppTypography.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _ExportButton(project: project),
            const SizedBox(width: 12),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      decoration: decoration,
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

// ── Mobile portrait layout (VSCO-style) ───────────────────────────────────────

enum _PortraitTool { adjust, tools }

class _MobilePortraitLayout extends ConsumerStatefulWidget {
  const _MobilePortraitLayout({required this.project});

  final ProjectModel project;

  @override
  ConsumerState<_MobilePortraitLayout> createState() =>
      _MobilePortraitLayoutState();
}

class _MobilePortraitLayoutState extends ConsumerState<_MobilePortraitLayout>
    with SingleTickerProviderStateMixin {
  _PortraitTool? _activeTool;
  late final AnimationController _panelAnim;
  late final Animation<double> _panelCurve;

  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _panelCurve = CurvedAnimation(
      parent: _panelAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _panelAnim.dispose();
    super.dispose();
  }

  void _toggleTool(_PortraitTool tool) {
    if (_activeTool == tool) {
      setState(() => _activeTool = null);
      _panelAnim.reverse();
    } else {
      setState(() => _activeTool = tool);
      _panelAnim.forward();
    }
  }

  void _showMediaPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: ColorTokens.backgroundPanel,
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
                child: MediaPanel(projectId: widget.project.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullInspector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.92,
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
    return Column(
      children: [
        // Preview — takes the top portion of available space
        Expanded(
          flex: 5,
          child: PreviewPanel(project: widget.project),
        ),
        // Transport bar — play/pause, skip, timecode
        _PortraitTransportBar(project: widget.project),
        // Timeline strip — compact horizontal clip view
        const Divider(height: 1),
        const PortraitTimelineStrip(),
        // Animated tool panel
        SizeTransition(
          sizeFactor: _panelCurve,
          axisAlignment: -1,
          child: SizedBox(
            height: AppConstants.portraitAdjustPanelHeight,
            child: _buildToolPanel(),
          ),
        ),
        // Bottom tool bar
        const Divider(height: 1),
        _PortraitToolBar(
          activeTool: _activeTool,
          project: widget.project,
          onToggle: _toggleTool,
          onMediaTap: _showMediaPanel,
          onMoreTap: _showFullInspector,
        ),
      ],
    );
  }

  Widget _buildToolPanel() {
    return switch (_activeTool) {
      _PortraitTool.adjust =>
        _PortraitAdjustPanel(projectId: widget.project.id),
      _PortraitTool.tools => _PortraitToolsPanel(project: widget.project),
      null => const SizedBox.shrink(),
    };
  }
}

// ── Portrait transport bar ────────────────────────────────────────────────────

class _PortraitTransportBar extends ConsumerWidget {
  const _PortraitTransportBar({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);

    return Container(
      height: 44,
      color: ColorTokens.backgroundPanel,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TransportBtn(
            icon: Icons.skip_previous_rounded,
            tooltip: 'Go to Start',
            onPressed: () => state.setPlayhead(Duration.zero),
          ),
          _TransportBtn(
            icon: state.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip: state.isPlaying ? 'Pause' : 'Play',
            size: 26,
            onPressed: () => state.setPlaying(!state.isPlaying),
          ),
          _TransportBtn(
            icon: Icons.skip_next_rounded,
            tooltip: 'Go to End',
            onPressed: () => state.setPlayhead(state.duration),
          ),
          const Spacer(),
          _TimecodeDisplay(
            playhead: state.playhead,
            frameRate: project.composition.frameRate,
          ),
        ],
      ),
    );
  }
}

// ── Portrait tool bar ─────────────────────────────────────────────────────────

class _PortraitToolBar extends ConsumerWidget {
  const _PortraitToolBar({
    required this.activeTool,
    required this.project,
    required this.onToggle,
    required this.onMediaTap,
    required this.onMoreTap,
  });

  final _PortraitTool? activeTool;
  final ProjectModel project;
  final ValueChanged<_PortraitTool> onToggle;
  final VoidCallback onMediaTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final hasSelection = state.selectedClipIds.isNotEmpty;

    return Container(
      height: AppConstants.portraitToolBarHeight,
      color: ColorTokens.backgroundPanel,
      child: Row(
        children: [
          _ToolBarBtn(
            icon: Icons.perm_media_outlined,
            label: 'Media',
            onTap: onMediaTap,
          ),
          _ToolBarBtn(
            icon: Icons.tune,
            label: 'Adjust',
            isActive: activeTool == _PortraitTool.adjust,
            enabled: hasSelection,
            onTap: hasSelection ? () => onToggle(_PortraitTool.adjust) : null,
          ),
          _ToolBarBtn(
            icon: Icons.content_cut,
            label: 'Split',
            onTap: hasSelection
                ? () => ref.read(timelineControllerProvider).splitAtPlayhead()
                : null,
            enabled: hasSelection,
          ),
          _ToolBarBtn(
            icon: Icons.build_outlined,
            label: 'Tools',
            isActive: activeTool == _PortraitTool.tools,
            onTap: () => onToggle(_PortraitTool.tools),
          ),
          _ToolBarBtn(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _ToolBarBtn extends StatelessWidget {
  const _ToolBarBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? ColorTokens.textDisabled
        : isActive
            ? ColorTokens.accentPrimary
            : ColorTokens.textSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portrait adjust panel (VSCO-style) ────────────────────────────────────────

enum _AdjustParam { opacity, speed }

class _PortraitAdjustPanel extends ConsumerStatefulWidget {
  const _PortraitAdjustPanel({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_PortraitAdjustPanel> createState() =>
      _PortraitAdjustPanelState();
}

class _PortraitAdjustPanelState extends ConsumerState<_PortraitAdjustPanel> {
  _AdjustParam _active = _AdjustParam.opacity;
  double? _liveValue;
  ClipModel? _clipAtDragStart;

  ClipModel? _selectedClip(TimelineState state) {
    final id = state.selectedClipIds.firstOrNull;
    if (id == null) return null;
    try {
      return state.clips.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineStateProvider);
    final clip = _selectedClip(state);

    return Container(
      color: ColorTokens.backgroundPanel,
      child: clip == null
          ? const Center(
              child: Text(
                'Select a clip to adjust',
                style: TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : _buildAdjustContent(clip, state),
    );
  }

  Widget _buildAdjustContent(ClipModel clip, TimelineState state) {
    final opacityVal = _active == _AdjustParam.opacity
        ? (_liveValue ?? clip.opacity)
        : clip.opacity;
    final speedVal = _active == _AdjustParam.speed
        ? (_liveValue ?? clip.speed)
        : clip.speed;

    return Column(
      children: [
        // Category chips row
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _AdjustChip(
                label: 'Opacity',
                value: '${(opacityVal * 100).round()}%',
                isActive: _active == _AdjustParam.opacity,
                onTap: () => setState(() {
                  _active = _AdjustParam.opacity;
                  _liveValue = null;
                }),
              ),
              const SizedBox(width: 8),
              _AdjustChip(
                label: 'Speed',
                value: '${speedVal.toStringAsFixed(2)}x',
                isActive: _active == _AdjustParam.speed,
                onTap: () => setState(() {
                  _active = _AdjustParam.speed;
                  _liveValue = null;
                }),
              ),
            ],
          ),
        ),
        // Current value display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _active == _AdjustParam.opacity ? 'Opacity' : 'Speed',
                style: const TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _active == _AdjustParam.opacity
                    ? '${(opacityVal * 100).round()}%'
                    : '${speedVal.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: ColorTokens.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
        // Slider
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _active == _AdjustParam.opacity
                ? _buildOpacitySlider(clip)
                : _buildSpeedSlider(clip),
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySlider(ClipModel clip) {
    final val = _liveValue ?? clip.opacity;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 3,
      ),
      child: Slider(
        value: val,
        min: AppConstants.minOpacity,
        max: AppConstants.maxOpacity,
        activeColor: ColorTokens.accentPrimary,
        inactiveColor: ColorTokens.sliderTrack,
        onChangeStart: (_) => _clipAtDragStart = clip,
        onChanged: (v) {
          setState(() => _liveValue = v);
          ref.read(timelineStateProvider).updateClip(clip.copyWith(opacity: v));
        },
        onChangeEnd: (v) {
          if (_clipAtDragStart != null) {
            ref
                .read(timelineControllerProvider)
                .updateClipOpacity(clip.id, v);
            _clipAtDragStart = null;
          }
          setState(() => _liveValue = null);
        },
      ),
    );
  }

  Widget _buildSpeedSlider(ClipModel clip) {
    final val = (_liveValue ?? clip.speed).clamp(
      AppConstants.minClipSpeed,
      AppConstants.maxClipSpeed,
    );
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 3,
      ),
      child: Slider(
        value: val,
        min: AppConstants.minClipSpeed,
        max: 4.0,
        activeColor: ColorTokens.accentPrimary,
        inactiveColor: ColorTokens.sliderTrack,
        onChangeStart: (_) => _clipAtDragStart = clip,
        onChanged: (v) {
          setState(() => _liveValue = v);
          ref.read(timelineStateProvider).updateClip(clip.copyWith(speed: v));
        },
        onChangeEnd: (v) {
          if (_clipAtDragStart != null) {
            ref.read(timelineControllerProvider).updateClipSpeed(clip.id, v);
            _clipAtDragStart = null;
          }
          setState(() => _liveValue = null);
        },
      ),
    );
  }
}

class _AdjustChip extends StatelessWidget {
  const _AdjustChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.accentPrimary.withValues(alpha: 0.15)
              : ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? ColorTokens.accentPrimary.withValues(alpha: 0.5)
                : ColorTokens.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? ColorTokens.accentPrimary
                    : ColorTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: isActive
                    ? ColorTokens.accentPrimary
                    : ColorTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portrait tools panel ──────────────────────────────────────────────────────

class _PortraitToolsPanel extends ConsumerWidget {
  const _PortraitToolsPanel({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyManagerProvider);
    final tool = ref.watch(timelineToolProvider);
    final state = ref.watch(timelineStateProvider);
    final controller = ref.read(timelineControllerProvider);

    return Container(
      color: ColorTokens.backgroundPanel,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // History row
          Row(
            children: [
              Expanded(
                child: _ToolsPanelBtn(
                  icon: Icons.undo,
                  label: history.nextUndoDescription != null
                      ? 'Undo: ${history.nextUndoDescription}'
                      : 'Undo',
                  enabled: history.canUndo,
                  onTap: history.canUndo ? () => controller.undo() : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolsPanelBtn(
                  icon: Icons.redo,
                  label: history.nextRedoDescription != null
                      ? 'Redo: ${history.nextRedoDescription}'
                      : 'Redo',
                  enabled: history.canRedo,
                  onTap: history.canRedo ? () => controller.redo() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tool select row
          Row(
            children: [
              Expanded(
                child: _ToolsPanelBtn(
                  icon: Icons.near_me,
                  label: 'Select',
                  isActive: tool == TimelineTool.select,
                  onTap: () => ref.read(timelineToolProvider.notifier).state =
                      TimelineTool.select,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolsPanelBtn(
                  icon: Icons.content_cut,
                  label: 'Blade',
                  isActive: tool == TimelineTool.blade,
                  onTap: () => ref.read(timelineToolProvider.notifier).state =
                      TimelineTool.blade,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Split + snap row
          Row(
            children: [
              Expanded(
                child: _ToolsPanelBtn(
                  icon: Icons.vertical_align_center,
                  label: 'Split at Playhead',
                  enabled: state.selectedClipIds.isNotEmpty,
                  onTap: state.selectedClipIds.isNotEmpty
                      ? () => controller.splitAtPlayhead()
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolsPanelBtn(
                  icon: state.snapEnabled
                      ? Icons.grid_on
                      : Icons.grid_off,
                  label: state.snapEnabled ? 'Snap On' : 'Snap Off',
                  isActive: state.snapEnabled,
                  onTap: () => state.setSnapEnabled(!state.snapEnabled),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolsPanelBtn extends StatelessWidget {
  const _ToolsPanelBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fgColor = !enabled
        ? ColorTokens.textDisabled
        : isActive
            ? ColorTokens.accentPrimary
            : ColorTokens.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.accentPrimary.withValues(alpha: 0.12)
              : ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? ColorTokens.accentPrimary.withValues(alpha: 0.4)
                : ColorTokens.borderDefault,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
