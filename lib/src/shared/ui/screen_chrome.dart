import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WarmGradientBackground extends StatelessWidget {
  const WarmGradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFBF3E8),
            Color(0xFFF7ECDB),
            Color(0xFFFCF7EF),
          ],
        ),
      ),
      child: child,
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    required this.fallbackLocation,
    super.key,
  });

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(fallbackLocation);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }
}

class MainSliverAppBar extends StatelessWidget {
  const MainSliverAppBar({
    required this.title,
    this.backLocation,
    super.key,
  });

  final String title;
  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            children: [
              if (backLocation != null) ...[
                AppBackButton(fallbackLocation: backLocation!),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF172033),
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
