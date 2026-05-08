enum HelpCategory { timeline, playback, editing, tools, mobile }

class HelpEntry {
  const HelpEntry({
    required this.category,
    required this.title,
    required this.description,
    this.shortcut,
    this.icon,
  });

  final HelpCategory category;
  final String title;
  final String description;
  final String? shortcut;
  final String? icon;
}

abstract final class HelpData {
  static const List<HelpEntry> entries = [
    // ── Playback ────────────────────────────────────────────────────────────
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Play / Pause',
      description: 'Start or stop playback of your project.',
      shortcut: 'Space',
      icon: '▶',
    ),
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Skip to Start',
      description: 'Jump the playhead to the very beginning of the timeline.',
      icon: '⏮',
    ),
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Skip to End',
      description: 'Jump the playhead to the end of the last clip.',
      icon: '⏭',
    ),
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Step Back One Frame',
      description: 'Move the playhead one frame earlier.',
      shortcut: 'J',
    ),
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Pause',
      description: 'Pause playback without moving the playhead.',
      shortcut: 'K',
    ),
    HelpEntry(
      category: HelpCategory.playback,
      title: 'Step Forward One Frame',
      description: 'Move the playhead one frame later.',
      shortcut: 'L',
    ),

    // ── Tools ───────────────────────────────────────────────────────────────
    HelpEntry(
      category: HelpCategory.tools,
      title: 'Select Tool',
      description:
          'Move and trim clips. Tap a clip to select it; drag to reposition.',
      shortcut: 'V',
      icon: '↖',
    ),
    HelpEntry(
      category: HelpCategory.tools,
      title: 'Blade / Cut Tool',
      description:
          'Click anywhere on a clip to split it at that point. '
          'Press B on desktop or tap the scissors icon in the toolbar.',
      shortcut: 'B',
      icon: '✂',
    ),
    HelpEntry(
      category: HelpCategory.tools,
      title: 'Snap',
      description:
          'When enabled, clip edges snap to the playhead and other clip '
          'boundaries as you drag. Toggle with the magnet icon in the toolbar.',
    ),

    // ── Timeline ────────────────────────────────────────────────────────────
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Add Clip to Timeline',
      description:
          'Tap the ⊕ button on any media tile, or double-tap the tile, '
          'to place that clip at the end of the video track.',
      icon: '⊕',
    ),
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Scroll Timeline',
      description:
          'Swipe left/right on empty track space to scroll. '
          'On desktop use the mouse wheel. Two-finger swipe also works.',
    ),
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Trim Clip',
      description:
          'Drag the left or right edge handle of a clip to shorten or '
          'lengthen it. The coloured handle highlights when active.',
    ),
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Seek (Scrub)',
      description:
          'Drag horizontally along the ruler at the top of the timeline '
          'to move the playhead to any point in time.',
    ),
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Clip Context Menu',
      description:
          'Long-press (mobile) or right-click (desktop) a clip to open a '
          'menu with quick actions: Edit, Split at Playhead, Duplicate, Delete.',
    ),
    HelpEntry(
      category: HelpCategory.timeline,
      title: 'Frame Thumbnails',
      description:
          'Video clips show real frames from your video tiled across the '
          'clip body, so you can see at a glance what is at each point in time.',
    ),

    // ── Editing ─────────────────────────────────────────────────────────────
    HelpEntry(
      category: HelpCategory.editing,
      title: 'Undo',
      description: 'Reverse the last action.',
      shortcut: 'Cmd+Z',
      icon: '↩',
    ),
    HelpEntry(
      category: HelpCategory.editing,
      title: 'Redo',
      description: 'Re-apply the last undone action.',
      shortcut: 'Cmd+Shift+Z',
      icon: '↪',
    ),
    HelpEntry(
      category: HelpCategory.editing,
      title: 'Split at Playhead',
      description: 'Cut the selected clip at the current playhead position.',
      shortcut: 'Cmd+B',
    ),
    HelpEntry(
      category: HelpCategory.editing,
      title: 'Delete Clip',
      description:
          'Remove the selected clip and pull subsequent clips left to '
          'close the gap (ripple delete).',
      shortcut: 'Delete / Backspace',
    ),
    HelpEntry(
      category: HelpCategory.editing,
      title: 'Clear Selection',
      description: 'Deselect all clips and return to the Select tool.',
      shortcut: 'Esc',
    ),

    // ── Mobile ──────────────────────────────────────────────────────────────
    HelpEntry(
      category: HelpCategory.mobile,
      title: 'Media / Preview Tabs',
      description:
          'On mobile, the top panel switches between your media library '
          '(to add clips) and the video preview.',
    ),
    HelpEntry(
      category: HelpCategory.mobile,
      title: 'Edit Clip (Inspector)',
      description:
          'Select a clip on the timeline, then tap the tune ⋮ button '
          'that appears — it opens the Inspector where you can adjust opacity, '
          'speed, effects, transitions, and keyframe animation.',
      icon: '⋮',
    ),
    HelpEntry(
      category: HelpCategory.mobile,
      title: 'Export',
      description:
          'Tap Export in the top bar to choose a quality preset and '
          'render your project to a video file using on-device FFmpeg.',
    ),
  ];

  static List<HelpEntry> entriesForCategory(HelpCategory category) =>
      entries.where((e) => e.category == category).toList();

  static const List<HelpCategory> categoryOrder = [
    HelpCategory.timeline,
    HelpCategory.playback,
    HelpCategory.tools,
    HelpCategory.editing,
    HelpCategory.mobile,
  ];

  static String categoryLabel(HelpCategory category) {
    switch (category) {
      case HelpCategory.timeline:
        return 'Timeline';
      case HelpCategory.playback:
        return 'Playback';
      case HelpCategory.tools:
        return 'Tools';
      case HelpCategory.editing:
        return 'Editing';
      case HelpCategory.mobile:
        return 'Mobile';
    }
  }
}
