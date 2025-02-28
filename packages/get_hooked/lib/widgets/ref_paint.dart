import 'dart:collection';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import '../ref/ref.dart';

extension<T extends ValueRef> on T {
  T of(BuildContext context) {
    if (this case final ValueRef get) {
      if (GetScope.of<ValueRef>(context, get) case final T result) return result;
    }
    return this;
  }
}

/// A variation of [CustomPaint] that interfaces with [Get] objects.
abstract class RefPaint extends SingleChildRenderObjectWidget {
  /// Initializes fields for subclasses.
  const RefPaint({super.key, this.position = DecorationPosition.background, super.child});

  /// Creates a custom-painted widget using the provided [RefPaintCallback].
  ///
  /// The [PaintingRef] interface allows `ref.watch()` calls to be made
  /// in the same fashion as [Ref.watch].
  const factory RefPaint.compose(
    RefPaintCallback paintCallback, {
    Key? key,
    RefPaintHitTest? hitTest,
    RefPaintSemanticsBuilder semanticsBuilder,
    DecorationPosition position,
    Widget? child,
  }) = _RefPaint;

  /// Whether the painting is done in front of or behind the [child].
  final DecorationPosition position;

  /// Whether this widget should absorb hit tests.
  ///
  /// By default, it will not absorb any hit tests it receives if
  /// the [position] is [DecorationPosition.foreground], and it will
  /// absorb all hit tests (that do not hit descendant widgets) if it's
  /// [DecorationPosition.background].
  bool hitTest(PainterRef ref, Offset location) => position == DecorationPosition.background;

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is the size of the [size] argument.
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
  ///
  /// To paint an image on a [Canvas]…
  /// ([Get] API for [ImageStream]s—coming soon!)
  void paint(PaintingRef ref);

  /// Signature of the function returned by [CustomPainter.semanticsBuilder].
  ///
  /// Builds semantics information describing the picture drawn by a
  /// [CustomPainter]. Each [CustomPainterSemantics] in the returned list is
  /// converted into a [SemanticsNode] by copying its properties.
  ///
  /// The returned list must not be mutated after this function completes. To
  /// change the semantic information, the function must return a new list
  /// instead.
  List<CustomPainterSemantics> buildSemantics(PaintingRef ref) => const [];

  @override
  SingleChildRenderObjectElement createElement() => _RefPainterElement(this);

  @override
  RenderBox createRenderObject(BuildContext context) {
    return _RenderRefPaint(this, context as _RefPainterElement);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    (renderObject as _RenderRefPaint).painter = this;
  }
}

/// Signature for the callback within a [RefPaint] widget that paints
/// a UI element, using a [Canvas] retrieved via [PaintingRef.stageCanvas].
typedef RefPaintCallback = void Function(PaintingRef ref);

/// Signature for a callback that determines whether a [RefPaint] widget
/// will absorb a hit test. If the function or its output is `null`, the
/// widget defers to the default behavior as defined in [RefPaint.hitTest].
typedef RefPaintHitTest = bool? Function(PainterRef ref, Offset location);

/// Builds semantics information describing the picture drawn by a
/// [RefPaintCallback]. Each [CustomPainterSemantics] in the returned list is
/// converted into a [SemanticsNode] by copying its properties.
///
/// The returned list must not be mutated after this function completes. To
/// change the semantic information, the function must return a new list
/// instead.
typedef RefPaintSemanticsBuilder = List<CustomPainterSemantics> Function(PaintingRef ref);

class _RefPaint extends RefPaint {
  const _RefPaint(
    this.paintCallback, {
    super.key,
    RefPaintHitTest? hitTest,
    this.semanticsBuilder = _defaultSemantics,
    super.position,
    super.child,
  }) : _hitTest = hitTest;

  final RefPaintCallback paintCallback;

  final RefPaintHitTest? _hitTest;

  final RefPaintSemanticsBuilder semanticsBuilder;
  static List<CustomPainterSemantics> _defaultSemantics(PaintingRef ref) => const [];

  @override
  bool hitTest(PainterRef ref, Offset location) {
    return _hitTest?.call(ref, location) ?? super.hitTest(ref, location);
  }

  @override
  void paint(PaintingRef ref) => paintCallback(ref);

  @override
  List<CustomPainterSemantics> buildSemantics(PaintingRef ref) => semanticsBuilder(ref);
}

/// A reference used in [RefPaint.hitTest] calls.
///
/// See also: [PaintingRef], a subtype of `PainterRef` that
/// [RefPaint.paint] and [RefPaint.buildSemantics] interface with.
extension type PainterRef._(_RefPainterElement _element) implements Object {
  /// Use caution when accessing the [BuildContext],
  /// since any update from an [InheritedWidget] will trigger
  /// a repaint unconditionally.
  BuildContext get context => _element;

  /// The [Size] of the painter's canvas.
  Size get size => _element._size!;

  /// Returns the relevant [Get] object based on the current [context].
  ///
  /// This will be identical to the input, unless a [Substitution] was made
  /// in the ancestor [GetScope].
  G read<G extends ValueRef>(G get, {bool createDependency = true, bool throwIfMissing = false}) {
    return GetScope.of(
      context,
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }
}

/// An interface used by [RefPaint.paint] and [RefPaint.buildSemantics].
extension type PaintingRef._(_RefPainterElement _element) implements PainterRef {
  /// Called by a [RefPaint] widget to stage a [Canvas] on which to paint.
  ///
  /// This method sets compositor hints regarding whether the layer [isComplex]
  /// or is likely to change.
  Canvas stageCanvas({bool isComplex = false, bool willChange = false}) {
    assert(() {
      if (_element.paintingContext != null) return true;
      throw FlutterError.fromParts([
        ErrorSummary('PaintingRef.stageCanvas() called during buildSemantics.'),
        ErrorHint('Consider removing this method call from the buildSemantics() method body.'),
      ]);
    }());
    final PaintingContext context = _element.paintingContext!;
    if (isComplex) context.setIsComplexHint();
    if (willChange) context.setWillChangeHint();
    return context.canvas;
  }

  /// Returns the [Get] object's value, and triggers a re-render when it changes.
  T watch<T>(ValueListenable<T> get) {
    final renderer = _element.renderObject as _RenderRefPaint;
    switch (renderer._method!) {
      case _PaintMethod.hitTest:
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('ref.watch() called during a RefPainter hit test.'),
            ErrorHint('Consider using ref.read() instead.'),
          ]),
        );
      case _PaintMethod.paint when _element.handledPaint:
      case _PaintMethod.buildSemantics when _element.handledSemantics:
        break;
      case _PaintMethod.paint:
        _listen(get, renderer.markNeedsPaint);
      case _PaintMethod.buildSemantics:
        _listen(get, renderer.markNeedsSemanticsUpdate);
    }
    return get.value;
  }

  /// Returns the [selector]'s output, and triggers a re-render when it changes.
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool useScope = true,
  }) {
    if (useScope) get = get.of(context);
    return _select(get, () => selector(get.value));
  }

  /// Returns the [selector]'s value.
  ///
  /// Each time the [listenable] emits a notification, the selector is re-evaluated
  /// and triggers a re-render if the output changed.
  T _select<T>(Listenable listenable, ValueGetter<T> selector) {
    T currentValue = selector();
    final renderer = _element.renderObject as _RenderRefPaint;
    assert(
      renderer._method != null,
      '_method should be set immediately before calling any HookPainter method.',
    );
    final _PaintMethod method = renderer._method!;

    // dart format off
    final bool handled = switch (method) {
      _PaintMethod.hitTest => throw StateError('hit-testing'),
      _PaintMethod.paint => _element.handledPaint,
      _PaintMethod.buildSemantics => _element.handledSemantics,
    };

    if (handled) return currentValue;

    final VoidCallback mark = switch (method) {
      _PaintMethod.hitTest => throw StateError('hit-testing'),
      _PaintMethod.paint => renderer.markNeedsPaint,
      _PaintMethod.buildSemantics => renderer.markNeedsSemanticsUpdate,
    }; // dart format on

    _listen(listenable, () {
      final T newValue = selector();
      if (newValue != currentValue) {
        currentValue = newValue;
        mark();
      }
    });

    return currentValue;
  }

  void _listen(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    _element.disposers.add(() => listenable.removeListener(listener));
  }

  /// Registers a [GetVsync] object with this [RefPaint]'s context,
  /// in a fashion similar to [Ref.vsync].
  A vsync<A extends VsyncRef>(A getVsync, {bool useScope = true, bool watch = false}) {
    if (useScope) getVsync = GetScope.of(context, getVsync);
    _element.registry.add(getVsync);
    if (watch) {
      this.watch<Object?>(getVsync);
    }
    return getVsync;
  }
}

class _RefPainterElement extends SingleChildRenderObjectElement with ElementVsync {
  _RefPainterElement(RefPaint super.widget);

  Size? _size;

  bool handledPaint = false;
  bool handledSemantics = false;

  void resetListeners() {
    for (final VoidCallback dispose in disposers) {
      dispose();
    }
    disposers.clear();
    handledPaint = handledSemantics = false;
    renderObject
      ..markNeedsPaint()
      ..markNeedsSemanticsUpdate();
  }

  final disposers = <VoidCallback>{};

  PaintingContext? paintingContext;

  bool get hasScope => getInheritedWidgetOfExactType<ScopeModel>() != null;
  late bool _hasScope;
  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _hasScope = hasScope;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool hasScopeNow = hasScope;
    if (_hasScope || hasScopeNow) resetListeners();
    _hasScope = hasScopeNow;
    renderObject
      ..markNeedsPaint()
      ..markNeedsSemanticsUpdate();
  }

  /// Ensures that any changes to subscriptions are picked up after a Hot Reload.
  @override
  void reassemble() {
    super.reassemble();
    resetListeners();
  }

  @override
  void unmount() {
    for (final VoidCallback dispose in disposers) {
      dispose();
    }
    disposers.clear();
    super.unmount();
  }
}

enum _PaintMethod { hitTest, paint, buildSemantics }

class _RenderRefPaint extends RenderProxyBox {
  _RenderRefPaint(RefPaint hookPaint, this._element)
    : _painter = hookPaint,
      foreground = hookPaint.position == DecorationPosition.foreground;

  final _RefPainterElement _element;

  RefPaint get painter => _painter;
  RefPaint _painter;
  set painter(RefPaint newValue) {
    if (newValue == _painter) return;
    _painter = newValue;
    foreground = newValue.position == DecorationPosition.foreground;
    markNeedsPaint();
  }

  _PaintMethod? _method;

  bool foreground;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    _method = _PaintMethod.hitTest;
    final bool wasHit =
        painter.position == DecorationPosition.foreground &&
        painter.hitTest(PainterRef._(_element.._size = size), position);
    _method = null;

    return wasHit || super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    _method = _PaintMethod.hitTest;
    final bool wasHit = painter.hitTest(PainterRef._(_element.._size = size), position);
    _method = null;
    return wasHit;
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  Size computeSizeForNoChild(BoxConstraints constraints) => constraints.biggest;

  @override
  void performResize() => size = constraints.biggest;

  @override
  void performLayout() {
    child?.layout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    late int debugPreviousCanvasSaveCount;
    if (foreground) super.paint(context, offset);
    final Canvas canvas = context.canvas;
    canvas.save();
    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());
    if (offset != Offset.zero) {
      canvas.translate(offset.dx, offset.dy);
    }
    _method = _PaintMethod.paint;
    painter.paint(
      PaintingRef._(
        _element
          ..paintingContext = context
          .._size = size,
      ),
    );
    _method = null;
    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      if (debugNewCanvasSaveCount > debugPreviousCanvasSaveCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $painter hook painter called canvas.save() or canvas.saveLayer() at least '
            '${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount} more '
            'time${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.restore().',
          ),
          ErrorDescription(
            'This leaves the canvas in an inconsistent state and will probably result in a broken display.',
          ),
          ErrorHint(
            'You must pair each call to save()/saveLayer() with a later matching call to restore().',
          ),
        ]);
      }
      if (debugNewCanvasSaveCount < debugPreviousCanvasSaveCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $painter hook painter called canvas.restore() '
            '${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount} more '
            'time${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.save() or canvas.saveLayer().',
          ),
          ErrorDescription(
            'This leaves the canvas in an inconsistent state and will result in a broken display.',
          ),
          ErrorHint('You should only call restore() if you first called save() or saveLayer().'),
        ]);
      }
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }());
    canvas.restore();
    if (!foreground) super.paint(context, offset);
    _element.handledPaint = true;
  }

  List<CustomPainterSemantics> painterSemantics = const [];
  List<SemanticsNode>? semanticsNodes;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // final List<CustomPainterSemantics> semantics = _invoke(
    //   _PainterMethod.buildSemantics,
    //   () => hookPainter.buildSemantics(size),
    // );
    // config.isSemanticBoundary = semantics.isNotEmpty;
    _element.handledSemantics = true;
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    assert(() {
      if (child == null && children.isNotEmpty) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            '$runtimeType does not have a child widget but received a non-empty list of child SemanticsNode:\n'
            '${children.join('\n')}',
          ),
        ]);
      }
      return true;
    }());

    final List<SemanticsNode> nodes =
        semanticsNodes = _updateSemanticsChildren(semanticsNodes, painterSemantics);

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

  /// Updates the nodes of `oldSemantics` using data in `newChildSemantics`, and
  /// returns a new list containing child nodes sorted according to the order
  /// specified by `newChildSemantics`.
  ///
  /// [SemanticsNode]s that match [CustomPainterSemantics] by [Key]s preserve
  /// their [SemanticsNode.key] field. If a node with the same key appears in
  /// a different position in the list, it is moved to the new position, but the
  /// same object is reused.
  ///
  /// [SemanticsNode]s whose `key` is null may be updated from
  /// [CustomPainterSemantics] whose `key` is also null. However, the algorithm
  /// does not guarantee it. If your semantics require that specific nodes are
  /// updated from specific [CustomPainterSemantics], it is recommended to match
  /// them by specifying non-null keys.
  ///
  /// The algorithm tries to be as close to [RenderObjectElement.updateChildren]
  /// as possible, deviating only where the concepts diverge between widgets and
  /// semantics. For example, a [SemanticsNode] can be updated from a
  /// [CustomPainterSemantics] based on `Key` alone; their types are not
  /// considered because there is only one type of [SemanticsNode]. There is no
  /// concept of a "forgotten" node in semantics, deactivated nodes, or global
  /// keys.
  static List<SemanticsNode> _updateSemanticsChildren(
    List<SemanticsNode>? oldSemantics,
    List<CustomPainterSemantics>? newChildSemantics,
  ) {
    oldSemantics = oldSemantics ?? const <SemanticsNode>[];
    newChildSemantics = newChildSemantics ?? const <CustomPainterSemantics>[];

    assert(() {
      final Map<Object, int> keys = HashMap<Object, int>();
      final List<DiagnosticsNode> information = <DiagnosticsNode>[];
      for (int i = 0; i < newChildSemantics!.length; i += 1) {
        final CustomPainterSemantics child = newChildSemantics[i];
        if (child.key != null) {
          if (keys.containsKey(child.key)) {
            information.add(
              ErrorDescription('- duplicate key ${child.key} found at position $i'),
            );
          }
          keys[child.key!] = i;
        }
      }

      if (information.isNotEmpty) {
        information.insert(
          0,
          ErrorSummary('Failed to update the list of CustomPainterSemantics:'),
        );
        throw FlutterError.fromParts(information);
      }

      return true;
    }());

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newChildSemantics.length - 1;
    int oldChildrenBottom = oldSemantics.length - 1;

    final List<SemanticsNode?> newChildren = List<SemanticsNode?>.filled(
      newChildSemantics.length,
      null,
    );

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      if (!_canUpdateSemanticsChild(oldChild, newSemantics)) {
        break;
      }
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenBottom];
      final CustomPainterSemantics newChild = newChildSemantics[newChildrenBottom];
      if (!_canUpdateSemanticsChild(oldChild, newChild)) {
        break;
      }
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    late final Map<Key, SemanticsNode> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, SemanticsNode>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
        if (oldChild.key != null) {
          oldKeyedChildren[oldChild.key!] = oldChild;
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      SemanticsNode? oldChild;
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      if (haveOldChildren) {
        final Key? key = newSemantics.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (_canUpdateSemanticsChild(oldChild, newSemantics)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild || oldChild == null);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newChildSemantics.length - newChildrenTop == oldSemantics.length - oldChildrenTop);
    newChildrenBottom = newChildSemantics.length - 1;
    oldChildrenBottom = oldSemantics.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
      assert(_canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    assert(() {
      for (final SemanticsNode? node in newChildren) {
        assert(node != null);
      }
      return true;
    }());

    return newChildren.cast<SemanticsNode>();
  }

  /// Whether `oldChild` can be updated with properties from `newSemantics`.
  ///
  /// If `oldChild` can be updated, it is updated using [_updateSemanticsChild].
  /// Otherwise, the node is replaced by a new instance of [SemanticsNode].
  static bool _canUpdateSemanticsChild(
    SemanticsNode oldChild,
    CustomPainterSemantics newSemantics,
  ) {
    return oldChild.key == newSemantics.key;
  }

  /// Updates `oldChild` using the properties of `newSemantics`.
  ///
  /// This method requires that `_canUpdateSemanticsChild(oldChild, newSemantics)`
  /// is true prior to calling it.
  static SemanticsNode _updateSemanticsChild(
    SemanticsNode? oldChild,
    CustomPainterSemantics newSemantics,
  ) {
    assert(oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));

    final SemanticsNode newChild = oldChild ?? SemanticsNode(key: newSemantics.key);

    final SemanticsProperties properties = newSemantics.properties;
    final SemanticsConfiguration config = SemanticsConfiguration();
    if (properties.sortKey != null) {
      config.sortKey = properties.sortKey;
    }
    if (properties.checked != null) {
      config.isChecked = properties.checked;
    }
    if (properties.mixed != null) {
      config.isCheckStateMixed = properties.mixed;
    }
    if (properties.selected != null) {
      config.isSelected = properties.selected!;
    }
    if (properties.button != null) {
      config.isButton = properties.button!;
    }
    if (properties.expanded != null) {
      config.isExpanded = properties.expanded;
    }
    if (properties.link != null) {
      config.isLink = properties.link!;
    }
    if (properties.linkUrl != null) {
      config.linkUrl = properties.linkUrl;
    }
    if (properties.textField != null) {
      config.isTextField = properties.textField!;
    }
    if (properties.slider != null) {
      config.isSlider = properties.slider!;
    }
    if (properties.keyboardKey != null) {
      config.isKeyboardKey = properties.keyboardKey!;
    }
    if (properties.readOnly != null) {
      config.isReadOnly = properties.readOnly!;
    }
    if (properties.focusable != null) {
      config.isFocusable = properties.focusable!;
    }
    if (properties.focused != null) {
      config.isFocused = properties.focused!;
    }
    if (properties.enabled != null) {
      config.isEnabled = properties.enabled;
    }
    if (properties.inMutuallyExclusiveGroup != null) {
      config.isInMutuallyExclusiveGroup = properties.inMutuallyExclusiveGroup!;
    }
    if (properties.obscured != null) {
      config.isObscured = properties.obscured!;
    }
    if (properties.multiline != null) {
      config.isMultiline = properties.multiline!;
    }
    if (properties.hidden != null) {
      config.isHidden = properties.hidden!;
    }
    if (properties.header != null) {
      config.isHeader = properties.header!;
    }
    if (properties.headingLevel != null) {
      config.headingLevel = properties.headingLevel!;
    }
    if (properties.scopesRoute != null) {
      config.scopesRoute = properties.scopesRoute!;
    }
    if (properties.namesRoute != null) {
      config.namesRoute = properties.namesRoute!;
    }
    if (properties.liveRegion != null) {
      config.liveRegion = properties.liveRegion!;
    }
    if (properties.maxValueLength != null) {
      config.maxValueLength = properties.maxValueLength;
    }
    if (properties.currentValueLength != null) {
      config.currentValueLength = properties.currentValueLength;
    }
    if (properties.toggled != null) {
      config.isToggled = properties.toggled;
    }
    if (properties.image != null) {
      config.isImage = properties.image!;
    }
    if (properties.label != null) {
      config.label = properties.label!;
    }
    if (properties.value != null) {
      config.value = properties.value!;
    }
    if (properties.increasedValue != null) {
      config.increasedValue = properties.increasedValue!;
    }
    if (properties.decreasedValue != null) {
      config.decreasedValue = properties.decreasedValue!;
    }
    if (properties.hint != null) {
      config.hint = properties.hint!;
    }
    if (properties.textDirection != null) {
      config.textDirection = properties.textDirection;
    }
    if (properties.onTap != null) {
      config.onTap = properties.onTap;
    }
    if (properties.onLongPress != null) {
      config.onLongPress = properties.onLongPress;
    }
    if (properties.onScrollLeft != null) {
      config.onScrollLeft = properties.onScrollLeft;
    }
    if (properties.onScrollRight != null) {
      config.onScrollRight = properties.onScrollRight;
    }
    if (properties.onScrollUp != null) {
      config.onScrollUp = properties.onScrollUp;
    }
    if (properties.onScrollDown != null) {
      config.onScrollDown = properties.onScrollDown;
    }
    if (properties.onIncrease != null) {
      config.onIncrease = properties.onIncrease;
    }
    if (properties.onDecrease != null) {
      config.onDecrease = properties.onDecrease;
    }
    if (properties.onCopy != null) {
      config.onCopy = properties.onCopy;
    }
    if (properties.onCut != null) {
      config.onCut = properties.onCut;
    }
    if (properties.onPaste != null) {
      config.onPaste = properties.onPaste;
    }
    if (properties.onMoveCursorForwardByCharacter != null) {
      config.onMoveCursorForwardByCharacter = properties.onMoveCursorForwardByCharacter;
    }
    if (properties.onMoveCursorBackwardByCharacter != null) {
      config.onMoveCursorBackwardByCharacter = properties.onMoveCursorBackwardByCharacter;
    }
    if (properties.onMoveCursorForwardByWord != null) {
      config.onMoveCursorForwardByWord = properties.onMoveCursorForwardByWord;
    }
    if (properties.onMoveCursorBackwardByWord != null) {
      config.onMoveCursorBackwardByWord = properties.onMoveCursorBackwardByWord;
    }
    if (properties.onSetSelection != null) {
      config.onSetSelection = properties.onSetSelection;
    }
    if (properties.onSetText != null) {
      config.onSetText = properties.onSetText;
    }
    if (properties.onDidGainAccessibilityFocus != null) {
      config.onDidGainAccessibilityFocus = properties.onDidGainAccessibilityFocus;
    }
    if (properties.onDidLoseAccessibilityFocus != null) {
      config.onDidLoseAccessibilityFocus = properties.onDidLoseAccessibilityFocus;
    }
    if (properties.onFocus != null) {
      config.onFocus = properties.onFocus;
    }
    if (properties.onDismiss != null) {
      config.onDismiss = properties.onDismiss;
    }

    newChild.updateWith(
      config: config,
      // As of now CustomPainter does not support multiple tree levels.
      childrenInInversePaintOrder: const <SemanticsNode>[],
    );

    newChild
      ..rect = newSemantics.rect
      ..transform = newSemantics.transform
      ..tags = newSemantics.tags;

    return newChild;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('painter', painter));
    properties.add(StringProperty('current method', _method?.name));
  }
}
