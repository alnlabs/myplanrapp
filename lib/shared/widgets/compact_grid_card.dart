import 'package:flutter/material.dart';

/// Uniform compact tile used in grid view across list screens.
class CompactGridCard extends StatelessWidget {
  const CompactGridCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small circular icon for grid tiles, with optional status dot.
class CompactGridIcon extends StatelessWidget {
  const CompactGridIcon({
    super.key,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.badgeColor,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color? badgeColor;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withOpacity(0.14);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: _radius,
          backgroundColor: bg,
          child: Icon(icon, color: color, size: 16),
        ),
        if (badgeColor != null)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
