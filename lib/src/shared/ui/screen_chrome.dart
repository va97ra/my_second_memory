import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaperTextureBackground extends StatefulWidget {
  const PaperTextureBackground({required this.child, super.key});

  final Widget child;

  @override
  State<PaperTextureBackground> createState() => _PaperTextureBackgroundState();
}

class _PaperTextureBackgroundState extends State<PaperTextureBackground> {
  static const _texturePath = 'assets/images/paper_texture.jpg';
  static const _texture = AssetImage(_texturePath);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_texture, context);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8DCCB),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.topLeft,
        children: [
          const Opacity(
            opacity: 0.9,
            child: Image(
              image: _texture,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
          const ColoredBox(color: Color(0x0FFFF7EA)),
          widget.child,
        ],
      ),
    );
  }
}

class WarmGradientBackground extends StatelessWidget {
  const WarmGradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x16A66F3F),
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
      child: MainPageHeader(title: title, backLocation: backLocation),
    );
  }
}

class MainPageHeader extends StatelessWidget {
  const MainPageHeader({
    required this.title,
    this.backLocation,
    super.key,
  });

  final String title;
  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Row(
          children: [
            if (backLocation != null) ...[
              AppBackButton(fallbackLocation: backLocation!),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF172033),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
