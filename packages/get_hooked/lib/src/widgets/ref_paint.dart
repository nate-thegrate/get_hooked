import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';
import 'package:get_hooked/src/scope.dart';

import 'ref_clip.dart';
import 'ref_paint_semantics.dart' as semantics;

/// A variation of [CustomPaint] that uses a [PaintRef]
/// to interface with [ValueListenable] objects.
class RefPaint extends SingleChildRenderObjectWidget {
  /// Creates a custom-painted widget using the provided [RefPaintCallback].
  const RefPaint(
    this.paint, {
    super.key,
    this.foreground = false,
    this.expanded,
    this.semanticsBuilder,
    super.child,
  });

  /// If true, this widget paints itself after the [child] in order to show up in front.
  ///
  /// If false (the default), this widget is shown behind the [child].
  final bool foreground;

  /// If `true`, the widget and its [child] will expand to fill the maximum space available.
  ///
  /// If `false`, this painter will match the [child]'s size.
  ///
  /// If `null` (the default), the painter fills the available space
  /// but does not apply additional constraints to the [child].
  ///
  /// If the child is `null`, this value is ignored and the painter fills the available space.
  final bool? expanded;

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is represented by the `size` argument.
  ///
  /// Paint operations should remain inside the given area. Graphical
  /// operations outside the bounds may be silently ignored, clipped, or not
  /// clipped. It may sometimes be difficult to guarantee that a certain
  /// operation is inside the bounds (e.g., drawing a rectangle whose size is
  /// determined by user inputs). In that case, consider calling
  /// [Canvas.clipRect] at the beginning of [paint] so everything that follows
  /// will be guaranteed to only draw within the clipped area.
  ///
  /// Implementations should be wary of correctly pairing any calls to
  /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
  /// subsequent painting on this canvas may be affected, with potentially
  /// hilarious but confusing results.
  ///
  /// To paint text on a [Canvas], use a [TextPainter].
  /// (Alternatively, include a [Text] widget as part of this painter's [child].)
  ///
  /// To paint an image on a [Canvas], use [PaintRef.loadImage].
  final RefPaintCallback paint;

  /// Signature of the function returned by [CustomPainter.semanticsBuilder].
  ///
  /// Builds semantics information describing the picture drawn by this widget.
  /// Each [CustomPainterSemantics] in the returned list is
  /// converted into a [SemanticsNode] by copying its properties.
  ///
  /// Rather than creating & modifying a single object, this callback should
  /// return a new list literal each time.
  final RefPaintSemanticsBuilder? semanticsBuilder;

  @override
  SingleChildRenderObjectElement createElement() => _RefPainterElement(this);

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderRefPaint(this, context);

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    (renderObject as _RenderRefPaint).painter = this;
  }
}

/// Signature for the callback within a [RefPaint] widget that paints
/// a UI element using a [PaintRef].
typedef RefPaintCallback = void Function(PaintRef ref);

/// Builds semantics information describing the picture drawn by a
/// [RefPaintCallback]. Each [CustomPainterSemantics] in the returned list is
/// converted into a [SemanticsNode] by copying its properties.
///
/// The returned list must not be mutated after this function completes. To
/// change the semantic information, the function must return a new list
/// instead.
typedef RefPaintSemanticsBuilder = List<CustomPainterSemantics> Function(PaintRef ref);

/// An interface used by [RefPaint.paint] and [RefPaint.semanticsBuilder].
abstract interface class PaintRef implements ClipRef {
  /// The painter's [BuildContext].
  BuildContext get context;

  /// The [Canvas] on which to paint.
  Canvas get canvas;

  /// Hints that the painting in the current layer is complex and would benefit
  /// from caching.
  ///
  /// If this hint is not set, the compositor will apply its own heuristics to
  /// decide whether the current layer is complex enough to benefit from
  /// caching.
  ///
  /// Calling this ensures a [Canvas] is available. Only draw calls on the
  /// current canvas will be hinted; the hint is not propagated to new canvases
  /// created after a new layer is added to the painting context.
  void setIsComplexHint();

  /// Hints that the painting in the current layer is likely to change next frame.
  ///
  /// This hint tells the compositor not to cache the current layer because the
  /// cache will not be used in the future. If this hint is not set, the
  /// compositor will apply its own heuristics to decide whether the current
  /// layer is likely to be reused in the future.
  ///
  /// Calling this ensures a [Canvas] is available. Only draw calls on the
  /// current canvas will be hinted; the hint is not propagated to new canvases
  /// created after a new layer is added to the painting context.
  void setWillChangeHint();

  /// Load and paint an image using the specified [ImageProvider].\
  /// The `size` parameter corresponds to [ImageConfiguration.size].
  ///
  /// Returns `null` while the image is loading.
  ///
  /// ```dart
  /// final image = ref.loadImage(AssetImage('assets/my_image.png'));
  ///
  /// if (image != null) {
  ///   ref.canvas.drawImage(image, Offset.zero, Paint());
  /// }
  /// ```
  ///
  /// See also:
  ///  - [Image], a dedicated widget that gives more fine-grained control
  ///    over how the image is loaded and displayed.
  ///  - [ImageStream], Flutter's built-in image loading API.
  ui.Image? loadImage(ImageProvider provider, {Size? size});

  /// Configure the area where this widget should respond to hit tests.
  /// Typically, [Path.combine] is used with [PathOperation.union] to represent
  /// the total area being painted.
  ///
  /// If this method is not called, anywhere inside the canvas is considered to be a hit.
  void hitTestArea({Path? path, Rect? rect});
}

class _RefPainterElement extends SingleChildComputeElement<_RenderRefPaint> implements PaintRef {
  _RefPainterElement(RefPaint super.widget);

  @override
  void recompute() => renderer.markNeedsPaint();

  /// Set to `true` while [RefPaint.semanticsBuilder] is being invoked.
  var buildingSemantics = false;

  /// Listenables subscribed via [watch] during [RefPaint.semanticsBuilder].
  final _subscriptions = <ValueListenable<Object?>>{};

  /// Disposers for [watch] listeners registered during [RefPaint.semanticsBuilder].
  final _disposers = <VoidCallback>{};

  /// Keys are listenables, values are disposers for [select] during semantics.
  final _selectors = <ValueListenable<Object?>, VoidCallback>{};

  PaintingContext? _paintingContext;

  final _imageProviders = _ImageProviders();

  void _prepImages() {
    if (_imageProviders.isEmpty) return;

    for (final _ImageProviderState state in _imageProviders.values) {
      state.stale = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final _ImageProviderState state
          in _imageProviders.values.where((state) => state.stale).toSet()) {
        state.dispose();
      }
    });
  }

  /// Stable tear-off target so [Listenable.removeListener] matches add.
  void _markNeedsSemanticsUpdate() => renderer.markNeedsSemanticsUpdate();

  void _clearSemanticsListeners() {
    for (final VoidCallback dispose in _disposers.followedBy(_selectors.values)) {
      dispose();
    }
    _disposers.clear();
    _selectors.clear();
    _subscriptions.clear();
  }

  void _resetSemanticsListeners() {
    _clearSemanticsListeners();
    _markNeedsSemanticsUpdate();
  }

  bool get _hasSemanticsScope => _semanticsScopeTag != null;
  Object? _semanticsScopeTag;
  Object? get _newSemanticsScopeTag =>
      getInheritedWidgetOfExactType<SubstitutionModel>()?.equalityTag;

  @override
  Size get size => renderer.size;

  @override
  BuildContext get context => this;

  @override
  Canvas get canvas {
    if (kDebugMode) _debugCheckPainting('canvas');
    return _paintingContext!.canvas;
  }

  @override
  void setIsComplexHint() {
    if (kDebugMode) _debugCheckPainting('setIsComplexHint()');
    _paintingContext?.setIsComplexHint();
  }

  @override
  void setWillChangeHint() {
    if (kDebugMode) _debugCheckPainting('setWillChangeHint()');
    _paintingContext?.setWillChangeHint();
  }

  void _debugCheckPainting(String fieldName) {
    if (kDebugMode && buildingSemantics) {
      throw FlutterError.fromParts([
        ErrorSummary('PaintRef.$fieldName accessed during buildSemantics.'),
        ErrorHint('Consider removing this method call from the buildSemantics() method body.'),
      ]);
    }
  }

  @override
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true}) {
    if (!buildingSemantics) {
      return super.watch(listenable, autoVsync: autoVsync, useScope: useScope);
    }

    final (scoped, value) = read(listenable, useScope: useScope && _hasSemanticsScope);
    if (_subscriptions.add(listenable)) {
      scoped.addListener(_markNeedsSemanticsUpdate);
      _disposers.add(() => scoped.removeListener(_markNeedsSemanticsUpdate));

      if (listenable == scoped && autoVsync && listenable is VsyncValue<T>) {
        if (registry.add(listenable)) _disposers.add(() => registry.remove(listenable));
      }
    }
    return value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (!buildingSemantics) {
      return super.select(listenable, selector, autoVsync: autoVsync, useScope: useScope);
    }

    final (scoped, value) = read(listenable, useScope: useScope && _hasSemanticsScope);
    Result currentValue = selector(value);
    void checkSelection() {
      final Result newValue = selector(
        read(listenable, useScope: useScope && _hasSemanticsScope).$2,
      );
      if (newValue != currentValue) {
        currentValue = newValue;
        _markNeedsSemanticsUpdate();
      }
    }

    _selectors.remove(listenable)?.call();
    scoped.addListener(checkSelection);
    _selectors[listenable] = () => scoped.removeListener(checkSelection);

    if (listenable == scoped && autoVsync && listenable is VsyncValue<T>) {
      if (registry.add(listenable)) _disposers.add(() => registry.remove(listenable));
    }
    return currentValue;
  }

  @override
  ui.Image? loadImage(ImageProvider provider, {Size? size}) {
    if (_imageProviders[provider] case _ImageProviderState(:final image)) {
      return image;
    }
    return _ImageProviderState(this, provider, size).image;
  }

  @override
  void hitTestArea({Path? path, Rect? rect}) {
    if (rect != null) path = Path()..addRect(rect);
    if (path != null) renderer.updateHitArea(path);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _semanticsScopeTag = _newSemanticsScopeTag;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? newTag = _newSemanticsScopeTag;
    if (newTag != _semanticsScopeTag) {
      _semanticsScopeTag = newTag;
      _resetSemanticsListeners();
    }
  }

  /// Ensures that any changes to subscriptions are picked up after a Hot Reload.
  @override
  void reassemble() {
    super.reassemble();
    _resetSemanticsListeners();
  }

  @override
  void unmount() {
    _clearSemanticsListeners();

    for (final _ImageProviderState provider in _imageProviders.values.toSet()) {
      provider.dispose();
    }
    // ElementCompute.unmount clears paint watch/select listeners, tickers, etc.
    super.unmount();
  }
}

typedef _ImageProviders = HashMap<ImageProvider, _ImageProviderState>;

class _ImageProviderState {
  _ImageProviderState(this.element, ImageProvider imageProvider, this.size)
    : provider = ScrollAwareImageProvider(
        context: _Context(element),
        imageProvider: imageProvider,
      ) {
    final HashMap<ImageProvider<Object>, _ImageProviderState> providers = element._imageProviders;

    providers[imageProvider] = this;

    final listener = ImageStreamListener((info, synchronousCall) {
      final ui.Image newImage = info.image;
      if (!identical(_image, newImage)) {
        _image?.dispose();
        _image = info.image;
      }

      if (!synchronousCall) element.renderer.markNeedsPaint();
    });

    final ImageStream imageStream = provider.resolve(
      createLocalImageConfiguration(provider.context.context!, size: size),
    );

    imageStream.addListener(listener);

    _stopListening = () {
      imageStream.removeListener(listener);
      providers.remove(imageProvider);
    };
  }

  final _RefPainterElement element;
  final ScrollAwareImageProvider provider;
  final Size? size;

  late final VoidCallback _stopListening;

  ui.Image? _image;
  ui.Image? get image {
    stale = false;
    return _image;
  }

  bool stale = false;

  void dispose() {
    _stopListening();
    provider.context.dispose();
    image?.dispose();
  }
}

class _Context implements DisposableBuildContext {
  _Context(BuildContext this.context);

  @override
  BuildContext? context;

  @override
  void dispose() {
    context = null;
  }
}

class _RenderRefPaint extends RenderProxyBox {
  _RenderRefPaint(RefPaint hookPaint, BuildContext context)
    : _element = context as _RefPainterElement,
      _painter = hookPaint,
      _foreground = hookPaint.foreground,
      _expanded = hookPaint.expanded;

  _RefPainterElement get element => _element!;
  _RefPainterElement? _element;

  RefPaint get painter => _painter;
  RefPaint _painter;
  set painter(RefPaint newValue) {
    if (newValue == _painter) return;
    _painter = newValue;
    foreground = newValue.foreground;
    expanded = newValue.expanded;
  }

  bool get foreground => _foreground;
  bool _foreground;
  set foreground(bool newValue) {
    if (newValue == _foreground) return;

    _foreground = newValue;
    markNeedsPaint();
  }

  bool? get expanded => _expanded;
  bool? _expanded;
  set expanded(bool? newValue) {
    if (newValue == _expanded) return;
    final bool sizedByParent = this.sizedByParent;
    _expanded = newValue;
    (this.sizedByParent == sizedByParent)
        ? markNeedsLayout()
        : markNeedsLayoutForSizedByParentChange();
  }

  Path? _hitArea;
  // ignore: use_setters_to_change_properties, used as tear-off
  void updateHitArea(Path newPath) {
    _hitArea = newPath;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    bool hitTestSelf() {
      final bool wasHit = _hitArea?.contains(position) ?? true;

      if (wasHit) result.add(BoxHitTestEntry(this, position));
      return wasHit;
    }

    if (painter.foreground) {
      return hitTestSelf() || hitTestChildren(result, position: position);
    } else {
      return hitTestChildren(result, position: position) || hitTestSelf();
    }
  }

  @override
  bool get sizedByParent => child == null || (_expanded ?? true);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (_expanded == false) {
      if (child case final child?) return child.computeDryLayout(constraints);
    }
    return constraints.biggest;
  }

  @override
  Size computeSizeForNoChild(BoxConstraints constraints) => constraints.biggest;

  @override
  void performResize() => size = constraints.biggest;

  @override
  void adoptChild(RenderObject child) {
    final bool sizedByParent = this.sizedByParent;
    super.adoptChild(child);
    if (this.sizedByParent != sizedByParent) markNeedsLayoutForSizedByParentChange();
  }

  @override
  void dropChild(RenderObject child) {
    final bool sizedByParent = this.sizedByParent;
    super.dropChild(child);
    if (this.sizedByParent != sizedByParent) markNeedsLayoutForSizedByParentChange();
  }

  @override
  void performLayout() {
    if (child case final child?) {
      switch (_expanded) {
        case true:
          child.layout(BoxConstraints.tight(constraints.biggest));
        case null:
          child.layout(constraints);
        case false:
          child.layout(constraints, parentUsesSize: true);
          size = child.size;
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    late int debugPreviousCanvasSaveCount;
    if (foreground) super.paint(context, offset);
    final Canvas canvas = context.canvas;
    canvas.save();
    if (kDebugMode) debugPreviousCanvasSaveCount = canvas.getSaveCount();
    if (offset != Offset.zero) {
      canvas.translate(offset.dx, offset.dy);
    }
    final _RefPainterElement element = this.element.._prepImages();
    element._paintingContext = context;
    try {
      painter.paint(element);
    } finally {
      element._paintingContext = null;
    }
    if (kDebugMode) {
      final int difference = canvas.getSaveCount() - debugPreviousCanvasSaveCount;
      switch (difference) {
        case > 0:
          throw FlutterError.fromParts([
            ErrorSummary(
              'The $painter hook painter called canvas.save() or canvas.saveLayer() at least '
              '$difference more time${difference == 1 ? '' : 's'} than it called canvas.restore().',
            ),
            ErrorDescription(
              'This leaves the canvas in an inconsistent state '
              'and will probably result in a broken display.',
            ),
            ErrorHint(
              'Ensure that each save()/saveLayer() call is paired '
              'with a later matching call to restore().',
            ),
          ]);
        case < 0:
          throw FlutterError.fromParts([
            ErrorSummary(
              'The $painter hook painter called canvas.restore() '
              '${-difference} more time${difference == -1 ? '' : 's'} '
              'than it called canvas.save() or canvas.saveLayer().',
            ),
            ErrorDescription(
              'This leaves the canvas in an inconsistent state '
              'and will result in a broken display.',
            ),
            ErrorHint('Ensure that each restore() call is preceded by save() or saveLayer().'),
          ]);
      }
    }
    canvas.restore();
    if (!foreground) super.paint(context, offset);
  }

  List<CustomPainterSemantics> painterSemantics = const [];
  List<SemanticsNode>? semanticsNodes;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    if (painter.semanticsBuilder case final buildSemantics?) {
      final _RefPainterElement element = this.element;
      element.buildingSemantics = true;
      try {
        painterSemantics = buildSemantics(element);
      } finally {
        element.buildingSemantics = false;
      }
    }
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    if (kDebugMode && child == null && children.isNotEmpty) {
      throw FlutterError.fromParts([
        ErrorSummary(
          '$runtimeType does not have a child widget but received a non-empty list of child SemanticsNode:\n'
          '${children.join('\n')}',
        ),
      ]);
    }

    final List<SemanticsNode> nodes = semanticsNodes = semantics.updateSemanticsChildren(
      semanticsNodes,
      painterSemantics,
    );

    final List<SemanticsNode> finalChildren = <SemanticsNode>[
      if (!foreground) ...nodes,
      ...children,
      if (foreground) ...nodes,
    ];
    super.assembleSemanticsNode(node, config, finalChildren);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    semanticsNodes = null;
  }

  @override
  void dispose() {
    _element = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('painter', painter));
  }
}
