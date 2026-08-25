import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'opaque_snapshot.dart';
import 'page_turn_coordinator.dart';
import 'paper_texture_cache.dart';
import 'page_turn_painter.dart';

enum PageTurnDirection { forward, backward }

/// Captures a complete, opaque page and animates it as a sheet bound at the
/// left edge. The child remains live underneath the frozen sheet.
class PageTurnFrame extends StatefulWidget {
  const PageTurnFrame({
    required this.child,
    this.provideNavigation = false,
    this.coordinator,
    super.key,
  });

  final Widget child;
  final bool provideNavigation;
  final PageTurnCoordinator? coordinator;

  @override
  State<PageTurnFrame> createState() => PageTurnFrameState();
}

class PageTurnFrameState extends State<PageTurnFrame>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 520);

  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;

  ui.Image? _sourceSnapshot;
  ui.Image? _targetSnapshot;
  final PaperTextureCache _paperTexture = PaperTextureCache();
  PageTurnDirection _direction = PageTurnDirection.forward;
  PagePaperStyle? _paperStyle;
  bool _isTurning = false;
  bool _preparingBackward = false;
  PageTurnCoordinator? _activeCoordinator;

  bool get isTurning => _isTurning;

  @visibleForTesting
  bool get debugUsesRuledBackside => _paperStyle?.backLineColor != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final asset = PagePaperStyle.of(context).textureAsset;
    if (!_paperTexture.changeAsset(asset)) return;
    if (asset != null) unawaited(_paperTexture.load(context, asset));
  }

  @override
  void dispose() {
    _releaseCoordinator();
    _controller.dispose();
    _sourceSnapshot?.dispose();
    _targetSnapshot?.dispose();
    _paperTexture.dispose();
    super.dispose();
  }

  /// Runs [switchContent] after the current page is safely frozen above it.
  /// Returns false when another turn is already in progress.
  Future<bool> beginTurn({
    required PageTurnDirection direction,
    required VoidCallback switchContent,
  }) async {
    if (_isTurning) return false;
    final coordinator =
        widget.coordinator ?? PageTurnCoordinatorScope.maybeOf(context);
    if (coordinator != null && !coordinator.tryAcquire(this)) return false;
    _activeCoordinator = coordinator;
    _isTurning = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      switchContent();
      _isTurning = false;
      _releaseCoordinator();
      return true;
    }

    final source = await _capturePage();
    if (!mounted) {
      source?.dispose();
      _isTurning = false;
      _releaseCoordinator();
      return false;
    }
    if (source == null) {
      _isTurning = false;
      switchContent();
      _releaseCoordinator();
      return true;
    }

    final paperStyle = PagePaperStyle.of(context);
    unawaited(_paperTexture.load(context, paperStyle.textureAsset));
    _disposeTurnSnapshots();
    setState(() {
      _sourceSnapshot = source;
      _direction = direction;
      _paperStyle = paperStyle;
      _preparingBackward = direction == PageTurnDirection.backward;
    });

    // Freeze the source above the live child before changing navigation.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _releaseCoordinator();
      return false;
    }
    switchContent();

    if (direction == PageTurnDirection.backward) {
      // The previous route is now live below the frozen source. Capture it so
      // that the returning leaf can unfold over the still-visible source.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        _releaseCoordinator();
        return false;
      }
      final target = await _capturePage();
      if (!mounted) {
        target?.dispose();
        _releaseCoordinator();
        return false;
      }
      if (target == null) {
        _finishTurn();
        return true;
      }
      setState(() {
        _targetSnapshot = target;
        _preparingBackward = false;
      });
    }

    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      _releaseCoordinator();
      return false;
    }
    if (!mounted) {
      _releaseCoordinator();
      return false;
    }
    _finishTurn();
    return true;
  }

  Future<ui.Image?> _capturePage() async {
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    if (kDebugMode && renderObject.debugNeedsPaint) return null;
    try {
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
      return await renderObject.toImage(
        pixelRatio: math.min(devicePixelRatio, 2.0),
      );
    } catch (_) {
      return null;
    }
  }

  void _finishTurn() {
    if (!mounted) {
      _releaseCoordinator();
      return;
    }
    _controller.value = 0;
    _disposeTurnSnapshots();
    setState(() {
      _paperStyle = null;
      _preparingBackward = false;
      _isTurning = false;
    });
    _releaseCoordinator();
  }

  void _releaseCoordinator() {
    _activeCoordinator?.release(this);
    _activeCoordinator = null;
  }

  void _disposeTurnSnapshots() {
    _sourceSnapshot?.dispose();
    _targetSnapshot?.dispose();
    _sourceSnapshot = null;
    _targetSnapshot = null;
  }

  @override
  Widget build(BuildContext context) {
    Widget livePage = RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );
    if (widget.provideNavigation) {
      livePage = PageTurnNavigationScope(
        frameState: this,
        child: livePage,
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        livePage,
        if (_sourceSnapshot != null)
          Positioned.fill(
            child: RepaintBoundary(
              key: const ValueKey('app_page_turn_composited_layer'),
              child: IgnorePointer(
                child: _buildOverlay(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    final source = _sourceSnapshot!;
    final style = _paperStyle!;

    if (_direction == PageTurnDirection.backward) {
      final target = _targetSnapshot;
      return Stack(
        fit: StackFit.expand,
        children: [
          OpaqueSnapshot(image: source, fallback: style.frontFallback),
          if (!_preparingBackward && target != null)
            CustomPaint(
              key: const ValueKey('app_page_turn_overlay'),
              painter: PageTurnPainter(
                image: target,
                paperTexture: _paperTexture.image,
                animation: _controller,
                reverseProgress: true,
                paperStyle: style,
              ),
            ),
        ],
      );
    }

    return CustomPaint(
      key: const ValueKey('app_page_turn_overlay'),
      painter: PageTurnPainter(
        image: source,
        paperTexture: _paperTexture.image,
        animation: _controller,
        paperStyle: style,
      ),
    );
  }
}

/// Доступ к рамке перелистывания для тех, кто под ней.
class PageTurnNavigationScope extends InheritedWidget {
  const PageTurnNavigationScope({
    required this.frameState,
    required super.child,
    super.key,
  });

  final PageTurnFrameState frameState;

  static PageTurnFrameState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageTurnNavigationScope>()
        ?.frameState;
  }

  @override
  bool updateShouldNotify(PageTurnNavigationScope oldWidget) =>
      oldWidget.frameState != frameState;
}
