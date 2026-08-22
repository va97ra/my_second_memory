import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_surface_palette.dart';
import '../../core/theme/app_surface_textures.dart';
import '../../core/theme/notebook/notebook_assets.dart';
import '../../core/theme/notebook/notebook_background.dart';
import '../../core/theme/notebook/notebook_visuals.dart';

enum PageTurnDirection { forward, backward }

class PageTurnCoordinator extends ChangeNotifier {
  Object? _owner;

  bool get isBusy => _owner != null;

  bool tryAcquire(Object owner) {
    if (_owner != null) return false;
    _owner = owner;
    notifyListeners();
    return true;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    notifyListeners();
  }
}

class PageTurnCoordinatorScope extends InheritedNotifier<PageTurnCoordinator> {
  const PageTurnCoordinatorScope({
    required PageTurnCoordinator coordinator,
    required super.child,
    super.key,
  }) : super(notifier: coordinator);

  static PageTurnCoordinator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageTurnCoordinatorScope>()
        ?.notifier;
  }
}

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
  ui.Image? _paperTexture;
  Future<ui.Image?>? _paperTextureLoad;
  String? _paperTextureAsset;
  PageTurnDirection _direction = PageTurnDirection.forward;
  _PagePaperStyle? _paperStyle;
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
    final asset = _PagePaperStyle.of(context).textureAsset;
    if (asset == _paperTextureAsset) return;
    _paperTexture?.dispose();
    _paperTexture = null;
    _paperTextureLoad = null;
    _paperTextureAsset = asset;
    if (asset != null) unawaited(_loadPaperTexture(asset));
  }

  @override
  void dispose() {
    _releaseCoordinator();
    _controller.dispose();
    _sourceSnapshot?.dispose();
    _targetSnapshot?.dispose();
    _paperTexture?.dispose();
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

    final paperStyle = _PagePaperStyle.of(context);
    unawaited(_loadPaperTexture(paperStyle.textureAsset));
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

  Future<ui.Image?> _loadPaperTexture(String? asset) {
    if (asset == null) return SynchronousFuture(null);
    if (_paperTexture != null && _paperTextureAsset == asset) {
      return SynchronousFuture(_paperTexture);
    }
    if (_paperTextureLoad != null && _paperTextureAsset == asset) {
      return _paperTextureLoad!;
    }

    _paperTextureAsset = asset;
    final completer = Completer<ui.Image?>();
    final stream = AssetImage(asset).resolve(
      createLocalImageConfiguration(context),
    );
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final image = info.image.clone();
        if (!mounted || _paperTextureAsset != asset) {
          image.dispose();
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        _paperTexture?.dispose();
        _paperTexture = image;
        if (!completer.isCompleted) completer.complete(image);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    _paperTextureLoad = completer.future.whenComplete(() {
      if (_paperTextureAsset == asset) _paperTextureLoad = null;
    });
    return _paperTextureLoad!;
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
          _OpaqueSnapshot(image: source, fallback: style.frontFallback),
          if (!_preparingBackward && target != null)
            CustomPaint(
              key: const ValueKey('app_page_turn_overlay'),
              painter: _PageTurnPainter(
                image: target,
                paperTexture: _paperTexture,
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
      painter: _PageTurnPainter(
        image: source,
        paperTexture: _paperTexture,
        animation: _controller,
        paperStyle: style,
      ),
    );
  }
}

class _OpaqueSnapshot extends StatelessWidget {
  const _OpaqueSnapshot({required this.image, required this.fallback});

  final ui.Image image;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: fallback,
      child: RawImage(
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

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

class PageTurnBranchNavigationScope extends InheritedWidget {
  const PageTurnBranchNavigationScope({
    required this.onGo,
    required super.child,
    super.key,
  });

  final Future<bool> Function(String location) onGo;

  static PageTurnBranchNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageTurnBranchNavigationScope>();
  }

  @override
  bool updateShouldNotify(PageTurnBranchNavigationScope oldWidget) =>
      oldWidget.onGo != onGo;
}

abstract interface class _PageTurnBackController {
  Future<void> pop<T>(T? result);

  Future<void> prepareForRouteReplacement();

  void restoreBackHandling();
}

class _PageTurnBackMarker extends InheritedWidget {
  const _PageTurnBackMarker({
    required this.controller,
    required super.child,
  });

  final _PageTurnBackController controller;

  static _PageTurnBackController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PageTurnBackMarker>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(_PageTurnBackMarker oldWidget) =>
      oldWidget.controller != controller;
}

/// Makes both the app bar back button and Android's system back command use
/// the same non-interactive returning-page animation.
class PageTurnBackScope extends StatefulWidget {
  const PageTurnBackScope({
    required this.child,
    this.fallbackLocation,
    super.key,
  });

  final Widget child;
  final String? fallbackLocation;

  @override
  State<PageTurnBackScope> createState() => _PageTurnBackScopeState();
}

class _PageTurnBackScopeState extends State<PageTurnBackScope>
    implements _PageTurnBackController {
  bool _allowPop = false;
  bool _handlingPop = false;

  @override
  Future<void> prepareForRouteReplacement() async {
    if (_allowPop || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  void restoreBackHandling() {
    if (!mounted || _handlingPop || !_allowPop) return;
    setState(() => _allowPop = false);
  }

  @override
  Future<void> pop<T>(T? result) async {
    final navigatorCanPop = Navigator.of(context).canPop();
    if (_handlingPop ||
        !mounted ||
        (!navigatorCanPop && widget.fallbackLocation == null)) {
      return;
    }
    _handlingPop = true;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final frame = PageTurnNavigationScope.maybeOf(context);
    if (frame == null) {
      if (navigatorCanPop) {
        context.pop<T>(result);
      } else {
        context.go(widget.fallbackLocation!);
      }
      return;
    }

    final started = await frame.beginTurn(
      direction: PageTurnDirection.backward,
      switchContent: () {
        if (navigatorCanPop) {
          context.pop<T>(result);
        } else {
          context.go(widget.fallbackLocation!);
        }
      },
    );
    if (!started && mounted) {
      setState(() {
        _allowPop = false;
        _handlingPop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();
    final markedChild = _PageTurnBackMarker(
      controller: this,
      child: widget.child,
    );
    if (!navigatorCanPop && widget.fallbackLocation != null) {
      return BackButtonListener(
        onBackButtonPressed: () async {
          await pop<Object?>(null);
          return true;
        },
        child: markedChild,
      );
    }
    return PopScope<Object?>(
      canPop: !navigatorCanPop || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigatorCanPop) unawaited(pop(result));
      },
      child: markedChild,
    );
  }
}

extension PageTurnNavigationBuildContext on BuildContext {
  Future<void> pageTurnGo(
    String location, {
    Object? extra,
    PageTurnDirection direction = PageTurnDirection.forward,
  }) async {
    final branchScope = PageTurnBranchNavigationScope.maybeOf(this);
    if (extra == null && branchScope != null) {
      final handled = await branchScope.onGo(location);
      if (handled) return;
    }

    final backController = _PageTurnBackMarker.maybeOf(this);
    await backController?.prepareForRouteReplacement();
    if (!mounted) return;

    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) {
      go(location, extra: extra);
      return;
    }
    final started = await frame.beginTurn(
      direction: direction,
      switchContent: () => go(location, extra: extra),
    );
    if (!started) backController?.restoreBackHandling();
  }

  Future<T?> pageTurnPush<T extends Object?>(
    String location, {
    Object? extra,
  }) async {
    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) return push<T>(location, extra: extra);

    late Future<T?> result;
    final started = await frame.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () {
        result = push<T>(location, extra: extra);
      },
    );
    if (!started) return null;
    return result;
  }

  Future<void> pageTurnPop<T extends Object?>([T? result]) async {
    final backController = _PageTurnBackMarker.maybeOf(this);
    if (backController != null) {
      await backController.pop(result);
      return;
    }

    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) {
      pop<T>(result);
      return;
    }
    await frame.beginTurn(
      direction: PageTurnDirection.backward,
      switchContent: () => pop<T>(result),
    );
  }
}

@immutable
class _PagePaperStyle {
  const _PagePaperStyle({
    required this.paperColor,
    required this.frontFallback,
    required this.shadowColor,
    required this.textureAsset,
    required this.textureOpacity,
    required this.backLineColor,
  });

  final Color paperColor;
  final Color frontFallback;
  final Color shadowColor;
  final String? textureAsset;
  final double textureOpacity;
  final Color? backLineColor;

  factory _PagePaperStyle.of(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    return _PagePaperStyle(
      paperColor: notebook?.paper ?? palette.panelSurface,
      frontFallback: palette.backgroundStart,
      shadowColor: Colors.black.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.52 : 0.36,
      ),
      textureAsset:
          notebook != null ? NotebookAssets.paper : textures?.surfaceAsset,
      textureOpacity: notebook != null ? 0.62 : textures?.surfaceOpacity ?? 0,
      backLineColor: notebook?.line,
    );
  }
}

@visibleForTesting
class PageTurnGeometry {
  const PageTurnGeometry({required this.width, required this.progress});

  final double width;
  final double progress;

  double get normalizedProgress => progress.clamp(0.0, 1.0);

  double get motionEnvelope => math.sin(math.pi * normalizedProgress);

  double get radius => radiusAt(0.5);

  double radiusAt(double verticalT) {
    final t = verticalT.clamp(0.0, 1.0);
    final breathingRadius = width * (0.065 + 0.055 * motionEnvelope);
    final verticalVariation =
        1 + 0.07 * math.sin(math.pi * 2 * t) * motionEnvelope;
    return breathingRadius.clamp(22.0, 60.0) * verticalVariation;
  }

  double get foldX => foldXAt(0.5);

  double foldXAt(double verticalT) {
    final t = verticalT.clamp(0.0, 1.0);
    final localRadius = radiusAt(t);
    final baseFold = ui.lerpDouble(
      width,
      -math.pi * localRadius,
      normalizedProgress,
    )!;
    final foldAmplitude = (width * 0.038).clamp(8.0, 20.0) * motionEnvelope;
    final foldWave =
        0.72 * math.sin(math.pi * (t - 0.5)) + 0.28 * math.sin(math.pi * 2 * t);
    return baseFold + foldAmplitude * foldWave;
  }

  PageTurnGeometryPoint project(
    double materialX, {
    double verticalT = 0.5,
  }) {
    final localRadius = radiusAt(verticalT);
    final localFoldX = foldXAt(verticalT);
    final distance = materialX - localFoldX;
    if (distance <= 0) {
      return PageTurnGeometryPoint(x: materialX, depth: 0, angle: 0);
    }

    final curlLength = math.pi * localRadius;
    if (distance < curlLength) {
      final angle = distance / localRadius;
      return PageTurnGeometryPoint(
        x: localFoldX + localRadius * math.sin(angle),
        depth: localRadius * (1 - math.cos(angle)),
        angle: angle,
      );
    }

    return PageTurnGeometryPoint(
      x: localFoldX - (distance - curlLength),
      depth: localRadius * 2,
      angle: math.pi,
    );
  }
}

@visibleForTesting
class PageTurnGeometryPoint {
  const PageTurnGeometryPoint({
    required this.x,
    required this.depth,
    required this.angle,
  });

  final double x;
  final double depth;
  final double angle;
}

class _PageTurnPainter extends CustomPainter {
  _PageTurnPainter({
    required this.image,
    required this.paperTexture,
    required this.animation,
    this.reverseProgress = false,
    required _PagePaperStyle paperStyle,
  })  : _paperColor = paperStyle.paperColor,
        _frontFallback = paperStyle.frontFallback,
        _shadowColor = paperStyle.shadowColor,
        _textureOpacity = paperStyle.textureOpacity,
        _backLineColor = paperStyle.backLineColor,
        super(repaint: animation) {
    _snapshotPaint.filterQuality = FilterQuality.medium;
    _frontTexturePaint
      ..shader = _imageShader(image)
      ..filterQuality = FilterQuality.medium;
    final backTexture = paperTexture;
    if (backTexture != null) {
      _backTexturePaint
        ..shader = _imageShader(backTexture)
        ..filterQuality = FilterQuality.medium;
    }
  }

  final ui.Image image;
  final ui.Image? paperTexture;
  final Animation<double> animation;
  final bool reverseProgress;
  final Color _paperColor;
  final Color _frontFallback;
  final Color _shadowColor;
  final double _textureOpacity;
  final Color? _backLineColor;

  final Paint _snapshotPaint = Paint();
  final Paint _foldShadowPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _freeEdgeShadowPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _cellPaint = Paint()..isAntiAlias = false;
  final Paint _backLinePaint = Paint()..strokeWidth = 1;
  final Paint _frontTexturePaint = Paint();
  final Paint _backTexturePaint = Paint();
  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
  final Paint _edgeDarkPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _edgeLightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.34)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final Path _foldShadowPath = Path();
  final Path _backLinesPath = Path();
  final Path _highlightPath = Path();
  final Path _edgePathBuffer = Path();
  _PageTurnMesh? _mesh;
  final _PageTurnCellVertices _cellVertices = _PageTurnCellVertices();

  static const double _focalLength = 900;
  static final Float64List _identityMatrix = Float64List.fromList(const [
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  static ui.ImageShader _imageShader(ui.Image image) {
    return ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      _identityMatrix,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final easedProgress = Curves.easeInOutCubic.transform(animation.value);
    final normalizedProgress =
        (reverseProgress ? 1 - easedProgress : easedProgress).clamp(0.0, 1.0);
    if (normalizedProgress <= 0.0001) {
      canvas.drawColor(_frontFallback, BlendMode.src);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        _snapshotPaint,
      );
      return;
    }
    if (normalizedProgress >= 0.9999) return;

    final geometry = PageTurnGeometry(
      width: size.width,
      progress: normalizedProgress,
    );
    final columns = (size.width / 8).ceil().clamp(48, 72);
    final rows = (size.height / 240).ceil().clamp(3, 5);
    final mesh = _meshFor(size, columns, rows);
    final projected = mesh.projected;
    for (var column = 0; column <= columns; column++) {
      final materialX = size.width * column / columns;
      for (var row = 0; row <= rows; row++) {
        final verticalT = row / rows;
        final materialY = size.height * verticalT;
        _updateProjectedVertex(
          projected[column][row],
          geometry.project(materialX, verticalT: verticalT),
          materialX,
          materialY,
          size,
        );
      }
    }

    _paintFoldShadow(canvas, size, geometry);
    _paintFreeEdgeShadow(canvas, projected.last, geometry.motionEnvelope);

    final cells = mesh.cells;
    for (final cell in cells) {
      cell.updatePath();
    }
    cells.sort((a, b) => a.averageDepth.compareTo(b.averageDepth));

    _paintOpaqueSilhouette(canvas, cells);
    _paintCells(canvas, size, cells);
    _paintCurlHighlight(canvas, size, geometry);
    _paintFreeEdge(canvas, projected.last);
  }

  _PageTurnMesh _meshFor(Size size, int columns, int rows) {
    final current = _mesh;
    if (current != null && current.matches(size, columns, rows)) return current;
    return _mesh = _PageTurnMesh(size: size, columns: columns, rows: rows);
  }

  void _updateProjectedVertex(
    _ProjectedVertex target,
    PageTurnGeometryPoint point,
    double materialX,
    double materialY,
    Size size,
  ) {
    target.update(
      offset: _projectOffset(point, materialY, size),
      materialX: materialX,
      materialY: materialY,
      depth: point.depth,
      angle: point.angle,
    );
  }

  Offset _projectOffset(
    PageTurnGeometryPoint point,
    double materialY,
    Size size,
  ) {
    final focalLength = math.max(_focalLength, size.longestSide * 1.35);
    final perspective = focalLength / (focalLength - point.depth);
    return Offset(
      point.x * perspective,
      size.height / 2 + (materialY - size.height / 2) * perspective,
    );
  }

  void _paintFoldShadow(Canvas canvas, Size size, PageTurnGeometry geometry) {
    final strength = geometry.motionEnvelope;
    if (strength <= 0.001) return;
    final path = _foldShadowPath..reset();
    for (var sample = 0; sample <= 8; sample++) {
      final verticalT = sample / 8;
      final point = Offset(
        geometry.foldXAt(verticalT) + geometry.radiusAt(verticalT) * 0.18,
        size.height * verticalT,
      );
      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final radius = geometry.radius;
    _foldShadowPaint
      ..color = _shadowColor.withValues(
        alpha: _shadowColor.a * 0.42 * strength,
      )
      ..strokeWidth = (radius * 0.62).clamp(16.0, 38.0)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (radius * 0.32).clamp(6.0, 18.0),
      );
    canvas.drawPath(path, _foldShadowPaint);
  }

  void _paintFreeEdgeShadow(
    Canvas canvas,
    List<_ProjectedVertex> edge,
    double strength,
  ) {
    if (strength <= 0.001) return;
    final path = _updateEdgePath(edge);
    _freeEdgeShadowPaint
      ..color = _shadowColor.withValues(
        alpha: _shadowColor.a * 0.5 * strength,
      )
      ..strokeWidth = 10 + 8 * strength
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 5 * strength);
    canvas.drawPath(path, _freeEdgeShadowPaint);
  }

  void _paintOpaqueSilhouette(
    Canvas canvas,
    List<_ProjectedCell> cells,
  ) {
    _cellPaint.color = _paperColor;
    for (final cell in cells) {
      // Independent paths keep reversed folds opaque without relying on a
      // combined Path's winding rule.
      canvas.drawPath(cell.path, _cellPaint);
    }
  }

  void _paintCells(
    Canvas canvas,
    Size size,
    List<_ProjectedCell> cells,
  ) {
    for (final cell in cells) {
      _paintCell(canvas, size, cell);
    }
  }

  void _paintCell(Canvas canvas, Size size, _ProjectedCell cell) {
    final isBack = cell.averageAngle > math.pi / 2;
    final light = _pageTurnLight(cell.averageAngle, isBack: isBack);
    _cellPaint.color = Color.lerp(
      Colors.black,
      isBack ? _paperColor : _frontFallback,
      light,
    )!;
    canvas.drawPath(cell.path, _cellPaint);

    if (isBack) {
      final texture = paperTexture;
      if (texture != null && _textureOpacity > 0) {
        _drawTexturedCell(
          canvas,
          cell,
          texture,
          size,
          paint: _backTexturePaint,
          opacity: _textureOpacity,
          mirrorX: true,
          isBack: true,
        );
      }
      _paintBackLines(
        canvas,
        cell,
        light,
      );
      return;
    }

    _drawTexturedCell(
      canvas,
      cell,
      image,
      size,
      paint: _frontTexturePaint,
      opacity: 1,
      mirrorX: false,
      isBack: false,
    );
  }

  void _drawTexturedCell(
    Canvas canvas,
    _ProjectedCell cell,
    ui.Image texture,
    Size size, {
    required Paint paint,
    required double opacity,
    required bool mirrorX,
    required bool isBack,
  }) {
    _cellVertices.update(
      cell,
      size: size,
      texture: texture,
      opacity: opacity,
      mirrorX: mirrorX,
      isBack: isBack,
    );
    canvas.drawVertices(
      _cellVertices.toVertices(),
      BlendMode.modulate,
      paint,
    );
  }

  void _paintBackLines(
    Canvas canvas,
    _ProjectedCell cell,
    double light,
  ) {
    final lineColor = _backLineColor;
    if (lineColor == null) return;

    final litColor = Color.lerp(
      Colors.black,
      lineColor.withValues(alpha: 1),
      light,
    )!
        .withValues(alpha: lineColor.a);
    _backLinePaint.color = litColor;

    final topY = cell.topLeft.materialY;
    final bottomY = cell.bottomLeft.materialY;
    var materialY = notebookPageLineTop;
    if (materialY < topY) {
      materialY += ((topY - materialY) / notebookPageLineHeight).ceil() *
          notebookPageLineHeight;
    }
    final lines = _backLinesPath..reset();
    while (materialY <= bottomY + 0.001) {
      final verticalT = (materialY - topY) / (bottomY - topY);
      final left = Offset.lerp(
        cell.topLeft.offset,
        cell.bottomLeft.offset,
        verticalT,
      )!;
      final right = Offset.lerp(
        cell.topRight.offset,
        cell.bottomRight.offset,
        verticalT,
      )!;
      lines.moveTo(left.dx, left.dy);
      lines.lineTo(right.dx, right.dy);
      materialY += notebookPageLineHeight;
    }

    canvas.save();
    canvas.clipPath(cell.path);
    canvas.drawPath(lines, _backLinePaint);
    canvas.restore();
  }

  void _paintCurlHighlight(
    Canvas canvas,
    Size size,
    PageTurnGeometry geometry,
  ) {
    final highlight = _highlightPath..reset();
    var started = false;
    for (var sample = 0; sample <= 12; sample++) {
      final verticalT = sample / 12;
      final radius = geometry.radiusAt(verticalT);
      final materialX = geometry.foldXAt(verticalT) + math.pi * radius / 2;
      if (materialX <= 0 || materialX >= size.width) {
        started = false;
        continue;
      }
      final offset = _projectOffset(
        geometry.project(materialX, verticalT: verticalT),
        size.height * verticalT,
        size,
      );
      if (!started) {
        highlight.moveTo(offset.dx, offset.dy);
        started = true;
      } else {
        highlight.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(highlight, _highlightPaint);
  }

  void _paintFreeEdge(Canvas canvas, List<_ProjectedVertex> edge) {
    final path = _updateEdgePath(edge);
    canvas.drawPath(path, _edgeDarkPaint);
    canvas.drawPath(path, _edgeLightPaint);
  }

  Path _updateEdgePath(List<_ProjectedVertex> edge) {
    final path = _edgePathBuffer..reset();
    for (var index = 0; index < edge.length; index++) {
      final point = edge[index].offset;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(_PageTurnPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.paperTexture != paperTexture ||
        oldDelegate.animation != animation ||
        oldDelegate.reverseProgress != reverseProgress ||
        oldDelegate._paperColor != _paperColor ||
        oldDelegate._frontFallback != _frontFallback ||
        oldDelegate._shadowColor != _shadowColor ||
        oldDelegate._textureOpacity != _textureOpacity ||
        oldDelegate._backLineColor != _backLineColor;
  }
}

class _PageTurnMesh {
  _PageTurnMesh({
    required this.size,
    required this.columns,
    required this.rows,
  }) : projected = List.generate(
          columns + 1,
          (column) => List.generate(
            rows + 1,
            (row) => _ProjectedVertex(
              materialX: size.width * column / columns,
              materialY: size.height * row / rows,
            ),
            growable: false,
          ),
          growable: false,
        ) {
    cells = <_ProjectedCell>[
      for (var column = 0; column < columns; column++)
        for (var row = 0; row < rows; row++)
          _ProjectedCell(
            topLeft: projected[column][row],
            bottomLeft: projected[column][row + 1],
            topRight: projected[column + 1][row],
            bottomRight: projected[column + 1][row + 1],
          ),
    ];
  }

  final Size size;
  final int columns;
  final int rows;
  final List<List<_ProjectedVertex>> projected;
  late final List<_ProjectedCell> cells;

  bool matches(Size otherSize, int otherColumns, int otherRows) {
    return size == otherSize && columns == otherColumns && rows == otherRows;
  }
}

class _ProjectedVertex {
  _ProjectedVertex({
    required this.materialX,
    required this.materialY,
  })  : offset = Offset.zero,
        depth = 0,
        angle = 0;

  Offset offset;
  double materialX;
  double materialY;
  double depth;
  double angle;

  void update({
    required Offset offset,
    required double materialX,
    required double materialY,
    required double depth,
    required double angle,
  }) {
    this.offset = offset;
    this.materialX = materialX;
    this.materialY = materialY;
    this.depth = depth;
    this.angle = angle;
  }
}

class _ProjectedCell {
  _ProjectedCell({
    required this.topLeft,
    required this.bottomLeft,
    required this.topRight,
    required this.bottomRight,
  }) : vertices = [topLeft, bottomLeft, topRight, bottomRight];

  final _ProjectedVertex topLeft;
  final _ProjectedVertex bottomLeft;
  final _ProjectedVertex topRight;
  final _ProjectedVertex bottomRight;
  final List<_ProjectedVertex> vertices;
  final Path path = Path();

  void updatePath() {
    path
      ..reset()
      ..moveTo(topLeft.offset.dx, topLeft.offset.dy)
      ..lineTo(bottomLeft.offset.dx, bottomLeft.offset.dy)
      ..lineTo(bottomRight.offset.dx, bottomRight.offset.dy)
      ..lineTo(topRight.offset.dx, topRight.offset.dy)
      ..close();
  }

  double get averageDepth =>
      (topLeft.depth + bottomLeft.depth + topRight.depth + bottomRight.depth) /
      4;

  double get averageAngle =>
      (topLeft.angle + bottomLeft.angle + topRight.angle + bottomRight.angle) /
      4;
}

class _PageTurnCellVertices {
  final Float32List _positions = Float32List(8);
  final Float32List _textureCoordinates = Float32List(8);
  final Int32List _colors = Int32List(4);
  final Uint16List _indices = Uint16List.fromList(const [0, 1, 2, 1, 3, 2]);

  void update(
    _ProjectedCell cell, {
    required Size size,
    required ui.Image texture,
    required double opacity,
    required bool mirrorX,
    required bool isBack,
  }) {
    for (var index = 0; index < cell.vertices.length; index++) {
      final vertex = cell.vertices[index];
      _positions[index * 2] = vertex.offset.dx;
      _positions[index * 2 + 1] = vertex.offset.dy;
      final horizontalU = vertex.materialX / size.width;
      _textureCoordinates[index * 2] =
          (mirrorX ? 1 - horizontalU : horizontalU) * texture.width;
      _textureCoordinates[index * 2 + 1] =
          vertex.materialY / size.height * texture.height;
      final channel =
          (_pageTurnLight(vertex.angle, isBack: isBack) * 255).round();
      _colors[index] =
          Color.fromRGBO(channel, channel, channel, opacity).toARGB32();
    }
  }

  ui.Vertices toVertices() {
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _textureCoordinates,
      colors: _colors,
      indices: _indices,
    );
  }
}

double _pageTurnLight(double angle, {required bool isBack}) {
  final edgeOn = math.pow(math.sin(angle).abs(), 1.6).toDouble();
  final flatLight = isBack ? 0.93 : 1.0;
  final foldLight = isBack ? 0.64 : 0.58;
  return ui.lerpDouble(flatLight, foldLight, edgeOn)!.clamp(0.0, 1.0);
}
