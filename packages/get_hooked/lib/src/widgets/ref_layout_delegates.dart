import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';

import 'ref_layout.dart';

/// The logic and state for a [RefLayout] widget.
///
/// Subclasses should override [performLayout] to position children using
/// the provided [LayoutRef].
abstract class RefLayoutState<T extends RefLayout> {
  late T _widget;

  /// The current widget configuration.
  T get widget => _widget;

  final _delegates = <RefLayoutDelegate>[];

  bool _dryRun = false;

  /// Called when the [RefLayout] widget is first inserted into the widget tree.
  ///
  /// Override this method for any additional initialization logic.
  /// Delegate initialization is handled automatically via a dry run of [performLayout].
  void initState() {}

  /// Called during the layout phase. The provided [LayoutRef] object contains methods for laying
  /// out the widget's children.
  void performLayout(LayoutRef ref);

  int _zIndex = 0;
  BoxConstraints _constraints = const BoxConstraints();
  Size _size = .zero;
  Rect get _rect => Offset.zero & _size;
  RefLayoutElement? _element;

  /// The [BuildContext] associated with this [RefLayout].
  BuildContext get context => _element!;

  /// The [Vsync] associated with this [RefLayout].
  Vsync get vsync => _element!;

  /// Creates a delegate for one of the [RefLayout] widget's children.
  RefLayoutDelegate delegate(Widget? Function(T widget) getChild) {
    return RefLayoutDelegate._(this, () => getChild(_widget));
  }

  @visibleForOverriding
  /// See [RenderBox.computeMinIntrinsicWidth].
  double minIntrinsicWidth(double height) => 0.0;
  @visibleForOverriding
  /// See [RenderBox.computeMinIntrinsicHeight].
  double minIntrinsicHeight(double width) => 0.0;
  @visibleForOverriding
  /// See [RenderBox.computeMaxIntrinsicWidth].
  double maxIntrinsicWidth(double height) => 0.0;
  @visibleForOverriding
  /// See [RenderBox.computeMaxIntrinsicHeight].
  double maxIntrinsicHeight(double width) => 0.0;

  @visibleForOverriding
  /// See [RenderBox.computeDistanceToActualBaseline].
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;

  @visibleForOverriding
  /// See [RenderBox.computeDryBaseline].
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) => null;

  /// Called when the [RefLayout] widget is removed from the tree.
  ///
  /// Override this method for any additional cleanup logic.
  void dispose() {}
}

/// Provides layout utilities and context for [RefLayout] children during [RefLayoutState.performLayout].
extension type LayoutRef._(RefLayoutElement _element) implements Ref {
  RefLayoutState<RefLayout> get _state => _element.state;

  /// The constraints that the [RefLayout] widget's render object is currently subject to.
  BoxConstraints get constraints => _state._constraints;

  /// The current size of the [RefLayout] widget.
  Size get size => _state._size;

  /// Sets the size of the [RefLayout] widget.
  set size(Size newValue) {
    _state._size = newValue;
  }
}

/// Parent data used by [RefLayout] to position children.
class RefLayoutParentData extends BoxParentData {
  /// The z-index used for paint ordering of this child.
  int zIndex = 0;

  @override
  String toString() => 'offset=$offset, z index=$zIndex';
}

/// A handle for laying out and positioning a child of a [RefLayout].
final class RefLayoutDelegate {
  RefLayoutDelegate._(RefLayoutState<RefLayout> state, this._getWidget) : _maybeState = state {
    state._delegates.add(this);
  }

  final RefLayoutState<RefLayout>? _maybeState;
  RefLayoutState<RefLayout> get _state => _maybeState!;
  final Widget? Function() _getWidget;

  /// The [RenderBox] associated with the child widget, as specified by the `getChild` callback.
  RenderBox? _renderer;

  /// The [Element] associated with the child widget, as specified by the `getChild` callback.
  Element? _element;

  /// The horizontal and vertical distance from the top-left corner of the [RefLayout]
  /// to the top-left corner of this delegate's widget.
  Offset get offset => _renderer == null ? Offset.zero : _parentData.offset;
  set offset(Offset value) {
    if (_renderer == null) return;
    _parentData.offset = value;
  }

  /// The size of the child after layout.
  Size get size => _size;
  late Size _size = _state._size;

  RefLayoutParentData get _parentData {
    final RenderBox renderer = _renderer!;
    final ParentData? data = renderer.parentData;
    assert(
      data is RefLayoutParentData?,
      "RefLayoutDelegate found ${data.runtimeType} for its render object's parent data.",
    );
    if (data is RefLayoutParentData) return data;
    return renderer.parentData = RefLayoutParentData();
  }

  /// Returns `null` if the relevant widget is null.
  ///
  /// Otherwise, returns `this`.
  RefLayoutDelegate? get guardNull => _renderer == null ? null : this;

  /// Lays out the child to fill the given [rect], relative to the [RefLayout].
  void layoutRect(Rect rect) {
    if (_state._dryRun) {
      _renderer?.getDryLayout(BoxConstraints.tight(rect.size));
      _size = rect.size;
      _state._zIndex += 1;
      return;
    }
    _renderer!
      ..layout(BoxConstraints.tight(rect.size))
      ..parentData = (_parentData
        ..offset = rect.topLeft
        ..zIndex = _state._zIndex);
    _size = rect.size;
    _state._zIndex += 1;
  }

  /// Lays out the child using a [Rect] whose coordinates are fractions of the
  /// [RefLayout]'s size (e.g. `Rect.fromLTRB(0, 0, 0.5, 1)` fills the left half).
  void layoutFractionalRect(Rect fractionalRect) {
    if (kDebugMode) {
      final Rect(:double top, :double bottom, :double left, :double right) = fractionalRect;
      if (top < 0 || bottom > 1 || left < 0 || right > 1) {
        throw FlutterError.fromParts([
          ErrorSummary('Invalid fractional rect.'),
          ErrorDescription(
            "The RefLayout delegate's layoutFractionalRect() method expects "
            'every part of the provided rect to be within the bounds of [0, 1], '
            'but instead received the following:',
          ),
          ErrorDescription('$fractionalRect'),
          ErrorHint('Consider double-checking the size and position of this Rect object.'),
        ]);
      }
    }
    final Rect(:double left, :double top, :double right, :double bottom) = fractionalRect;
    final Size(width: double x, height: double y) = _state._size;

    layoutRect(Rect.fromLTRB(left * x, top * y, right * x, bottom * y));
  }

  /// Lays out the child inside the [RefLayout], inset by the given [padding].
  void layoutPadding(EdgeInsetsGeometry padding) {
    final Size(:double width, :double height) = _state._size;
    final EdgeInsets(:double left, :double top, :double right, :double bottom) =
        padding is EdgeInsets ? padding : padding.resolve(Directionality.of(_state._element!));

    layoutRect(Rect.fromLTRB(left, top, width - right, height - bottom));
  }

  /// To perform an aligned layout without setting a size, use a `delegate()`
  /// instead of a `fixedDelegate()`.
  ///
  /// Alternatively, use [layoutFractionalRect] to set both size and position
  /// relative to the [RefLayout] widget's total size.
  void layoutAlign(Alignment alignment, {Size? size}) {
    if (size != null) {
      layoutRect(alignment.inscribe(_size = size, _state._rect));
      return;
    }
    if (_state._dryRun) {
      if (_renderer != null) {
        _size = _renderer!.getDryLayout(BoxConstraints.loose(_state._size));
      } else {
        _size = Size.zero;
      }
      _state._zIndex += 1;
      return;
    }
    final RenderBox renderer = _renderer!
      ..layout(BoxConstraints.loose(_state._size), parentUsesSize: true);
    renderer.parentData = _parentData
      ..offset = alignment.inscribe(_size = renderer.size, _state._rect).topLeft
      ..zIndex = _state._zIndex;

    _state._zIndex += 1;
  }

  /// Lays out the delegate's [RenderBox] using the specified constraints and returns its size.
  ///
  /// Afterward, the delegate's position can be adjusted by setting its [offset] value.
  Size layout({BoxConstraints? constraints}) {
    BoxConstraints effectiveConstraints = BoxConstraints.loose(_state._size);
    effectiveConstraints = constraints?.enforce(effectiveConstraints) ?? effectiveConstraints;
    if (_state._dryRun) {
      _state._zIndex += 1;
      if (_renderer != null) {
        return _size = _renderer!.getDryLayout(effectiveConstraints);
      }
      return _size = effectiveConstraints.smallest;
    }
    final RenderBox renderer = _renderer!;
    _parentData.zIndex = _state._zIndex;
    renderer.layout(effectiveConstraints, parentUsesSize: true);
    _state._zIndex += 1;
    return renderer.size;
  }

  /// Returns the minimum intrinsic width of the child for the given height.
  double getMinIntrinsicWidth(double height) {
    return _renderer?.getMinIntrinsicWidth(height) ?? 0.0;
  }

  /// Returns the minimum intrinsic height of the child for the given width.
  double getMinIntrinsicHeight(double width) {
    return _renderer?.getMinIntrinsicHeight(width) ?? 0.0;
  }

  /// Returns the size that the child would have if laid out with the given constraints.
  Size getSize(BoxConstraints constraints) {
    return _renderer?.getDryLayout(constraints) ?? .zero;
  }

  /// Returns the distance from the top of the child to the first baseline of the given type.
  double? getDistanceToBaseline(TextBaseline baseline, {bool onlyReal = false}) {
    return _renderer?.getDistanceToBaseline(baseline, onlyReal: onlyReal);
  }

  /// Returns the baseline of the child after laying it out with the given constraints.
  double? getBaseline(BoxConstraints constraints, TextBaseline baseline) {
    return _renderer?.getDryBaseline(constraints, baseline);
  }
}

@internal
class RefLayoutElement extends RenderObjectElement with ElementCompute {
  /// Creates an element that uses the given widget as its configuration.
  // ignore: invalid_use_of_protected_member, intended usage
  RefLayoutElement(RefLayout super.widget) : _state = widget.createState().._widget = widget {
    state._element = this;
  }

  RefLayoutState<RefLayout> get state => _state!;
  RefLayoutState<RefLayout>? _state;

  @override
  void recompute() => renderObject.markNeedsLayout();

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    state
      .._dryRun = true
      ..initState()
      ..performLayout(LayoutRef._(this))
      .._dryRun = false;
    for (final RefLayoutDelegate delegate in state._delegates.toList()) {
      if (delegate._getWidget() case final widget?) {
        delegate._element = updateChild(delegate._element, widget, delegate);
      }
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final RefLayoutDelegate child in state._delegates) {
      if (child._element case final element?) visitor(element);
    }
  }

  @override
  void forgetChild(Element child) {
    for (final RefLayoutDelegate delegate in state._delegates) {
      if (delegate._element == child) {
        delegate
          .._element = null
          .._renderer = null;
        break;
      }
    }
    super.forgetChild(child);
  }

  @override
  void update(RefLayout newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    state._widget = newWidget;
    for (final RefLayoutDelegate delegate in state._delegates) {
      delegate._element = updateChild(delegate._element, delegate._getWidget(), delegate);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    renderObject.markNeedsLayout();
  }

  @override
  void insertRenderObjectChild(RenderBox child, RefLayoutDelegate slot) {
    // ignore: invalid_use_of_protected_member, intended usage
    (renderObject as RenderRefLayout).adoptChild(slot._renderer = child);
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    RefLayoutDelegate oldSlot,
    RefLayoutDelegate newSlot,
  ) {
    assert(throw StateError('RefLayout does not support moving children between delegates.'));
  }

  @override
  void removeRenderObjectChild(RenderBox child, RefLayoutDelegate slot) {
    assert(slot._renderer == child);
    // ignore: invalid_use_of_protected_member, intended usage
    (renderObject as RenderRefLayout).dropChild(child);
  }

  @override
  void unmount() {
    for (final RefLayoutDelegate delegate in state._delegates) {
      delegate
        .._element = null
        .._renderer = null;
    }
    state.dispose();
    _state = null;
    super.unmount();
  }
}

@internal
class RenderRefLayout extends RenderBox {
  RefLayoutState<RefLayout>? state;
  Iterable<RenderBox> get children sync* {
    if (state != null) {
      for (final RefLayoutDelegate delegate in state!._delegates) {
        if (delegate._renderer case final child?) yield child;
      }
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox child in children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final RenderBox child in children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() => children.forEach(redepthChild);

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[for (final child in children) child.toDiagnosticsNode()];
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! RefLayoutParentData) {
      child.parentData = RefLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => state!.minIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) => state!.maxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => state!.minIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => state!.maxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return state?.computeDistanceToActualBaseline(baseline);
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    return state?.computeDryBaseline(constraints, baseline);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final RefLayoutState<RefLayout> state = this.state!;
    final BoxConstraints actualConstraints = state._constraints;
    final Size actualSize = state._size;
    state
      .._dryRun = true
      .._constraints = constraints
      .._size = constraints.biggest
      ..performLayout(LayoutRef._(state._element!))
      .._dryRun = false;
    final Size result = state._size;
    state
      .._constraints = actualConstraints
      .._size = actualSize;
    return result;
  }

  @override
  void performLayout() {
    final RefLayoutState<RefLayout> state = this.state!;
    state
      .._zIndex = 0
      .._constraints = constraints
      .._size = constraints.biggest
      ..performLayout(LayoutRef._(state._element!))
      .._delegates.sort((a, b) => a._parentData.zIndex.compareTo(b._parentData.zIndex));
    size = state._size;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox renderBox in children.toList().reversed) {
      if (renderBox.parentData case RefLayoutParentData(:final offset)
          when (offset & renderBox.size).contains(position) &&
              renderBox.hitTest(result, position: position - offset)) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((child) {
      context.paintChild(child, offset + (child.parentData! as RefLayoutParentData).offset);
    });
  }
}
