import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_registry.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/keyframes/animated_property.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';
import 'package:prepstation/core/segmentation/segmentation_service.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/timeline/timeline_tool.dart';
import 'package:prepstation/core/tracker/tracker_model.dart';
import 'package:prepstation/core/transitions/transition_type.dart';
import 'package:google_fonts/google_fonts.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);
    final selectedIds = timelineState.selectedClipIds;

    return Container(
      color: ColorTokens.inspectorBackground,
      child: Column(
        children: [
          const _PanelHeader(),
          Expanded(
            child: selectedIds.isEmpty
                ? const _NoSelectionPlaceholder()
                : _ClipInspector(
                    clipId: selectedIds.first,
                    projectId: projectId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          bottom: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.tune, size: 13, color: ColorTokens.textDisabled),
          SizedBox(width: 6),
          Text('Inspector', style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}

class _NoSelectionPlaceholder extends StatelessWidget {
  const _NoSelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 28, color: ColorTokens.textDisabled),
          SizedBox(height: 10),
          Text('Select a clip to edit', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _ClipInspector extends ConsumerStatefulWidget {
  const _ClipInspector({
    required this.clipId,
    required this.projectId,
  });

  final String clipId;
  final String projectId;

  @override
  ConsumerState<_ClipInspector> createState() => _ClipInspectorState();
}

class _ClipInspectorState extends ConsumerState<_ClipInspector> {
  late TextEditingController _nameController;
  ClipModel? _clipAtDragStart;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ClipModel? _findClip() {
    final clips = ref.read(timelineStateProvider).clips;
    try {
      return clips.firstWhere((c) => c.id == widget.clipId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineStateProvider);
    final ClipModel? clip = timelineState.clips
        .cast<ClipModel?>()
        .firstWhere(
          (ClipModel? c) => c?.id == widget.clipId,
          orElse: () => null,
        );

    if (clip == null) return const SizedBox();

    // Sync name field when clip changes externally
    if (_nameController.text != clip.name) {
      _nameController.text = clip.name;
    }

    return FutureBuilder<MediaAsset?>(
      future:
          ref.read(projectRepositoryProvider).getMediaAsset(clip.mediaId),
      builder: (context, snap) {
        final asset = snap.data;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _SectionHeader(title: 'Clip'),
            _NameField(controller: _nameController, onSubmit: _onNameSubmit),
            _PropertyRow(
              label: 'Duration',
              value: _formatDuration(clip.duration),
            ),
            _PropertyRow(
              label: 'Start',
              value: _formatDuration(clip.startOnTimeline),
            ),
            _PropertyRow(
              label: 'End',
              value: _formatDuration(clip.endOnTimeline),
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: 'Speed',
              value: clip.speed,
              min: AppConstants.minClipSpeed,
              max: AppConstants.maxClipSpeed,
              displayText: '${clip.speed.toStringAsFixed(2)}x',
              onChangeStart: (_) => _clipAtDragStart = _findClip(),
              onChangeEnd: (v) {
                if (_clipAtDragStart != null) {
                  ref.read(timelineControllerProvider).updateClipSpeed(
                    widget.clipId,
                    v,
                  );
                  _clipAtDragStart = null;
                }
              },
              onChanged: (v) {
                // Live preview without committing to history
                final c = _findClip();
                if (c != null) {
                  ref.read(timelineStateProvider).updateClip(
                    c.copyWith(speed: v),
                  );
                }
              },
            ),
            _SliderRow(
              label: 'Opacity',
              value: timelineState.evaluateParameter(
                widget.clipId,
                AnimatedProperty.opacity,
                timelineState.playhead,
                clip.opacity,
              ),
              min: 0,
              max: 1,
              displayText:
                  '${(timelineState.evaluateParameter(widget.clipId, AnimatedProperty.opacity, timelineState.playhead, clip.opacity) * 100).toStringAsFixed(0)}%',
              keyframeDiamond: _KeyframeDiamond(
                isFilled: timelineState.hasKeyframeAt(
                  widget.clipId,
                  AnimatedProperty.opacity,
                  timelineState.playhead,
                ),
                onTap: () {
                  final controller =
                      ref.read(timelineControllerProvider);
                  if (timelineState.hasKeyframeAt(
                    widget.clipId,
                    AnimatedProperty.opacity,
                    timelineState.playhead,
                  )) {
                    controller.removeKeyframeAtPlayhead(
                      widget.clipId,
                      AnimatedProperty.opacity,
                    );
                  } else {
                    controller.setKeyframe(
                      widget.clipId,
                      AnimatedProperty.opacity,
                      clip.opacity,
                    );
                  }
                },
              ),
              onChangeStart: (_) => _clipAtDragStart = _findClip(),
              onChangeEnd: (v) {
                if (_clipAtDragStart != null) {
                  final controller =
                      ref.read(timelineControllerProvider);
                  if (timelineState.hasKeyframeAt(
                    widget.clipId,
                    AnimatedProperty.opacity,
                    timelineState.playhead,
                  )) {
                    controller.setKeyframe(
                      widget.clipId,
                      AnimatedProperty.opacity,
                      v,
                    );
                  } else {
                    controller.updateClipOpacity(widget.clipId, v);
                  }
                  _clipAtDragStart = null;
                }
              },
              onChanged: (v) {
                final c = _findClip();
                if (c != null) {
                  ref
                      .read(timelineStateProvider)
                      .updateClip(c.copyWith(opacity: v));
                }
              },
            ),
            if (asset != null) ...[
              const SizedBox(height: 12),
              const _SectionHeader(title: 'Source'),
              _PropertyRow(label: 'Resolution', value: asset.resolution),
              _PropertyRow(
                label: 'Frame Rate',
                value: '${asset.frameRateDisplay} fps',
              ),
              _PropertyRow(label: 'Video Codec', value: asset.videoCodec),
              _PropertyRow(label: 'Audio Codec', value: asset.audioCodec),
              _PropertyRow(label: 'Color Space', value: asset.colorSpace),
            ],
            if (clip.type == ClipType.title) ...[
              const SizedBox(height: 12),
              _TitleSection(clip: clip),
            ],
            if (clip.type == ClipType.colorCard) ...[
              const SizedBox(height: 12),
              _ColorCardSection(clip: clip),
            ],
            if (clip.type == ClipType.image) ...[
              const SizedBox(height: 12),
              _ImageClipSection(clip: clip),
            ],
            // Volume (for video/audio clips)
            if (clip.type == ClipType.video || clip.type == ClipType.audio) ...[
              _SliderRow(
                label: 'Volume',
                value: clip.volume,
                min: AppConstants.minVolume,
                max: AppConstants.maxVolume,
                displayText: '${(clip.volume * 100).toStringAsFixed(0)}%',
                onChangeStart: (_) => _clipAtDragStart = _findClip(),
                onChangeEnd: (v) {
                  if (_clipAtDragStart != null) {
                    ref.read(timelineControllerProvider).updateClipVolume(
                      widget.clipId, v,
                    );
                    _clipAtDragStart = null;
                  }
                },
                onChanged: (v) {
                  final c = _findClip();
                  if (c != null) {
                    ref.read(timelineStateProvider).updateClip(
                      c.copyWith(volume: v),
                    );
                  }
                },
              ),
            ],
            if (clip.type == ClipType.video || clip.type == ClipType.image) ...[
              const SizedBox(height: 12),
              _TransformSection(clip: clip),
              const SizedBox(height: 12),
              _CropSection(clip: clip),
            ],
            if (clip.type == ClipType.video) ...[
              const SizedBox(height: 12),
              _ClipFlagsSection(clip: clip),
              const SizedBox(height: 12),
              _SubjectIsolationSection(clip: clip),
              const SizedBox(height: 12),
              _TrackerSection(clip: clip),
            ],
            const SizedBox(height: 12),
            _EffectsSection(clipId: clip.id),
            if (clip.type == ClipType.video) ...[
              const SizedBox(height: 12),
              _TransitionSection(clip: clip),
            ],
          ],
        );
      },
    );
  }

  void _onNameSubmit(String name) {
    ref.read(timelineControllerProvider).updateClipName(widget.clipId, name);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ms = d.inMilliseconds.remainder(1000);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: ColorTokens.accentPrimary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text('Name', style: AppTypography.labelMedium),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.bodySmall
                  .copyWith(color: ColorTokens.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                filled: true,
                fillColor: ColorTokens.backgroundSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: ColorTokens.borderSubtle,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: ColorTokens.borderSubtle,
                  ),
                ),
              ),
              onSubmitted: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayText,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
    this.keyframeDiamond,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayText;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final Widget? keyframeDiamond;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(label, style: AppTypography.labelMedium),
              ),
              Text(
                displayText,
                style: AppTypography.bodySmall
                    .copyWith(color: ColorTokens.textPrimary),
              ),
              if (keyframeDiamond != null) ...[
                const Spacer(),
                keyframeDiamond!,
              ],
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
              activeTrackColor: ColorTokens.accentPrimary,
              thumbColor: ColorTokens.accentPrimary,
              overlayColor:
                  ColorTokens.accentPrimary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Keyframe Diamond Button ───────────────────────────────────────────────────

class _KeyframeDiamond extends StatelessWidget {
  const _KeyframeDiamond({required this.isFilled, required this.onTap});

  final bool isFilled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(painter: _DiamondPainter(filled: isFilled)),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.35;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    const color = ColorTokens.accentPrimary;
    if (filled) {
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.filled != filled;
}

// ── Effects Section ───────────────────────────────────────────────────────────

class _EffectsSection extends ConsumerWidget {
  const _EffectsSection({required this.clipId});

  final String clipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final effects = state.effectsForClip(clipId);
    final controller = ref.read(timelineControllerProvider);
    final canAdd = effects.length < AppConstants.maxEffectsPerClip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Effects')),
            if (canAdd)
              _AddEffectButton(
                onSelected: (type) => controller.addEffect(clipId, type),
              ),
          ],
        ),
        if (effects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No effects applied',
              style: AppTypography.bodySmall.copyWith(
                color: ColorTokens.textSecondary,
              ),
            ),
          ),
        ...effects.map((e) => _EffectRow(effect: e)),
      ],
    );
  }
}

class _AddEffectButton extends StatelessWidget {
  const _AddEffectButton({required this.onSelected});

  final void Function(EffectType) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EffectType>(
      icon: const Icon(Icons.add, size: 16, color: ColorTokens.accentPrimary),
      tooltip: 'Add Effect',
      padding: EdgeInsets.zero,
      itemBuilder: (_) => EffectType.values.map(
            (t) => PopupMenuItem(
              value: t,
              child: Text(t.displayName, style: AppTypography.bodySmall),
            ),
          )
          .toList(),
      onSelected: onSelected,
    );
  }
}

class _EffectRow extends ConsumerStatefulWidget {
  const _EffectRow({required this.effect});

  final EffectInstance effect;

  @override
  ConsumerState<_EffectRow> createState() => _EffectRowState();
}

class _EffectRowState extends ConsumerState<_EffectRow> {
  EffectInstance? _atDragStart;

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final controller = ref.read(timelineControllerProvider);
    final ranges = EffectRegistry.parameterRanges(effect.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Effect header row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => controller.toggleEffect(effect),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      color: effect.isEnabled
                          ? ColorTokens.accentPrimary
                          : ColorTokens.backgroundElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: effect.isEnabled
                            ? ColorTokens.accentPrimary
                            : ColorTokens.borderStrong,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 150),
                      alignment: effect.isEnabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effect.displayName,
                    style: AppTypography.labelMedium.copyWith(
                      color: effect.isEnabled
                          ? ColorTokens.textPrimary
                          : ColorTokens.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(10),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: ColorTokens.textSecondary,
                  tooltip: 'Remove Effect',
                  onPressed: () => controller.removeEffect(effect),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),
          if (effect.isEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: ranges.entries.map((entry) {
                  final key = entry.key;
                  final (min, max) = entry.value;
                  final value =
                      (effect.parameters[key] ?? min).clamp(min, max);
                  return _SliderRow(
                    label: _formatParamName(key),
                    value: value,
                    min: min,
                    max: max,
                    displayText: value.toStringAsFixed(2),
                    onChangeStart: (_) => _atDragStart = effect,
                    onChanged: (v) {
                      final updated = effect.copyWith(
                        parameters: {...effect.parameters, key: v},
                      );
                      ref.read(timelineStateProvider).updateEffect(updated);
                    },
                    onChangeEnd: (v) {
                      if (_atDragStart != null) {
                        controller.updateEffectParameters(
                          _atDragStart!,
                          {..._atDragStart!.parameters, key: v},
                        );
                        _atDragStart = null;
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatParamName(String key) {
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}

// ── Curated font list ─────────────────────────────────────────────────────────

const _kFontFamilies = [
  'Roboto',
  'Montserrat',
  'Poppins',
  'Inter',
  'Oswald',
  'Raleway',
  'Nunito',
  'Bebas Neue',
  'Playfair Display',
  'Dancing Script',
  'Permanent Marker',
  'Anton',
];

// ── Shared text-style controls (used by Title and ColorCard sections) ─────────

class _TextStyleControls extends ConsumerStatefulWidget {
  const _TextStyleControls({required this.clip});

  final ClipModel clip;

  @override
  ConsumerState<_TextStyleControls> createState() => _TextStyleControlsState();
}

class _TextStyleControlsState extends ConsumerState<_TextStyleControls> {
  late TextEditingController _textController;
  ClipModel? _clipAtDragStart;

  static const _presetColors = [
    0xFFFFFFFF, // white
    0xFF000000, // black
    0xFFFF5252, // red
    0xFFFFB340, // orange
    0xFFFFEB3B, // yellow
    0xFF34C47A, // green
    0xFF4D9CFF, // blue
    0xFF9B6DFF, // purple
    0xFFFF6B9D, // pink
    0xFF40D9F3, // cyan
  ];

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.clip.titleText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  ClipModel? _latestClip() {
    try {
      return ref
          .read(timelineStateProvider)
          .clips
          .firstWhere((c) => c.id == widget.clip.id);
    } catch (_) {
      return null;
    }
  }

  TextStyle _fontPreviewStyle(String family) {
    const base = TextStyle(fontSize: 13, color: ColorTokens.textPrimary);
    try {
      return GoogleFonts.getFont(family, textStyle: base);
    } catch (_) {
      return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == widget.clip.id,
                orElse: () => null) ??
        widget.clip;

    if (_textController.text != (clip.titleText ?? '')) {
      _textController.text = clip.titleText ?? '';
    }

    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text content
        _labeledRow(
          'Text',
          TextField(
            controller: _textController,
            style: AppTypography.bodySmall
                .copyWith(color: ColorTokens.textPrimary),
            decoration: _inputDecoration(),
            onSubmitted: (v) => controller.updateTitleText(clip.id, v),
          ),
        ),
        // Font family
        _labeledRow(
          'Font',
          DropdownButtonHideUnderline(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: ColorTokens.backgroundSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ColorTokens.borderSubtle),
              ),
              child: DropdownButton<String>(
                value: _kFontFamilies.contains(clip.fontFamily)
                    ? clip.fontFamily
                    : _kFontFamilies.first,
                isDense: true,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: _fontPreviewStyle(clip.fontFamily),
                items: _kFontFamilies
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f,
                            style: _fontPreviewStyle(f),
                            overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateFontFamily(clip.id, v);
                },
              ),
            ),
          ),
        ),
        // Font size
        _SliderRow(
          label: 'Font Size',
          value: clip.titleFontSize.clamp(8.0, 200.0),
          min: 8,
          max: 200,
          displayText: clip.titleFontSize.toStringAsFixed(0),
          onChangeStart: (_) => _clipAtDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref
                  .read(timelineStateProvider)
                  .updateClip(c.copyWith(titleFontSize: v));
            }
          },
          onChangeEnd: (v) {
            if (_clipAtDragStart != null) {
              controller.updateTitleFontSize(clip.id, v);
              _clipAtDragStart = null;
            }
          },
        ),
        // Alignment
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const SizedBox(
                  width: 80,
                  child: Text('Align', style: AppTypography.labelMedium)),
              _AlignButton(
                icon: Icons.format_align_left,
                isActive: clip.titleAlignment == 'left',
                onTap: () =>
                    controller.updateTitleAlignment(clip.id, 'left'),
              ),
              const SizedBox(width: 4),
              _AlignButton(
                icon: Icons.format_align_center,
                isActive: clip.titleAlignment == 'center',
                onTap: () =>
                    controller.updateTitleAlignment(clip.id, 'center'),
              ),
              const SizedBox(width: 4),
              _AlignButton(
                icon: Icons.format_align_right,
                isActive: clip.titleAlignment == 'right',
                onTap: () =>
                    controller.updateTitleAlignment(clip.id, 'right'),
              ),
            ],
          ),
        ),
        // Text color
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Text Color', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              _ColorSwatchRow(
                selectedColor: clip.titleColorValue,
                colors: _presetColors,
                onSelected: (c) => controller.updateTitleColor(clip.id, c),
              ),
            ],
          ),
        ),
        // Animation type
        _labeledRow(
          'Anim',
          DropdownButtonHideUnderline(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: ColorTokens.backgroundSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ColorTokens.borderSubtle),
              ),
              child: DropdownButton<TextAnimationType>(
                value: clip.textAnimationType,
                isDense: true,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodySmall
                    .copyWith(color: ColorTokens.textPrimary),
                items: TextAnimationType.values
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.displayName,
                            style: AppTypography.bodySmall
                                .copyWith(color: ColorTokens.textPrimary)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateTextAnimation(clip.id, v);
                },
              ),
            ),
          ),
        ),
        // Animation duration (only when an animation is active)
        if (clip.textAnimationType != TextAnimationType.none)
          _SliderRow(
            label: 'Duration',
            value: clip.textAnimationDurationMs.toDouble().clamp(100.0, 5000.0),
            min: 100,
            max: 5000,
            displayText:
                '${(clip.textAnimationDurationMs / 1000.0).toStringAsFixed(1)}s',
            onChangeStart: (_) => _clipAtDragStart = _latestClip(),
            onChanged: (v) {
              final c = _latestClip();
              if (c != null) {
                ref.read(timelineStateProvider).updateClip(
                      c.copyWith(textAnimationDurationMs: v.round()),
                    );
              }
            },
            onChangeEnd: (v) {
              if (_clipAtDragStart != null) {
                controller.updateAnimationDuration(clip.id, v.round());
                _clipAtDragStart = null;
              }
            },
          ),
      ],
    );
  }

  Widget _labeledRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: AppTypography.labelMedium)),
          Expanded(child: child),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      filled: true,
      fillColor: ColorTokens.backgroundSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ColorTokens.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ColorTokens.borderSubtle),
      ),
    );
  }
}

// ── Title Clip Section ────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.clip});

  final ClipModel clip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Title'),
        _TextStyleControls(clip: clip),
      ],
    );
  }
}

// ── Color Card Section ────────────────────────────────────────────────────────

class _ColorCardSection extends ConsumerWidget {
  const _ColorCardSection({required this.clip});

  final ClipModel clip;

  static const _bgColors = [
    0xFF000000, // black
    0xFFFFFFFF, // white
    0xFF1A1A1B, // dark grey
    0xFF505057, // mid grey
    0xFFFF5252, // red
    0xFFFFB340, // orange
    0xFFFFEB3B, // yellow
    0xFF34C47A, // green
    0xFF4D9CFF, // blue
    0xFF9B6DFF, // purple
    0xFFFF6B9D, // pink
    0xFF40D9F3, // cyan
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveClip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == clip.id, orElse: () => null) ??
        clip;

    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Color Card'),
        const Text('Background Color', style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        _ColorSwatchRow(
          selectedColor: liveClip.cardColorValue,
          colors: _bgColors,
          onSelected: (c) => controller.updateCardColor(liveClip.id, c),
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Text Overlay'),
        _TextStyleControls(clip: liveClip),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _AlignButton extends StatelessWidget {
  const _AlignButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.accentPrimary.withValues(alpha: 0.2)
              : ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? ColorTokens.accentPrimary
                : ColorTokens.borderSubtle,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive
              ? ColorTokens.accentPrimary
              : ColorTokens.textSecondary,
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({
    required this.selectedColor,
    required this.colors,
    required this.onSelected,
  });

  final int selectedColor;
  final List<int> colors;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors
          .map(
            (c) => GestureDetector(
              onTap: () => onSelected(c),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == c
                        ? ColorTokens.accentPrimary
                        : ColorTokens.borderStrong,
                    width: selectedColor == c ? 2 : 1,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Image Clip Section ────────────────────────────────────────────────────────

class _ImageClipSection extends StatelessWidget {
  const _ImageClipSection({required this.clip});

  final ClipModel clip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Image'),
        const _SectionHeader(title: 'Text Overlay'),
        _TextStyleControls(clip: clip),
      ],
    );
  }
}

// ── Transition Section ────────────────────────────────────────────────────────

// ── Transform Section ────────────────────────────────────────────────────────

class _TransformSection extends ConsumerStatefulWidget {
  const _TransformSection({required this.clip});

  final ClipModel clip;

  @override
  ConsumerState<_TransformSection> createState() => _TransformSectionState();
}

class _TransformSectionState extends ConsumerState<_TransformSection> {
  ClipModel? _atDragStart;

  ClipModel? _latestClip() {
    try {
      return ref
          .read(timelineStateProvider)
          .clips
          .firstWhere((c) => c.id == widget.clip.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == widget.clip.id, orElse: () => null) ??
        widget.clip;
    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Transform'),
        _SliderRow(
          label: 'Position X',
          value: clip.posX,
          min: -1920,
          max: 1920,
          displayText: clip.posX.toStringAsFixed(0),
          onChangeStart: (_) => _atDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref.read(timelineStateProvider).updateClip(c.copyWith(posX: v));
            }
          },
          onChangeEnd: (v) {
            if (_atDragStart != null) {
              controller.updateClipTransform(clip.id, posX: v);
              _atDragStart = null;
            }
          },
        ),
        _SliderRow(
          label: 'Position Y',
          value: clip.posY,
          min: -1080,
          max: 1080,
          displayText: clip.posY.toStringAsFixed(0),
          onChangeStart: (_) => _atDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref.read(timelineStateProvider).updateClip(c.copyWith(posY: v));
            }
          },
          onChangeEnd: (v) {
            if (_atDragStart != null) {
              controller.updateClipTransform(clip.id, posY: v);
              _atDragStart = null;
            }
          },
        ),
        _SliderRow(
          label: 'Scale X',
          value: clip.scaleX,
          min: AppConstants.minScale,
          max: AppConstants.maxScale,
          displayText: '${(clip.scaleX * 100).toStringAsFixed(0)}%',
          onChangeStart: (_) => _atDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref.read(timelineStateProvider).updateClip(c.copyWith(scaleX: v));
            }
          },
          onChangeEnd: (v) {
            if (_atDragStart != null) {
              controller.updateClipTransform(clip.id, scaleX: v);
              _atDragStart = null;
            }
          },
        ),
        _SliderRow(
          label: 'Scale Y',
          value: clip.scaleY,
          min: AppConstants.minScale,
          max: AppConstants.maxScale,
          displayText: '${(clip.scaleY * 100).toStringAsFixed(0)}%',
          onChangeStart: (_) => _atDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref.read(timelineStateProvider).updateClip(c.copyWith(scaleY: v));
            }
          },
          onChangeEnd: (v) {
            if (_atDragStart != null) {
              controller.updateClipTransform(clip.id, scaleY: v);
              _atDragStart = null;
            }
          },
        ),
        _SliderRow(
          label: 'Rotation',
          value: clip.rotation,
          min: AppConstants.minRotation,
          max: AppConstants.maxRotation,
          displayText: '${clip.rotation.toStringAsFixed(1)}°',
          onChangeStart: (_) => _atDragStart = _latestClip(),
          onChanged: (v) {
            final c = _latestClip();
            if (c != null) {
              ref
                  .read(timelineStateProvider)
                  .updateClip(c.copyWith(rotation: v));
            }
          },
          onChangeEnd: (v) {
            if (_atDragStart != null) {
              controller.updateClipTransform(clip.id, rotation: v);
              _atDragStart = null;
            }
          },
        ),
      ],
    );
  }
}

// ── Crop Section ─────────────────────────────────────────────────────────────

class _CropSection extends ConsumerStatefulWidget {
  const _CropSection({required this.clip});

  final ClipModel clip;

  @override
  ConsumerState<_CropSection> createState() => _CropSectionState();
}

class _CropSectionState extends ConsumerState<_CropSection> {
  ClipModel? _atDragStart;

  ClipModel? _latestClip() {
    try {
      return ref
          .read(timelineStateProvider)
          .clips
          .firstWhere((c) => c.id == widget.clip.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == widget.clip.id, orElse: () => null) ??
        widget.clip;
    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Crop'),
        for (final entry in [
          ('Left', clip.cropLeft, (double v) => controller.updateClipCrop(clip.id, cropLeft: v)),
          ('Right', clip.cropRight, (double v) => controller.updateClipCrop(clip.id, cropRight: v)),
          ('Top', clip.cropTop, (double v) => controller.updateClipCrop(clip.id, cropTop: v)),
          ('Bottom', clip.cropBottom, (double v) => controller.updateClipCrop(clip.id, cropBottom: v)),
        ])
          _SliderRow(
            label: entry.$1,
            value: entry.$2,
            min: 0,
            max: 0.99,
            displayText: '${(entry.$2 * 100).toStringAsFixed(0)}%',
            onChangeStart: (_) => _atDragStart = _latestClip(),
            onChanged: (v) {
              final c = _latestClip();
              if (c != null) {
                final updated = switch (entry.$1) {
                  'Left' => c.copyWith(cropLeft: v),
                  'Right' => c.copyWith(cropRight: v),
                  'Top' => c.copyWith(cropTop: v),
                  'Bottom' => c.copyWith(cropBottom: v),
                  _ => c,
                };
                ref.read(timelineStateProvider).updateClip(updated);
              }
            },
            onChangeEnd: (v) {
              if (_atDragStart != null) {
                entry.$3(v);
                _atDragStart = null;
              }
            },
          ),
      ],
    );
  }
}

// ── Clip Flags Section ───────────────────────────────────────────────────────

class _ClipFlagsSection extends ConsumerWidget {
  const _ClipFlagsSection({required this.clip});

  final ClipModel clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(timelineControllerProvider);
    final liveClip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == clip.id, orElse: () => null) ??
        clip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Clip Controls'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FlagChip(
              label: 'Flip H',
              icon: Icons.flip,
              isActive: liveClip.flipHorizontal,
              onTap: () => controller.toggleFlipHorizontal(clip.id),
            ),
            _FlagChip(
              label: 'Flip V',
              icon: Icons.flip_camera_android,
              isActive: liveClip.flipVertical,
              onTap: () => controller.toggleFlipVertical(clip.id),
            ),
            _FlagChip(
              label: 'Reverse',
              icon: Icons.fast_rewind,
              isActive: liveClip.isReversed,
              onTap: () => controller.toggleReverse(clip.id),
            ),
            _FlagChip(
              label: 'Freeze',
              icon: Icons.ac_unit,
              isActive: liveClip.isFrozen,
              onTap: () => controller.toggleFreezeFrame(clip.id),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.accentPrimary.withValues(alpha: 0.2)
              : ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? ColorTokens.accentPrimary
                : ColorTokens.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
              color: isActive ? ColorTokens.accentPrimary : ColorTokens.textSecondary),
            const SizedBox(width: 4),
            Text(label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? ColorTokens.accentPrimary : ColorTokens.textSecondary,
              )),
          ],
        ),
      ),
    );
  }
}

// ── Subject Isolation Section ────────────────────────────────────────────────

class _SubjectIsolationSection extends ConsumerStatefulWidget {
  const _SubjectIsolationSection({required this.clip});

  final ClipModel clip;

  @override
  ConsumerState<_SubjectIsolationSection> createState() =>
      _SubjectIsolationSectionState();
}

class _SubjectIsolationSectionState
    extends ConsumerState<_SubjectIsolationSection> {
  ClipModel? _atDragStart;

  ClipModel? _latestClip() {
    try {
      return ref
          .read(timelineStateProvider)
          .clips
          .firstWhere((c) => c.id == widget.clip.id);
    } catch (_) {
      return null;
    }
  }

  static const _bgColors = [
    0xFF00FF00,
    0xFF000000,
    0xFFFFFFFF,
    0xFF0A84FF,
    0xFFFF453A,
    0xFFBF5AF2,
    0xFFFF9F0A,
    0xFF30D158,
  ];

  Future<void> _processIsolation(ClipModel clip) async {
    final controller = ref.read(timelineControllerProvider);
    final repo = ref.read(projectRepositoryProvider);
    final segService = ref.read(segmentationServiceProvider);

    final available = await segService.isAvailable();
    if (!available || !mounted) return;

    final asset = await repo.getMediaAsset(clip.mediaId);
    if (asset == null || !mounted) return;

    controller.setIsolationProcessing(clip.id, true);

    final outputDir = asset.filePath.substring(
      0,
      asset.filePath.lastIndexOf('/'),
    );
    final outputPath = '$outputDir/${clip.id}_mask.mp4';

    final Rect? selectionRect = clip.isolationSelectionLeft != null
        ? Rect.fromLTRB(
            clip.isolationSelectionLeft!,
            clip.isolationSelectionTop!,
            clip.isolationSelectionRight!,
            clip.isolationSelectionBottom!,
          )
        : null;

    final maskPath = await segService.generateMaskVideo(
      videoPath: asset.filePath,
      outputPath: outputPath,
      inPoint: clip.mediaInPoint,
      outPoint: clip.mediaOutPoint,
      selectionRect: selectionRect,
    );

    if (!mounted) return;
    await controller.setIsolationMaskPath(clip.id, maskPath);
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref
            .watch(timelineStateProvider)
            .clips
            .cast<ClipModel?>()
            .firstWhere((c) => c?.id == widget.clip.id, orElse: () => null) ??
        widget.clip;
    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(title: 'Subject Isolation'),
            ),
            GestureDetector(
              onTap: () => controller.toggleIsolation(clip.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: clip.isolationEnabled
                      ? ColorTokens.isolationBadge
                      : ColorTokens.backgroundElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: clip.isolationEnabled
                        ? ColorTokens.isolationBadge
                        : ColorTokens.borderStrong,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: clip.isolationEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!clip.isolationEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Remove background from video',
              style: AppTypography.bodySmall.copyWith(
                color: ColorTokens.textSecondary,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 6),
          if (clip.isolationProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorTokens.isolationBadge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing segmentation…',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (clip.isolationMaskPath == null &&
              clip.isolationSelectionLeft == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    size: 14,
                    color: ColorTokens.isolationBadge,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Draw on the preview to select your subject',
                      style: AppTypography.bodySmall.copyWith(
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (clip.isolationMaskPath == null &&
              clip.isolationSelectionLeft != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _processIsolation(clip),
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Generate Mask'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.isolationBadge,
                    side: const BorderSide(color: ColorTokens.isolationBadge),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: ColorTokens.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mask ready',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorTokens.success,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        controller.clearIsolationSelectionRect(clip.id),
                    child: Text(
                      'Redraw',
                      style: AppTypography.labelSmall.copyWith(
                        color: ColorTokens.isolationBadge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Background mode
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('Background', style: AppTypography.labelMedium),
                ),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: ColorTokens.backgroundSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ColorTokens.borderSubtle),
                      ),
                      child: DropdownButton<IsolationMode>(
                        value: clip.isolationMode,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: ColorTokens.backgroundElevated,
                        style: AppTypography.bodySmall
                            .copyWith(color: ColorTokens.textPrimary),
                        items: IsolationMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m.displayName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: ColorTokens.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            controller.updateIsolationMode(clip.id, v);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Edge feather (all modes, when mask exists)
          if (clip.isolationMaskPath != null)
            _SliderRow(
              label: 'Edge',
              value: clip.isolationEdgeFeather,
              min: AppConstants.minIsolationEdgeFeather,
              max: AppConstants.maxIsolationEdgeFeather,
              displayText:
                  clip.isolationEdgeFeather.toStringAsFixed(1),
              onChangeStart: (_) => _atDragStart = _latestClip(),
              onChanged: (v) {
                final c = _latestClip();
                if (c != null) {
                  ref.read(timelineStateProvider).updateClip(
                        c.copyWith(isolationEdgeFeather: v),
                      );
                }
              },
              onChangeEnd: (v) {
                if (_atDragStart != null) {
                  controller.updateIsolationEdgeFeather(clip.id, v);
                  _atDragStart = null;
                }
              },
            ),
          // Blur radius (only in blur mode)
          if (clip.isolationMode == IsolationMode.blur)
            _SliderRow(
              label: 'Blur',
              value: clip.isolationBlurRadius,
              min: AppConstants.minIsolationBlurRadius,
              max: AppConstants.maxIsolationBlurRadius,
              displayText:
                  '${clip.isolationBlurRadius.toStringAsFixed(0)}px',
              onChangeStart: (_) => _atDragStart = _latestClip(),
              onChanged: (v) {
                final c = _latestClip();
                if (c != null) {
                  ref.read(timelineStateProvider).updateClip(
                        c.copyWith(isolationBlurRadius: v),
                      );
                }
              },
              onChangeEnd: (v) {
                if (_atDragStart != null) {
                  controller.updateIsolationBlurRadius(clip.id, v);
                  _atDragStart = null;
                }
              },
            ),
          // Color picker (only in solidColor mode)
          if (clip.isolationMode == IsolationMode.solidColor) ...[
            const SizedBox(height: 4),
            const Text('Background Color', style: AppTypography.labelMedium),
            const SizedBox(height: 6),
            _ColorSwatchRow(
              selectedColor: clip.isolationColorValue,
              colors: _bgColors,
              onSelected: (c) =>
                  controller.updateIsolationColor(clip.id, c),
            ),
          ],
        ],
      ],
    );
  }
}

// ── Transition Section ────────────────────────────────────────────────────────

class _TransitionSection extends ConsumerStatefulWidget {
  const _TransitionSection({required this.clip});

  final ClipModel clip;

  @override
  ConsumerState<_TransitionSection> createState() => _TransitionSectionState();
}

class _TransitionSectionState extends ConsumerState<_TransitionSection> {
  double? _dragStartDurationSecs;

  ClipModel get _clip {
    final clips = ref.read(timelineStateProvider).clips;
    try {
      return clips.firstWhere((c) => c.id == widget.clip.id);
    } catch (_) {
      return widget.clip;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref.watch(timelineStateProvider).clips.cast<ClipModel?>()
            .firstWhere(
          (c) => c?.id == widget.clip.id,
          orElse: () => null,
        ) ??
        widget.clip;

    final controller = ref.read(timelineControllerProvider);
    final currentType =
        clip.transitionOutId != null
            ? TransitionType.fromId(clip.transitionOutId!)
            : null;
    final durationSecs =
        clip.transitionOutDuration.inMilliseconds / 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Transition Out')),
            PopupMenuButton<TransitionType?>(
              icon: const Icon(
                Icons.add,
                size: 16,
                color: ColorTokens.accentPrimary,
              ),
              tooltip: 'Set Transition',
              padding: EdgeInsets.zero,
              itemBuilder: (_) => [
                const PopupMenuItem<TransitionType?>(
                  value: null,
                  child: Text('None', style: AppTypography.bodySmall),
                ),
                ...TransitionType.values.map(
                  (t) => PopupMenuItem(
                    value: t,
                    child: Text(t.displayName, style: AppTypography.bodySmall),
                  ),
                ),
              ],
              onSelected: (type) {
                if (type == null) {
                  controller.clearTransition(clip.id);
                } else {
                  final dur = currentType == null
                      ? Duration(
                          milliseconds: (AppConstants.defaultTransitionDuration *
                                  1000)
                              .round(),
                        )
                      : clip.transitionOutDuration;
                  controller.setTransition(clip.id, type, dur);
                }
              },
            ),
          ],
        ),
        if (currentType == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No transition',
              style: AppTypography.bodySmall.copyWith(
                color: ColorTokens.textSecondary,
              ),
            ),
          )
        else ...[
          _PropertyRow(label: 'Type', value: currentType.displayName),
          _SliderRow(
            label: 'Duration',
            value: durationSecs.clamp(
              AppConstants.minTransitionDuration,
              AppConstants.maxTransitionDuration,
            ),
            min: AppConstants.minTransitionDuration,
            max: AppConstants.maxTransitionDuration,
            displayText: '${durationSecs.toStringAsFixed(2)}s',
            onChangeStart: (_) {
              _dragStartDurationSecs = durationSecs;
            },
            onChanged: (v) {
              // Live preview: update state without history
              final c = _clip;
              ref.read(timelineStateProvider).updateClip(
                    c.copyWith(
                      transitionOutDuration: Duration(
                        milliseconds: (v * 1000).round(),
                      ),
                    ),
                  );
            },
            onChangeEnd: (v) {
              if (_dragStartDurationSecs != null) {
                controller.setTransition(
                  clip.id,
                  currentType,
                  Duration(milliseconds: (v * 1000).round()),
                );
                _dragStartDurationSecs = null;
              }
            },
          ),
        ],
      ],
    );
  }
}

// ── Subject Tracking Section ────────────────────────────────────────────────

class _TrackerSection extends ConsumerWidget {
  const _TrackerSection({required this.clip});

  final ClipModel clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);
    final sessions = timelineState.trackerSessionsForClip(clip.id);
    final activeSessionId = timelineState.activeTrackerSessionId;
    final controller = ref.read(timelineControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Subject Tracking')),
            Tooltip(
              message: 'Activate tracker tool to drop pins',
              child: GestureDetector(
                onTap: () {
                  ref.read(timelineToolProvider.notifier).state =
                      TimelineTool.tracker;
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ColorTokens.backgroundSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ColorTokens.borderDefault),
                  ),
                  child: const Icon(
                    Icons.pin_drop_outlined,
                    size: 14,
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Use the Track Point tool (T) to drop a pin on the preview.',
              style: TextStyle(
                color: ColorTokens.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        for (final session in sessions)
          _TrackerSessionTile(
            session: session,
            isActive: session.id == activeSessionId,
            onTap: () {
              timelineState.setActiveTrackerSession(session.id);
            },
            onDelete: () {
              controller.removeTrackerSession(session.id);
            },
            onApplyStabilize: session.status == TrackerStatus.completed
                ? () => controller.applyTrackingToTransform(
                      session.id,
                      stabilize: true,
                    )
                : null,
            onApplyFollow: session.status == TrackerStatus.completed
                ? () => controller.applyTrackingToTransform(
                      session.id,
                      stabilize: false,
                    )
                : null,
          ),
      ],
    );
  }
}

class _TrackerSessionTile extends StatelessWidget {
  const _TrackerSessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    this.onApplyStabilize,
    this.onApplyFollow,
  });

  final TrackerSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onApplyStabilize;
  final VoidCallback? onApplyFollow;

  @override
  Widget build(BuildContext context) {
    final color = Color(session.colorHex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.08)
              : ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : ColorTokens.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.name,
                    style: TextStyle(
                      color: isActive
                          ? ColorTokens.textPrimary
                          : ColorTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _StatusBadge(status: session.status),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
            if (session.status == TrackerStatus.completed) ...[
              const SizedBox(height: 6),
              Text(
                '${session.points.length} points tracked',
                style: const TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _SmallActionBtn(
                    label: 'Stabilize',
                    icon: Icons.center_focus_strong,
                    onTap: onApplyStabilize,
                  ),
                  const SizedBox(width: 6),
                  _SmallActionBtn(
                    label: 'Follow',
                    icon: Icons.control_camera,
                    onTap: onApplyFollow,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TrackerStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      TrackerStatus.idle => ('Idle', ColorTokens.textDisabled),
      TrackerStatus.tracking => ('Tracking...', ColorTokens.accentPrimary),
      TrackerStatus.completed => ('Done', ColorTokens.success),
      TrackerStatus.failed => ('Failed', ColorTokens.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SmallActionBtn extends StatelessWidget {
  const _SmallActionBtn({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ColorTokens.backgroundSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ColorTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: ColorTokens.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: ColorTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
