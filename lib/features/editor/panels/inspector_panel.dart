import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_registry.dart';
import 'package:fluxedit/core/effects/effect_type.dart';
import 'package:fluxedit/core/keyframes/animated_property.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/transitions/transition_type.dart';

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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          bottom: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text('Inspector', style: AppTypography.labelLarge),
      ),
    );
  }
}

class _NoSelectionPlaceholder extends StatelessWidget {
  const _NoSelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a clip to inspect',
        style: AppTypography.bodySmall,
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
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
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              activeColor: ColorTokens.accentPrimary,
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
      itemBuilder: (_) => EffectType.values
          .where((t) => t != EffectType.lut)
          .map(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: effect.isEnabled,
              onChanged: (_) => controller.toggleEffect(effect),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(effect.displayName, style: AppTypography.labelMedium),
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 14),
                color: ColorTokens.textSecondary,
                tooltip: 'Remove',
                onPressed: () => controller.removeEffect(effect),
              ),
            ),
          ],
        ),
        if (effect.isEnabled)
          ...ranges.entries.map((entry) {
            final key = entry.key;
            final (min, max) = entry.value;
            final value = (effect.parameters[key] ?? min).clamp(min, max);
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
          }),
        const Divider(height: 8),
      ],
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
