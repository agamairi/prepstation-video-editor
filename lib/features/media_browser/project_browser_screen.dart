import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

final _projectListProvider = FutureProvider<List<ProjectModel>>((ref) {
  return ref.watch(projectRepositoryProvider).getAllProjects();
});

class ProjectBrowserScreen extends ConsumerWidget {
  const ProjectBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(_projectListProvider);

    return Scaffold(
      backgroundColor: ColorTokens.backgroundDeep,
      body: CustomScrollView(
        slivers: [
          _AppHeader(onCreateProject: () => _createProject(context, ref)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            sliver: projectsAsync.when(
              data: (projects) => projects.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyState(
                        onCreateProject: () => _createProject(context, ref),
                      ),
                    )
                  : _ProjectSliverGrid(projects: projects),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  heightFactor: 8,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Failed to load projects: $e',
                      style: AppTypography.bodyMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: 'Untitled Project');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project', style: AppTypography.headlineMedium),
        content: TextField(
          controller: nameController,
          style: AppTypography.bodyLarge,
          decoration: const InputDecoration(labelText: 'Project name'),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final projectName = nameController.text.trim().isEmpty
        ? 'Untitled Project'
        : nameController.text.trim();

    final project = ProjectModel.create(
      name: projectName,
      filePath: '${appDocDir.path}/fluxedit/$projectName.fluxedit',
    );

    await ref.read(projectRepositoryProvider).saveProject(project);
    ref.invalidate(_projectListProvider);

    if (context.mounted) {
      unawaited(context.push('/editor/${project.id}'));
    }
  }
}

// ── Sliver app header ─────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 52, 28, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A84FF), Color(0xFFBF5AF2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('PrepStation', style: AppTypography.headlineLarge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Professional video editing, beautifully simple',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            _NewProjectButton(onPressed: onCreateProject),
          ],
        ),
      ),
    );
  }
}

class _NewProjectButton extends StatelessWidget {
  const _NewProjectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: ColorTokens.accentPrimary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'New Project',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1C1F), Color(0xFF2C2C30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorTokens.borderDefault),
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 32,
                color: ColorTokens.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            const Text('No projects yet', style: AppTypography.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Create your first project to get started',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 28),
            _NewProjectButton(onPressed: onCreateProject),
          ],
        ),
      ),
    );
  }
}

// ── Project grid ──────────────────────────────────────────────────────────────

class _ProjectSliverGrid extends ConsumerWidget {
  const _ProjectSliverGrid({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _ProjectCard(
          project: projects[i],
          onDelete: () async {
            await ref
                .read(projectRepositoryProvider)
                .deleteProject(projects[i].id);
            ref.invalidate(_projectListProvider);
          },
        ),
        childCount: projects.length,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────────

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project, required this.onDelete});

  final ProjectModel project;
  final VoidCallback onDelete;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  LinearGradient _gradient(String id) {
    final index = id.hashCode.abs() % ColorTokens.projectGradients.length;
    final colors = ColorTokens.projectGradients[index];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final gradient = _gradient(project.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: () => context.push('/editor/${project.id}'),
          onSecondaryTapDown: (details) => _showContextMenu(
            context,
            details.globalPosition,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: ColorTokens.backgroundPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? ColorTokens.borderDefault
                    : ColorTokens.borderSubtle,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 36,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: AppTypography.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${project.composition.width}×'
                            '${project.composition.height}',
                            style: AppTypography.labelSmall,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('·', style: AppTypography.labelSmall),
                          ),
                          Text(
                            _relativeDate(project.dateModified),
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: ColorTokens.error),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'open' && context.mounted) {
        context.push('/editor/${widget.project.id}');
      } else if (value == 'delete') {
        widget.onDelete();
      }
    });
  }
}
