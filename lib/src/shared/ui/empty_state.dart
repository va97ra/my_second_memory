import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97757).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFD97757).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(icon, color: const Color(0xFFD97757), size: 24),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFC2BFB6),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
