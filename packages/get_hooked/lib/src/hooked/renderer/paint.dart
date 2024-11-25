part of '../renderer.dart';

/// A variation of [CustomPaint] that does not require any addditional class declarations.
abstract class HookPaint extends RenderHookWidget {
  /// Initializes fields for subclasses.
  const HookPaint({super.key, this.position = DecorationPosition.background, super.child});

  /// Creates a [HookDecoration] using the specified [ValueGetter] callback.
  ///
  /// The [painter], [hitTest], and [semantics] callbacks allow this widget
  /// to subscribe to updates.
  ///
  /// {@macro get_hooked.RenderHookElement}
  const factory HookPaint.compose({
    Key? key,
    required HookPainter painter,
    HookPaintHitTest? hitTest,
    SemanticsBuilderCallback semantics,
    DecorationPosition position,
    Widget? child,
  }) = _HookPaint;

  /// Whether the painting is done in front of or behind the [child].
  final DecorationPosition position;

  /// Whether this widget should absorb hit tests.
  ///
  /// By default, it will not absorb any hit tests it receives if
  /// the [position] is [DecorationPosition.foreground], and it will
  /// absorb all hit tests (that do not hit descendant widgets) if it's
  /// [DecorationPosition.background].
  bool hitTest(Offset location, Size size) => position == DecorationPosition.background;

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
  void paint(HookPaintContext context, Size size);

  /// Signature of the function returned by [CustomPainter.semanticsBuilder].
  ///
  /// Builds semantics information describing the picture drawn by a
  /// [CustomPainter]. Each [CustomPainterSemantics] in the returned list is
  /// converted into a [SemanticsNode] by copying its properties.
  ///
  /// The returned list must not be mutated after this function completes. To
  /// change the semantic information, the function must return a new list
  /// instead.
  List<CustomPainterSemantics> buildSemantics(Size size) => const [];

  @override
  SingleChildRenderHookElement createElement() => _HookPaintElement(this);

  @internal
  @override
  // ignore: library_private_types_in_public_api, I don't care
  RenderBox createRenderObject(_HookPaintElement element) {
    return _RenderHookPaint(this, element);
  }
}

/// Signature for the callback within a [HookPaint] widget that paints
/// a UI element, using a [Canvas] retrieved via [HookPaintContext.stageCanvas].
typedef HookPainter = void Function(HookPaintContext context, Size size);

/// Signature for a callback that determines whether a [HookPaint] widget
/// will absorb a hit test. If the function or its output is `null`, the
/// widget defers to the default behavior as defined in [HookPaint.hitTest].
typedef HookPaintHitTest = bool? Function(Offset location, Size size);

class _HookPaint extends HookPaint {
  const _HookPaint({
    super.key,
    required this.painter,
    HookPaintHitTest? hitTest,
    this.semantics = _defaultSemantics,
    super.position,
    super.child,
  }) : _hitTest = hitTest;

  final HookPainter painter;

  final HookPaintHitTest? _hitTest;

  final SemanticsBuilderCallback semantics;
  static List<CustomPainterSemantics> _defaultSemantics(Size size) => const [];

  @override
  bool hitTest(Offset location, Size size) {
    return _hitTest?.call(location, size) ?? super.hitTest(location, size);
  }

  @override
  void paint(HookPaintContext context, Size size) => painter(context, size);
}

/// The context in which a [HookPaint] widget paints.
///
/// The [Canvas] is accessed via [HookPaintContext.stageCanvas] in order to allow
/// setting compositor hints.
extension type HookPaintContext._(PaintingContext _context) {
  /// Instead of using a [Canvas] directly, a [HookPaint] widget uses this method to
  /// set compositor hints regarding whether the layer [isComplex] or is likely to
  /// change.
  Canvas stageCanvas({bool isComplex = false, bool willChange = false}) {
    if (isComplex) _context.setIsComplexHint();
    if (willChange) _context.setWillChangeHint();
    return _context.canvas;
  }
}

final class _HookPaintElement extends SingleChildRenderHookElement {
  _HookPaintElement(HookPaint super.widget);

  bool _handledPaint = false;
  bool _handledSemantics = false;

  @override
  void didResetListeners() {
    _handledPaint = _handledSemantics = false;
    renderObject
      ..markNeedsPaint()
      ..markNeedsSemanticsUpdate();
  }

  @override
  T select<T>(Listenable listenable, ValueGetter<T> selector) {
    T currentValue = selector();
    final renderer = renderObject as _RenderHookPaint;
    assert(
      renderer._method != null,
      '_method should be set immediately before calling any HookPainter method.',
    );
    final _PaintMethod method = renderer._method!;

    // dart format off
    final bool handled = switch (method) {
      _PaintMethod.hitTest => true,
      _PaintMethod.paint => _handledPaint,
      _PaintMethod.buildSemantics => _handledSemantics,
    };

    if (handled) return currentValue;

    final VoidCallback mark = switch (method) {
      _PaintMethod.hitTest => throw Error(),
      _PaintMethod.paint => renderer.markNeedsPaint,
      _PaintMethod.buildSemantics => renderer.markNeedsSemanticsUpdate,
    }; // dart format on

    listen(listenable, () {
      final T newValue = selector();
      if (newValue != currentValue) {
        currentValue = newValue;
        mark();
      }
    });

    return currentValue;
  }
}

enum _PaintMethod { hitTest, paint, buildSemantics }

class _RenderHookPaint extends RenderProxyBox {
  _RenderHookPaint(HookPaint hookPaint, this.hooked)
      : _hookPaint = hookPaint,
        foreground = hookPaint.position == DecorationPosition.foreground;

  final _HookPaintElement hooked;
  T _invoke<T>(_PaintMethod method, ValueGetter<T> callback) {
    Hooked.renderer = hooked;
    _method = method;
    final T result = callback();
    Hooked.renderer = _method = null;
    return result;
  }

  HookPaint get hookPaint => _hookPaint;
  HookPaint _hookPaint;
  set hookPaint(HookPaint newValue) {
    if (newValue == _hookPaint) return;
    _hookPaint = newValue;
    foreground = newValue.position == DecorationPosition.foreground;
  }

  _PaintMethod? _method;

  bool foreground;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final bool wasHit = _invoke(_PaintMethod.hitTest, () {
      return hookPaint.position == DecorationPosition.foreground &&
          hookPaint.hitTest(position, size);
    });

    return wasHit || super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return _invoke(_PaintMethod.hitTest, () => hookPaint.hitTest(position, size));
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
  void performLayout() {}

  @override
  void paint(PaintingContext context, Offset offset) {
    late int debugPreviousCanvasSaveCount;
    final Canvas canvas = context.canvas;
    if (foreground) super.paint(context, offset);
    canvas.save();
    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());
    if (offset != Offset.zero) {
      canvas.translate(offset.dx, offset.dy);
    }
    _invoke(_PaintMethod.paint, () => hookPaint.paint(HookPaintContext._(context), size));
    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      if (debugNewCanvasSaveCount > debugPreviousCanvasSaveCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $hookPaint hook painter called canvas.save() or canvas.saveLayer() at least '
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
            'The $hookPaint hook painter called canvas.restore() '
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
    hooked._handledPaint = true;
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
    hooked._handledSemantics = true;
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
    properties.add(MessageProperty('painter', '$hookPaint'));
  }
}
