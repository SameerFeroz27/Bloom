import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// Rounded tinted square behind an icon — the CSS `.icon-tile`.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 42,
    this.radius = 14,
    this.iconSize = 22,
  });

  final BloomIcon icon;
  final HabitTone tone;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.bg(brightness),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon.data, size: iconSize, color: tone.fg(brightness)),
    );
  }
}

/// The icon tile that stands for a habit.
class HabitIconView extends StatelessWidget {
  const HabitIconView({super.key, required this.habit, this.size = 22});

  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) =>
      IconTile(icon: habit.icon, tone: habit.tone, iconSize: size);
}

/// Small uppercase label with a leading dot — the CSS `.eyebrow`.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: BloomText.body(9.5, FontWeight.w700, letterSpacing: 1.5, color: tint),
          ),
        ),
      ],
    );
  }
}

/// The white rounded panel used for every section — the CSS `.card`.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: dark ? null : extras.shadow1,
      ),
      child: child,
    );
  }
}

/// Category badge — the CSS `.cat`.
class CategoryChip extends StatelessWidget {
  const CategoryChip(this.category, {super.key});

  final TaskCategory category;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: category.bg(brightness),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.label,
        style: BloomText.body(9, FontWeight.w700, letterSpacing: 0.6, color: category.fg(brightness)),
      ),
    );
  }
}

/// Pill-style filter control — the CSS `.segmented`.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final (key, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(key),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: key == value ? scheme.surfaceContainer : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: key == value ? extras.shadow1 : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (key == value) ...[
                        Icon(Icons.check, size: 15, color: scheme.primary),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: BloomText.body(
                          11.5,
                          FontWeight.w600,
                          color: key == value ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty placeholder — the CSS `.empty-state`.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final BloomIcon icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon.data, size: 30, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(title, style: BloomText.display(15, FontWeight.w700)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: BloomText.body(12, FontWeight.w400, height: 1.6, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Material 3 switch from the profile sheet — the CSS `.switch`.
class BloomSwitch extends StatelessWidget {
  const BloomSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: value,
      label: 'Dark theme',
      container: true,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 54,
          height: 32,
          decoration: BoxDecoration(
            color: value ? scheme.primary : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value ? scheme.primary : scheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: value ? 22 : 16,
                height: value ? 22 : 16,
                decoration: BoxDecoration(
                  color: value ? scheme.onPrimary : scheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flame plus the current streak count — the CSS `.streak-badge`.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? const Color(0xFFE5B375) : const Color(0xFFB07A3C);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(BloomIcon.fire.data, size: 14, color: tint),
        const SizedBox(width: 3),
        Text('${streakOf(habit)}', style: BloomText.body(12, FontWeight.w700, color: tint)),
      ],
    );
  }
}

/// Full-width primary action — the CSS `.filled-btn`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final BloomIcon? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);
    final leading = icon;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: extras.shadow1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Icon(leading.data, size: 18, color: scheme.onPrimary),
                const SizedBox(width: 8),
              ],
              Flexible(
                // Shrinks the label instead of clipping it when the button has
                // to share a row with other controls.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: BloomText.body(
                      13.5,
                      FontWeight.w700,
                      letterSpacing: 0.1,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed call-to-action row — the CSS `.banner`.
class BannerCta extends StatelessWidget {
  const BannerCta({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.trailing = BloomIcon.plus,
  });

  final BloomIcon icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final BloomIcon trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DashedBorder(
      color: scheme.outline,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon.data, size: 22, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BloomText.body(13, FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: BloomText.body(11, FontWeight.w400, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(trailing.data, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title + supporting line, with an optional trailing action — the CSS `.card-head`.
class CardHead extends StatelessWidget {
  const CardHead({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final action = trailing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BloomText.display(16, FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: BloomText.body(11.5, FontWeight.w400, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Inline text action — the CSS `.text-btn`.
class TextBtn extends StatelessWidget {
  const TextBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = BloomIcon.chevron,
    this.danger = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final BloomIcon? icon;
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = danger ? scheme.error : scheme.primary;
    final iconData = icon;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconData != null) ...[
          Icon(iconData.data, size: 15, color: tint),
          const SizedBox(width: 6),
        ],
        Text(label, style: BloomText.body(11.5, FontWeight.w700, color: tint)),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: content,
      ),
    );
  }
}

/// Screen title block — the CSS `.page-head`.
class PageHead extends StatelessWidget {
  const PageHead({super.key, required this.eyebrow, required this.title, required this.subtitle});

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 8),
          Text(title, style: BloomText.display(27, FontWeight.w800, letterSpacing: -0.9, height: 1.25)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: BloomText.body(12.5, FontWeight.w400, height: 1.6, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Dashed outline used by the call-to-action banners.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 20,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRectPainter(color: color, radius: radius, strokeWidth: strokeWidth),
    child: child,
  );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius, required this.strokeWidth});

  static const double _dash = 6;
  static const double _gap = 5;

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

void showBloomSnackBar(BuildContext context, String message) {
  showBloomSnackBarOn(ScaffoldMessenger.of(context), message);
}

/// Shows a snackbar on a messenger captured before the screen that triggered
/// it was popped. This keeps feedback working after a sheet closes.
void showBloomSnackBarOn(ScaffoldMessengerState messenger, String message) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    ),
  );
}

void showUndoSnackBar(BuildContext context, String message, VoidCallback onUndo) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      action: SnackBarAction(label: 'UNDO', onPressed: onUndo),
    ),
  );
}

/// Small low-emphasis icon button — the CSS `.icon-btn.ghost`.
class GhostIconButton extends StatelessWidget {
  const GhostIconButton({super.key, required this.icon, required this.onTap, this.tooltip});

  final BloomIcon icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon.data, size: 17, color: scheme.outline),
      ),
    );
    final message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}
