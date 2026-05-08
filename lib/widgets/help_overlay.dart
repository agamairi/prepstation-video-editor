import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/help/help_data.dart';

void showHelpDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _HelpDialog(),
  );
}

class _HelpDialog extends StatefulWidget {
  const _HelpDialog();

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  HelpCategory _active = HelpData.categoryOrder.first;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.backgroundPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 560,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildCategoryRow(),
            const Divider(height: 1),
            Expanded(child: _buildEntryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
      child: Row(
        children: [
          const Icon(
            Icons.help_outline,
            size: 18,
            color: ColorTokens.accentPrimary,
          ),
          const SizedBox(width: 8),
          const Text('Help & Keyboard Shortcuts', style: AppTypography.headlineSmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: HelpData.categoryOrder.map((cat) {
          final active = cat == _active;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _active = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? ColorTokens.accentPrimary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? ColorTokens.accentPrimary
                        : ColorTokens.borderSubtle,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  HelpData.categoryLabel(cat),
                  style: AppTypography.labelMedium.copyWith(
                    color: active
                        ? ColorTokens.accentPrimary
                        : ColorTokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntryList() {
    final entries = HelpData.entriesForCategory(_active);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, idx) =>
          const Divider(height: 1, color: ColorTokens.borderSubtle),
      itemBuilder: (_, i) => _HelpEntryTile(entry: entries[i]),
    );
  }
}

class _HelpEntryTile extends StatelessWidget {
  const _HelpEntryTile({required this.entry});

  final HelpEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: entry.icon != null
                ? Text(
                    entry.icon!,
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: AppTypography.bodySmall
                      .copyWith(color: ColorTokens.textSecondary),
                ),
              ],
            ),
          ),
          if (entry.shortcut != null) ...[
            const SizedBox(width: 12),
            _ShortcutBadge(shortcut: entry.shortcut!),
          ],
        ],
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  const _ShortcutBadge({required this.shortcut});

  final String shortcut;

  @override
  Widget build(BuildContext context) {
    final parts = shortcut.split('+');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '+',
                style: AppTypography.labelSmall
                    .copyWith(color: ColorTokens.textSecondary),
              ),
            ),
          _KeyCap(label: parts[i]),
        ],
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ColorTokens.borderStrong),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: ColorTokens.textPrimary,
          fontFeatures: const [],
        ),
      ),
    );
  }
}
