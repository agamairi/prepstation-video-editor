import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_registry.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/history/history_manager.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/timeline_tool.dart';
import 'package:prepstation/features/editor/panels/inspector_panel.dart';
import 'package:prepstation/features/editor/panels/media_panel.dart';
import 'package:prepstation/features/editor/panels/portrait_timeline_strip.dart';
import 'package:prepstation/features/editor/panels/preview_panel.dart';
import 'package:prepstation/features/editor/panels/timeline_panel.dart';
import 'package:prepstation/features/export/export_dialog.dart';
import 'package:prepstation/widgets/help_overlay.dart';
import 'package:go_router/go_router.dart';

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
      if (!mounted) return;
      final controller = ref.read(timelineControllerProvider);
      controller.loadProject(widget.projectId).then((_) {
        if (!mounted) return;
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

    if (key == LogicalKeyboardKey.keyT) {
      ref.read(timelineToolProvider.notifier).state = TimelineTool.tracker;
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
            const SizedBox(width: 4),
            _AppBarIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back to Projects',
              onPressed: () => context.go('/'),
            ),
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
          // Left zone — back button + project name + save state
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  _AppBarIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Projects',
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 4),
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
      builder: (sheetContext) => DraggableScrollableSheet(
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
                child: MediaPanel(
                  projectId: widget.project.id,
                  onClipAdded: () {
                    if (Navigator.of(sheetContext).canPop()) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
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

// ── Portrait adjust panel (category-based dial) ──────────────────────────────

class _DialSpec {
  const _DialSpec({
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.minorStep,
    required this.majorStep,
    required this.pxPerTick,
  });
  final double min, max, defaultValue, minorStep, majorStep, pxPerTick;
}

enum _ParamKind { clipProperty, effectParam }

class _SubParam {
  const _SubParam({
    required this.label,
    this.suffix = '',
    required this.dial,
    required this.kind,
    this.clipField,
    this.effectType,
    this.effectParam,
  });
  final String label;
  final String suffix;
  final _DialSpec dial;
  final _ParamKind kind;
  final String? clipField;
  final EffectType? effectType;
  final String? effectParam;

  bool get isEffect => kind == _ParamKind.effectParam;

  String formatValue(double v) {
    if (clipField == 'opacity' || clipField == 'volume') return '${(v * 100).round()}';
    if (clipField == 'speed') return v.toStringAsFixed(2);
    if (clipField?.startsWith('scale') == true) return '${(v * 100).round()}';
    if (clipField == 'rotation') return v.toStringAsFixed(1);
    if (clipField?.startsWith('crop') == true) return '${(v * 100).round()}';
    if (v.abs() < 10) return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }
}

class _AdjustCategory {
  const _AdjustCategory({
    required this.icon,
    required this.label,
    required this.params,
    this.needsVideo = false,
    this.needsAudio = false,
  });
  final IconData icon;
  final String label;
  final List<_SubParam> params;
  final bool needsVideo;
  final bool needsAudio;

  bool appliesTo(ClipType type) {
    if (!needsVideo && !needsAudio) return true;
    final hasVideo = type == ClipType.video || type == ClipType.image ||
        type == ClipType.title || type == ClipType.colorCard;
    final hasAudio = type == ClipType.video || type == ClipType.audio;
    if (needsVideo && !hasVideo) return false;
    if (needsAudio && !hasAudio) return false;
    return true;
  }
}

const _kAdjustCategories = <_AdjustCategory>[
  // ── Clip properties ──
  _AdjustCategory(icon: Icons.opacity, label: 'Opacity', params: [
    _SubParam(label: 'Opacity', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'opacity',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
  ]),
  _AdjustCategory(icon: Icons.slow_motion_video, label: 'Speed', params: [
    _SubParam(label: 'Speed', suffix: '×', kind: _ParamKind.clipProperty, clipField: 'speed',
      dial: _DialSpec(min: 0.25, max: 4, defaultValue: 1, minorStep: 0.05, majorStep: 0.5, pxPerTick: 8)),
  ]),
  _AdjustCategory(icon: Icons.volume_up, label: 'Volume', needsAudio: true, params: [
    _SubParam(label: 'Volume', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'volume',
      dial: _DialSpec(min: 0, max: 4, defaultValue: 1, minorStep: 0.01, majorStep: 0.25, pxPerTick: 5)),
  ]),
  // ── Video effects ──
  _AdjustCategory(icon: Icons.palette_outlined, label: 'Color', needsVideo: true, params: [
    _SubParam(label: 'Brightness', kind: _ParamKind.effectParam,
      effectType: EffectType.colorCorrection, effectParam: 'brightness',
      dial: _DialSpec(min: -1, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Contrast', kind: _ParamKind.effectParam,
      effectType: EffectType.colorCorrection, effectParam: 'contrast',
      dial: _DialSpec(min: 0, max: 3, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
    _SubParam(label: 'Saturation', kind: _ParamKind.effectParam,
      effectType: EffectType.colorCorrection, effectParam: 'saturation',
      dial: _DialSpec(min: 0, max: 3, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
    _SubParam(label: 'Hue', kind: _ParamKind.effectParam,
      effectType: EffectType.colorCorrection, effectParam: 'hue',
      dial: _DialSpec(min: -3.14159, max: 3.14159, defaultValue: 0, minorStep: 0.03, majorStep: 0.3, pxPerTick: 5)),
  ]),
  _AdjustCategory(icon: Icons.blur_on, label: 'Blur', needsVideo: true, params: [
    _SubParam(label: 'Radius', suffix: 'px', kind: _ParamKind.effectParam,
      effectType: EffectType.blur, effectParam: 'radius',
      dial: _DialSpec(min: 0, max: 40, defaultValue: 0, minorStep: 0.5, majorStep: 5, pxPerTick: 6)),
  ]),
  _AdjustCategory(icon: Icons.vignette, label: 'Vignette', needsVideo: true, params: [
    _SubParam(label: 'Amount', kind: _ParamKind.effectParam,
      effectType: EffectType.vignette, effectParam: 'angle',
      dial: _DialSpec(min: 0, max: 3.14159, defaultValue: 0, minorStep: 0.03, majorStep: 0.3, pxPerTick: 5)),
  ]),
  _AdjustCategory(icon: Icons.grain, label: 'Grain', needsVideo: true, params: [
    _SubParam(label: 'Strength', kind: _ParamKind.effectParam,
      effectType: EffectType.grain, effectParam: 'strength',
      dial: _DialSpec(min: 0, max: 100, defaultValue: 0, minorStep: 1, majorStep: 10, pxPerTick: 4)),
  ]),
  _AdjustCategory(icon: Icons.deblur, label: 'Sharpen', needsVideo: true, params: [
    _SubParam(label: 'Amount', kind: _ParamKind.effectParam,
      effectType: EffectType.sharpen, effectParam: 'amount',
      dial: _DialSpec(min: 0, max: 5, defaultValue: 0, minorStep: 0.05, majorStep: 0.5, pxPerTick: 8)),
    _SubParam(label: 'Size', kind: _ParamKind.effectParam,
      effectType: EffectType.sharpen, effectParam: 'size',
      dial: _DialSpec(min: 3, max: 13, defaultValue: 5, minorStep: 1, majorStep: 2, pxPerTick: 10)),
  ]),
  _AdjustCategory(icon: Icons.auto_fix_high, label: 'Denoise', needsVideo: true, params: [
    _SubParam(label: 'Strength', kind: _ParamKind.effectParam,
      effectType: EffectType.denoise, effectParam: 'strength',
      dial: _DialSpec(min: 1, max: 20, defaultValue: 1, minorStep: 0.5, majorStep: 2, pxPerTick: 6)),
    _SubParam(label: 'Patch', kind: _ParamKind.effectParam,
      effectType: EffectType.denoise, effectParam: 'patchSize',
      dial: _DialSpec(min: 3, max: 15, defaultValue: 7, minorStep: 1, majorStep: 2, pxPerTick: 8)),
    _SubParam(label: 'Search', kind: _ParamKind.effectParam,
      effectType: EffectType.denoise, effectParam: 'searchSize',
      dial: _DialSpec(min: 5, max: 25, defaultValue: 15, minorStep: 1, majorStep: 5, pxPerTick: 6)),
  ]),
  _AdjustCategory(icon: Icons.tv_off, label: 'Chroma', needsVideo: true, params: [
    _SubParam(label: 'Red', kind: _ParamKind.effectParam,
      effectType: EffectType.chromaKey, effectParam: 'colorR',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Green', kind: _ParamKind.effectParam,
      effectType: EffectType.chromaKey, effectParam: 'colorG',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Blue', kind: _ParamKind.effectParam,
      effectType: EffectType.chromaKey, effectParam: 'colorB',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Similarity', kind: _ParamKind.effectParam,
      effectType: EffectType.chromaKey, effectParam: 'similarity',
      dial: _DialSpec(min: 0.01, max: 0.5, defaultValue: 0.3, minorStep: 0.005, majorStep: 0.05, pxPerTick: 8)),
    _SubParam(label: 'Blend', kind: _ParamKind.effectParam,
      effectType: EffectType.chromaKey, effectParam: 'blend',
      dial: _DialSpec(min: 0, max: 0.3, defaultValue: 0.05, minorStep: 0.005, majorStep: 0.05, pxPerTick: 10)),
  ]),
  _AdjustCategory(icon: Icons.color_lens, label: 'Wheels', needsVideo: true, params: [
    _SubParam(label: 'Lift R', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'liftR',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Lift G', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'liftG',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Lift B', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'liftB',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gamma R', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gammaR',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gamma G', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gammaG',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gamma B', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gammaB',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gain R', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gainR',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gain G', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gainG',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Gain B', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'gainB',
      dial: _DialSpec(min: 0, max: 2, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Temp', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'temperature',
      dial: _DialSpec(min: -1, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Tint', kind: _ParamKind.effectParam,
      effectType: EffectType.colorWheels, effectParam: 'tint',
      dial: _DialSpec(min: -1, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
  ]),
  _AdjustCategory(icon: Icons.timeline, label: 'Curves', needsVideo: true, params: [
    _SubParam(label: 'M Black', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'masterBlack',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'M White', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'masterWhite',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'M Gamma', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'masterGamma',
      dial: _DialSpec(min: 0.1, max: 4, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
    _SubParam(label: 'R Black', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'redBlack',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'R White', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'redWhite',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'R Gamma', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'redGamma',
      dial: _DialSpec(min: 0.1, max: 4, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
    _SubParam(label: 'G Black', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'greenBlack',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'G White', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'greenWhite',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'G Gamma', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'greenGamma',
      dial: _DialSpec(min: 0.1, max: 4, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
    _SubParam(label: 'B Black', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'blueBlack',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'B White', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'blueWhite',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 1, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'B Gamma', kind: _ParamKind.effectParam,
      effectType: EffectType.curves, effectParam: 'blueGamma',
      dial: _DialSpec(min: 0.1, max: 4, defaultValue: 1, minorStep: 0.02, majorStep: 0.2, pxPerTick: 5)),
  ]),
  // ── Transform & Crop ──
  _AdjustCategory(icon: Icons.open_with, label: 'Transform', needsVideo: true, params: [
    _SubParam(label: 'Pos X', suffix: 'px', kind: _ParamKind.clipProperty, clipField: 'posX',
      dial: _DialSpec(min: -1920, max: 1920, defaultValue: 0, minorStep: 1, majorStep: 50, pxPerTick: 2)),
    _SubParam(label: 'Pos Y', suffix: 'px', kind: _ParamKind.clipProperty, clipField: 'posY',
      dial: _DialSpec(min: -1080, max: 1080, defaultValue: 0, minorStep: 1, majorStep: 50, pxPerTick: 2)),
    _SubParam(label: 'Scale X', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'scaleX',
      dial: _DialSpec(min: 0.01, max: 10, defaultValue: 1, minorStep: 0.01, majorStep: 0.25, pxPerTick: 5)),
    _SubParam(label: 'Scale Y', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'scaleY',
      dial: _DialSpec(min: 0.01, max: 10, defaultValue: 1, minorStep: 0.01, majorStep: 0.25, pxPerTick: 5)),
    _SubParam(label: 'Rotation', suffix: '°', kind: _ParamKind.clipProperty, clipField: 'rotation',
      dial: _DialSpec(min: -360, max: 360, defaultValue: 0, minorStep: 0.5, majorStep: 15, pxPerTick: 3)),
  ]),
  _AdjustCategory(icon: Icons.crop, label: 'Crop', needsVideo: true, params: [
    _SubParam(label: 'Left', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'cropLeft',
      dial: _DialSpec(min: 0, max: 0.99, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Right', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'cropRight',
      dial: _DialSpec(min: 0, max: 0.99, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Top', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'cropTop',
      dial: _DialSpec(min: 0, max: 0.99, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Bottom', suffix: '%', kind: _ParamKind.clipProperty, clipField: 'cropBottom',
      dial: _DialSpec(min: 0, max: 0.99, defaultValue: 0, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
  ]),
  // ── Audio effects ──
  _AdjustCategory(icon: Icons.equalizer, label: 'EQ', needsAudio: true, params: [
    _SubParam(label: 'Low', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioEq, effectParam: 'lowGain',
      dial: _DialSpec(min: -20, max: 20, defaultValue: 0, minorStep: 0.5, majorStep: 5, pxPerTick: 4)),
    _SubParam(label: 'Mid', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioEq, effectParam: 'midGain',
      dial: _DialSpec(min: -20, max: 20, defaultValue: 0, minorStep: 0.5, majorStep: 5, pxPerTick: 4)),
    _SubParam(label: 'High', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioEq, effectParam: 'highGain',
      dial: _DialSpec(min: -20, max: 20, defaultValue: 0, minorStep: 0.5, majorStep: 5, pxPerTick: 4)),
    _SubParam(label: 'Low Freq', suffix: 'Hz', kind: _ParamKind.effectParam,
      effectType: EffectType.audioEq, effectParam: 'lowFreq',
      dial: _DialSpec(min: 60, max: 500, defaultValue: 200, minorStep: 5, majorStep: 50, pxPerTick: 3)),
    _SubParam(label: 'High Freq', suffix: 'Hz', kind: _ParamKind.effectParam,
      effectType: EffectType.audioEq, effectParam: 'highFreq',
      dial: _DialSpec(min: 1000, max: 10000, defaultValue: 3000, minorStep: 50, majorStep: 500, pxPerTick: 2)),
  ]),
  _AdjustCategory(icon: Icons.compress, label: 'Compress', needsAudio: true, params: [
    _SubParam(label: 'Threshold', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioCompressor, effectParam: 'threshold',
      dial: _DialSpec(min: -60, max: 0, defaultValue: -20, minorStep: 0.5, majorStep: 5, pxPerTick: 3)),
    _SubParam(label: 'Ratio', kind: _ParamKind.effectParam,
      effectType: EffectType.audioCompressor, effectParam: 'ratio',
      dial: _DialSpec(min: 1, max: 20, defaultValue: 4, minorStep: 0.5, majorStep: 2, pxPerTick: 5)),
    _SubParam(label: 'Attack', suffix: 'ms', kind: _ParamKind.effectParam,
      effectType: EffectType.audioCompressor, effectParam: 'attack',
      dial: _DialSpec(min: 0.1, max: 200, defaultValue: 20, minorStep: 1, majorStep: 20, pxPerTick: 3)),
    _SubParam(label: 'Release', suffix: 'ms', kind: _ParamKind.effectParam,
      effectType: EffectType.audioCompressor, effectParam: 'release',
      dial: _DialSpec(min: 10, max: 2000, defaultValue: 250, minorStep: 10, majorStep: 100, pxPerTick: 2)),
    _SubParam(label: 'Makeup', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioCompressor, effectParam: 'makeup',
      dial: _DialSpec(min: 0, max: 30, defaultValue: 0, minorStep: 0.5, majorStep: 5, pxPerTick: 4)),
  ]),
  _AdjustCategory(icon: Icons.noise_aware, label: 'De-Noise', needsAudio: true, params: [
    _SubParam(label: 'Amount', kind: _ParamKind.effectParam,
      effectType: EffectType.audioNoiseReduction, effectParam: 'amount',
      dial: _DialSpec(min: 0, max: 40, defaultValue: 12, minorStep: 0.5, majorStep: 5, pxPerTick: 4)),
    _SubParam(label: 'Floor', suffix: 'dB', kind: _ParamKind.effectParam,
      effectType: EffectType.audioNoiseReduction, effectParam: 'floor',
      dial: _DialSpec(min: -60, max: 0, defaultValue: -30, minorStep: 0.5, majorStep: 5, pxPerTick: 3)),
  ]),
  _AdjustCategory(icon: Icons.spatial_audio, label: 'Reverb', needsAudio: true, params: [
    _SubParam(label: 'Room', kind: _ParamKind.effectParam,
      effectType: EffectType.audioReverb, effectParam: 'roomSize',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0.5, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Damping', kind: _ParamKind.effectParam,
      effectType: EffectType.audioReverb, effectParam: 'damping',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0.5, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Wet', kind: _ParamKind.effectParam,
      effectType: EffectType.audioReverb, effectParam: 'wetLevel',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0.3, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
    _SubParam(label: 'Dry', kind: _ParamKind.effectParam,
      effectType: EffectType.audioReverb, effectParam: 'dryLevel',
      dial: _DialSpec(min: 0, max: 1, defaultValue: 0.7, minorStep: 0.01, majorStep: 0.1, pxPerTick: 5)),
  ]),
];

class _PortraitAdjustPanel extends ConsumerStatefulWidget {
  const _PortraitAdjustPanel({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_PortraitAdjustPanel> createState() =>
      _PortraitAdjustPanelState();
}

class _PortraitAdjustPanelState extends ConsumerState<_PortraitAdjustPanel> {
  int _catIdx = 0;
  int _subIdx = 0;
  double? _liveValue;
  ClipModel? _clipAtDragStart;
  EffectInstance? _effectAtDragStart;

  List<_AdjustCategory> _filtered(ClipType type) =>
      _kAdjustCategories.where((c) => c.appliesTo(type)).toList();

  ClipModel? _selectedClip(TimelineState state) {
    final id = state.selectedClipIds.firstOrNull;
    if (id == null) return null;
    try { return state.clips.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  EffectInstance? _findEffect(TimelineState state, String clipId, EffectType type) {
    return state.effectsForClip(clipId).cast<EffectInstance?>().firstWhere(
      (e) => e!.type == type, orElse: () => null);
  }

  double _readClipField(ClipModel clip, String field) => switch (field) {
    'opacity' => clip.opacity,
    'speed' => clip.speed,
    'volume' => clip.volume,
    'posX' => clip.posX,
    'posY' => clip.posY,
    'scaleX' => clip.scaleX,
    'scaleY' => clip.scaleY,
    'rotation' => clip.rotation,
    'cropLeft' => clip.cropLeft,
    'cropRight' => clip.cropRight,
    'cropTop' => clip.cropTop,
    'cropBottom' => clip.cropBottom,
    _ => 0.0,
  };

  ClipModel _applyClipField(ClipModel clip, String field, double v) => switch (field) {
    'opacity' => clip.copyWith(opacity: v),
    'speed' => clip.copyWith(speed: v),
    'volume' => clip.copyWith(volume: v),
    'posX' => clip.copyWith(posX: v),
    'posY' => clip.copyWith(posY: v),
    'scaleX' => clip.copyWith(scaleX: v),
    'scaleY' => clip.copyWith(scaleY: v),
    'rotation' => clip.copyWith(rotation: v),
    'cropLeft' => clip.copyWith(cropLeft: v),
    'cropRight' => clip.copyWith(cropRight: v),
    'cropTop' => clip.copyWith(cropTop: v),
    'cropBottom' => clip.copyWith(cropBottom: v),
    _ => clip,
  };

  Future<void> _commitClipField(String clipId, String field, double v) async {
    if (!mounted) return;
    final ctrl = ref.read(timelineControllerProvider);
    switch (field) {
      case 'opacity': await ctrl.updateClipOpacity(clipId, v);
      case 'speed': await ctrl.updateClipSpeed(clipId, v);
      case 'volume': await ctrl.updateClipVolume(clipId, v);
      case 'posX': await ctrl.updateClipTransform(clipId, posX: v);
      case 'posY': await ctrl.updateClipTransform(clipId, posY: v);
      case 'scaleX': await ctrl.updateClipTransform(clipId, scaleX: v);
      case 'scaleY': await ctrl.updateClipTransform(clipId, scaleY: v);
      case 'rotation': await ctrl.updateClipTransform(clipId, rotation: v);
      case 'cropLeft': await ctrl.updateClipCrop(clipId, cropLeft: v);
      case 'cropRight': await ctrl.updateClipCrop(clipId, cropRight: v);
      case 'cropTop': await ctrl.updateClipCrop(clipId, cropTop: v);
      case 'cropBottom': await ctrl.updateClipCrop(clipId, cropBottom: v);
    }
  }

  double _currentValue(TimelineState state, ClipModel clip, _SubParam p) {
    if (!p.isEffect) return _readClipField(clip, p.clipField!);
    final effect = _findEffect(state, clip.id, p.effectType!);
    if (effect == null || !effect.isEnabled) return p.dial.defaultValue;
    return effect.parameters[p.effectParam!] ?? p.dial.defaultValue;
  }

  void _onDialChanged(ClipModel clip, double v, _SubParam p) {
    setState(() => _liveValue = v);
    final state = ref.read(timelineStateProvider);
    if (!p.isEffect) {
      state.updateClip(_applyClipField(clip, p.clipField!, v));
      return;
    }
    var effect = _findEffect(state, clip.id, p.effectType!);
    if (effect == null) {
      effect = EffectInstance(
        id: 'temp_${p.effectType!.name}_${clip.id}',
        clipId: clip.id,
        type: p.effectType!,
        stackIndex: state.effectsForClip(clip.id).length,
        parameters: EffectRegistry.defaultParameters(p.effectType!),
      );
      state.addEffect(effect);
    }
    final newParams = Map<String, double>.from(effect.parameters);
    newParams[p.effectParam!] = v;
    state.updateEffect(effect.copyWith(parameters: newParams));
  }

  Future<void> _onDialEnd(ClipModel clip, double v, _SubParam p) async {
    if (!mounted) return;
    final state = ref.read(timelineStateProvider);
    final ctrl = ref.read(timelineControllerProvider);
    if (!p.isEffect) {
      if (_clipAtDragStart != null) {
        await _commitClipField(clip.id, p.clipField!, v);
      }
    } else {
      final effect = _findEffect(state, clip.id, p.effectType!);
      if (effect != null) {
        final isTempId = effect.id.startsWith('temp_');
        if (isTempId) {
          state.removeEffect(effect);
          final created = await ctrl.addEffect(clip.id, p.effectType!);
          if (!mounted) return;
          if (created != null) {
            final newParams = Map<String, double>.from(created.parameters);
            newParams[p.effectParam!] = v;
            await ctrl.updateEffectParameters(created, newParams);
          }
        } else {
          final newParams = Map<String, double>.from(effect.parameters);
          newParams[p.effectParam!] = v;
          await ctrl.updateEffectParameters(
            _effectAtDragStart ?? effect, newParams);
        }
      }
    }
    _clipAtDragStart = null;
    _effectAtDragStart = null;
    if (mounted) setState(() => _liveValue = null);
  }

  void _resetToDefault(ClipModel clip, _SubParam p) {
    _clipAtDragStart = clip;
    if (p.isEffect) {
      _effectAtDragStart = _findEffect(
        ref.read(timelineStateProvider), clip.id, p.effectType!);
    }
    _onDialChanged(clip, p.dial.defaultValue, p);
    _onDialEnd(clip, p.dial.defaultValue, p);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineStateProvider);
    final clip = _selectedClip(state);
    if (clip == null) {
      return Container(
        color: ColorTokens.backgroundPanel,
        child: const Center(
          child: Text('Select a clip to adjust',
            style: TextStyle(color: ColorTokens.textSecondary, fontSize: 13)),
        ),
      );
    }

    final cats = _filtered(clip.type);
    if (_catIdx >= cats.length) _catIdx = 0;
    final cat = cats[_catIdx];
    if (_subIdx >= cat.params.length) _subIdx = 0;
    final param = cat.params[_subIdx];
    final val = _liveValue ?? _currentValue(state, clip, param);
    final isDefault = (val - param.dial.defaultValue).abs() < param.dial.minorStep * 0.5;

    return Container(
      color: ColorTokens.backgroundPanel,
      child: Column(
        children: [
          const SizedBox(height: 6),
          // Value display
          GestureDetector(
            onDoubleTap: () => _resetToDefault(clip, param),
            child: Column(
              children: [
                Text(param.label.toUpperCase(),
                  style: const TextStyle(color: ColorTokens.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(param.formatValue(val),
                      style: TextStyle(
                        color: isDefault ? ColorTokens.textPrimary : const Color(0xFFFFD60A),
                        fontSize: 28, fontWeight: FontWeight.w300,
                        fontFamily: 'SF Pro Display', letterSpacing: -0.5)),
                    if (param.suffix.isNotEmpty)
                      Text(param.suffix,
                        style: TextStyle(
                          color: isDefault ? ColorTokens.textSecondary
                              : const Color(0xFFFFD60A).withValues(alpha: 0.7),
                          fontSize: 16, fontWeight: FontWeight.w400,
                          fontFamily: 'SF Pro Display')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Dial
          SizedBox(
            height: AppConstants.dialHeight,
            child: _AdjustDial(
              value: val,
              spec: param.dial,
              onChangeStart: () {
                _clipAtDragStart = clip;
                if (param.isEffect) {
                  _effectAtDragStart = _findEffect(state, clip.id, param.effectType!);
                }
              },
              onChanged: (v) => _onDialChanged(clip, v, param),
              onChangeEnd: (v) => _onDialEnd(clip, v, param),
            ),
          ),
          const SizedBox(height: 6),
          // Sub-param chips (only if category has >1 param)
          if (cat.params.length > 1)
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cat.params.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sub = cat.params[i];
                  final active = i == _subIdx;
                  return GestureDetector(
                    onTap: () => setState(() { _subIdx = i; _liveValue = null; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFFD60A).withValues(alpha: 0.15)
                            : ColorTokens.backgroundSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? const Color(0xFFFFD60A) : ColorTokens.borderSubtle),
                      ),
                      child: Text(sub.label,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: active ? const Color(0xFFFFD60A) : ColorTokens.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          if (cat.params.length <= 1) const SizedBox(height: 28),
          const SizedBox(height: 6),
          // Category icons with labels
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final c = cats[i];
                final active = i == _catIdx;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _catIdx = i; _subIdx = 0; _liveValue = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36, height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: active
                                ? ColorTokens.textPrimary.withValues(alpha: 0.12)
                                : Colors.transparent),
                          child: Icon(c.icon, size: 20,
                            color: active ? ColorTokens.textPrimary : ColorTokens.textSecondary),
                        ),
                        const SizedBox(height: 3),
                        Text(c.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: active ? const Color(0xFFFFD60A) : ColorTokens.textSecondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ── Apple Photos-style scrollable dial ──────────────────────────────────────

class _AdjustDial extends StatefulWidget {
  const _AdjustDial({
    required this.value,
    required this.spec,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final _DialSpec spec;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_AdjustDial> createState() => _AdjustDialState();
}

class _AdjustDialState extends State<_AdjustDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _momentum;
  int _lastMajorTick = 0;

  @override
  void initState() {
    super.initState();
    _momentum = AnimationController.unbounded(vsync: this);
    _momentum.addListener(_onMomentumTick);
  }

  @override
  void dispose() {
    _momentum.dispose();
    super.dispose();
  }

  void _onMomentumTick() {
    final clamped = _momentum.value.clamp(widget.spec.min, widget.spec.max);
    _checkHaptic(clamped);
    widget.onChanged(clamped);
    if (clamped != _momentum.value) {
      _momentum.stop();
      widget.onChangeEnd(clamped);
    }
  }

  void _checkHaptic(double value) {
    final majorIdx = (value / widget.spec.majorStep).round();
    if (majorIdx != _lastMajorTick) {
      _lastMajorTick = majorIdx;
      HapticFeedback.selectionClick();
    }
  }

  double get _pxPerUnit => widget.spec.pxPerTick / widget.spec.minorStep;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) {
        _momentum.stop();
        _lastMajorTick = (widget.value / widget.spec.majorStep).round();
        widget.onChangeStart();
      },
      onHorizontalDragUpdate: (d) {
        final delta = -(d.primaryDelta ?? 0);
        final newVal =
            (widget.value + delta / _pxPerUnit)
                .clamp(widget.spec.min, widget.spec.max);
        _checkHaptic(newVal);
        widget.onChanged(newVal);
      },
      onHorizontalDragEnd: (d) {
        final velocity = -(d.primaryVelocity ?? 0);
        if (velocity.abs() > 200) {
          _momentum.value = widget.value;
          _momentum.animateWith(
            FrictionSimulation(
              0.135,
              widget.value,
              velocity / _pxPerUnit,
            ),
          ).whenCompleteOrCancel(() {
            final clamped =
                _momentum.value.clamp(widget.spec.min, widget.spec.max);
            widget.onChangeEnd(clamped);
          });
        } else {
          widget.onChangeEnd(widget.value);
        }
      },
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.12, 0.88, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: CustomPaint(
          size: const Size(double.infinity, AppConstants.dialHeight),
          painter: _DialPainter(
            value: widget.value,
            spec: widget.spec,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.value, required this.spec});

  final double value;
  final _DialSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final pxPerUnit = spec.pxPerTick / spec.minorStep;

    final minorPaint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final majorPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final defaultPaint = Paint()
      ..color = const Color(0xFFFFD60A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final visibleHalf = size.width / 2 + spec.majorStep * pxPerUnit;
    final startVal = value - visibleHalf / pxPerUnit;
    final endVal = value + visibleHalf / pxPerUnit;

    double tick = (startVal / spec.minorStep).floorToDouble() * spec.minorStep;

    while (tick <= endVal) {
      if (tick >= spec.min - spec.minorStep * 0.5 &&
          tick <= spec.max + spec.minorStep * 0.5) {
        final x = centerX + (tick - value) * pxPerUnit;
        final distFromCenter = (x - centerX).abs() / (size.width / 2);
        final alpha = (1.0 - distFromCenter * 0.6).clamp(0.3, 1.0);

        final isMajor =
            ((tick / spec.majorStep).round() * spec.majorStep - tick).abs() <
                spec.minorStep * 0.01;
        final isDefault = (tick - spec.defaultValue).abs() <
            spec.minorStep * 0.3;

        if (isDefault) {
          defaultPaint.color =
              const Color(0xFFFFD60A).withValues(alpha: alpha);
          canvas.drawLine(
            Offset(x, centerY - 16),
            Offset(x, centerY + 16),
            defaultPaint,
          );
        } else if (isMajor) {
          majorPaint.color =
              const Color(0xFF8A8A8E).withValues(alpha: alpha);
          canvas.drawLine(
            Offset(x, centerY - 13),
            Offset(x, centerY + 13),
            majorPaint,
          );
        } else {
          minorPaint.color =
              const Color(0xFF48484A).withValues(alpha: alpha);
          canvas.drawLine(
            Offset(x, centerY - 7),
            Offset(x, centerY + 7),
            minorPaint,
          );
        }
      }
      tick += spec.minorStep;
    }

    final indicatorPaint = Paint()
      ..color = const Color(0xFFFFD60A)
      ..style = PaintingStyle.fill;

    final trianglePath = Path()
      ..moveTo(centerX - 5, centerY - 20)
      ..lineTo(centerX + 5, centerY - 20)
      ..lineTo(centerX, centerY - 14)
      ..close();
    canvas.drawPath(trianglePath, indicatorPaint);

    canvas.drawLine(
      Offset(centerX, centerY - 14),
      Offset(centerX, centerY + 14),
      Paint()
        ..color = const Color(0xFFFFD60A).withValues(alpha: 0.4)
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value || old.spec != spec;
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
