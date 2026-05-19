import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/features/editor/editor_screen.dart';
import 'package:prepstation/features/media_browser/project_browser_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String editor = '/editor/:projectId';
  static const String editorRoot = '/editor';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ProjectBrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.editor,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return EditorScreen(projectId: projectId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
