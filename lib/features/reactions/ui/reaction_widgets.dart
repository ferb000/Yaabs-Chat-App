import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/reaction_models.dart';

Future<String?> showReactionPicker(
  BuildContext context, {
  String? selectedReaction,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.soft,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: reactionOptions.map((option) {
            final selected = selectedReaction == option.key;
            return Tooltip(
              message: option.label,
              child: InkWell(
                onTap: () => Navigator.pop(context, option.key),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.outgoing : AppColors.chip,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    option.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

class ReactionStrip extends StatelessWidget {
  const ReactionStrip({
    super.key,
    required this.summary,
    this.myReaction,
    this.compact = false,
  });

  final ReactionSummary summary;
  final String? myReaction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (summary.total == 0) return const SizedBox.shrink();

    final visibleCounts = summary.counts.take(compact ? 3 : 6).toList();
    final names = summary.preview.map((item) => item.name).take(2).join(', ');

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4 : 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...visibleCounts.map((item) {
            final option = reactionOptionFor(item.reaction);
            final active = myReaction == item.reaction;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 10,
                vertical: compact ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.outgoing : AppColors.chip,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                '${option.emoji} ${item.count}',
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            );
          }),
          if (!compact && names.isNotEmpty)
            Text(
              names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class ReactionActionButton extends StatelessWidget {
  const ReactionActionButton({
    super.key,
    required this.myReaction,
    required this.onTap,
  });

  final String? myReaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final option = myReaction == null ? null : reactionOptionFor(myReaction);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: option == null ? AppColors.chip : AppColors.outgoing,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: option == null ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option?.emoji ?? '＋',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Text(
              option?.label ?? 'React',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
