import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A small rounded label — a trade, a city, a category, a status.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.icon,
    this.background,
    this.foreground,
    this.dense = false,
  });

  const Pill.accent(this.label, {super.key, this.icon, this.dense = false})
      : background = const Color(0x14E63946),
        foreground = AppColors.accent;

  const Pill.success(this.label, {super.key, this.icon, this.dense = false})
      : background = const Color(0x141B7350),
        foreground = AppColors.success;

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: background ?? const Color(0x14283A8E),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          // Flexible, because a pill is often placed in a constrained row —
          // two of them side by side on a card. Without it a long city name
          // overflows the pill rather than trimming inside it.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.metaStrong.copyWith(color: fg, fontSize: dense ? 11 : 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontally scrolling row of filter chips.
///
/// [selected] being null is "All" — the row always leads with that, because a
/// filtered directory with no way back to the whole of it is a trap.
class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// value → label.
  final List<({String value, String label})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = index == 0 ? null : options[index - 1].value;
          final label = index == 0 ? allLabel : options[index - 1].label;
          final isSelected = selected == value;

          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onSelected(value),
              labelStyle: AppText.button.copyWith(
                fontSize: 13,
                color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        },
      ),
    );
  }
}
