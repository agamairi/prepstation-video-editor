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
      appBar: AppBar(
        backgroundColor: ColorTokens.backgroundPanel,
        title: const Text(
          'FluxEdit',
          style: AppTypography.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New Project',
            onPressed: () => _createProject(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) => projects.isEmpty
            ? _EmptyState(onCreateProject: () => _createProject(context, ref))
            : _ProjectGrid(projects: projects),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load projects: $e',
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    );
  }

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(
      text: 'Untitled Project',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.backgroundPanel,
        title: const Text('New Project', style: AppTypography.headlineMedium),
        content: TextField(
          controller: nameController,
          style: AppTypography.bodyLarge,
          decoration: const InputDecoration(
            labelText: 'Project Name',
          ),
          autofocus: true,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.movie_creation_outlined,
            size: 80,
            color: ColorTokens.textDisabled,
          ),
          const SizedBox(height: 24),
          const Text(
            'No projects yet',
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new project to get started',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onCreateProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Project'),
          ),
        ],
      ),
    );
  }
}

class _ProjectGrid extends ConsumerWidget {
  const _ProjectGrid({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 180,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: projects.length,
      itemBuilder: (context, i) => _ProjectCard(project: projects[i]),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/editor/${project.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: ColorTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorTokens.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: ColorTokens.backgroundSurface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.movie,
                    size: 40,
                    color: ColorTokens.accentPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.composition.width}×'
                    '${project.composition.height} · '
                    '${project.composition.frameRateDisplay} fps',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
