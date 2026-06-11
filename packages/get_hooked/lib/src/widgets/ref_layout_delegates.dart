// ignore_for_file: public_member_api_docs, use_late_for_private_fields_and_variables, unused_field, unused_element, procrastinate!

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

import 'ref_layout.dart';

abstract class RefLayoutState<T extends RefLayout> {
  T? _widget;
  T get widget => _widget!;

  final _delegates = <RefLayoutDelegate>[];

  /// Called when the [RefLayout] widget is first inserted into the widget tree.
  /// Returns a [Object] containing every [RefLayoutDelegate] used by this state.
  ///
  /// This ensures that `late final` delegate fields are initialized at the correct time.
  ///
  /// When implementing this method, feel free to include any other relevant initialization logic
  /// as well.
  Object initState();

  /// Called during the layout phase. The provided [LayoutRef] object contains methods for laying
  /// out the widget's children.
  void performLayout(LayoutRef ref);

  int _zIndex = 0;
  late BoxConstraints _constraints;
  late Size _size = _constraints.biggest;
  Rect get _rect => Offset.zero & _size;
  RefLayoutElement? _element;

  BuildContext get context => _element!;
  Vsync get vsync => _element!;

  /// Creates a delegate for one of the [RefLayout] widget's children.
  RefLayoutDelegate delegate(Widget? Function(T widget) getChild) {
    return RefLayoutDelegate._(this, () => getChild(_widget!));
  }

  @visibleForOverriding
  double minIntrinsicWidth(double height) => 0.0;
  @visibleForOverriding
  double minIntrinsicHeight(double width) => 0.0;
  @visibleForOverriding
  double maxIntrinsicWidth(double height) => 0.0;
  @visibleForOverriding
  double maxIntrinsicHeight(double width) => 0.0;

  @visibleForOverriding
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;

  @visibleForOverriding
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) => null;

  void dispose() {}
}

extension type LayoutRef._(RefLayoutElement _element) implements Ref {
  RefLayoutState<RefLayout> get _state => _element.state;

  BoxConstraints get constraints => _state._constraints;

  Size get size => _state._size;
  set size(Size newValue) {
    _state._size = newValue;
  }
}

class RefLayoutParentData extends BoxParentData {
  int zIndex = 0;

  @override
  String toString() => 'offset=$offset, z index=$zIndex';
}

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

  void layoutRect(Rect rect) {
    _renderer!
      ..layout(BoxConstraints.tight(rect.size))
      ..parentData = (_parentData
        ..offset = rect.topLeft
        ..zIndex = _state._zIndex);
    _size = rect.size;
    _state._zIndex += 1;
  }

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
    } else {
      final RenderBox renderer = _renderer!
        ..layout(BoxConstraints.loose(_state._size), parentUsesSize: true);
      renderer.parentData = _parentData
        ..offset = alignment.inscribe(_size = renderer.size, _state._rect).topLeft
        ..zIndex = _state._zIndex;

      _state._zIndex += 1;
    }
  }

  /// Lays out the delegate's [RenderBox] using the specified constraints and returns its size.
  ///
  /// Afterward, [positionAt] can be called to adjust the position accordingly.
  Size layout({BoxConstraints? constraints}) {
    final RenderBox renderer = _renderer!;

    _parentData.zIndex = _state._zIndex;

    BoxConstraints effectiveConstraints = BoxConstraints.loose(_state._size);
    effectiveConstraints = constraints?.enforce(effectiveConstraints) ?? effectiveConstraints;
    renderer.layout(effectiveConstraints, parentUsesSize: true);
    _state._zIndex += 1;
    return renderer.size;
  }

  /// Moves the delegate to the specified position.
  ///
  /// This method is most commonly called after [layout] is used to obtain the [Size].
  // ignore: use_setters_to_change_properties, API design choice
  void positionAt(Offset topLeft) {
    _parentData.offset = topLeft;
  }

  double getMinIntrinsicWidth(double height) {
    return _renderer!.getMinIntrinsicWidth(height);
  }

  double getMinIntrinsicHeight(double width) {
    return _renderer!.getMinIntrinsicHeight(width);
  }

  Size getSize(BoxConstraints constraints) {
    return _renderer!.getDryLayout(constraints);
  }

  double? getDistanceToBaseline(TextBaseline baseline, {bool onlyReal = false}) {
    return _renderer?.getDistanceToBaseline(baseline, onlyReal: onlyReal);
  }

  double? getBaseline(BoxConstraints constraints, TextBaseline baseline) {
    return _renderer?.getDryBaseline(constraints, baseline);
  }
}

extension on Set<RefLayoutDelegate> {
  RefLayoutDelegate? operator [](Element element) {
    for (final delegate in this) {
      if (delegate._element == element) return delegate;
    }
    return null;
  }

  void operator []=(Element element, RefLayoutDelegate? value) {
    if (this[element] case final delegate?) {
      remove(delegate);
    }
    if (value != null) {
      add(value.._element = element);
    }
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
    state.initState();
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

extension on List<RenderBox> {
  List<RenderBox> get sorted {
    return toList()..sort(
      (a, b) => (a.parentData! as RefLayoutParentData).zIndex.compareTo(
        (b.parentData! as RefLayoutParentData).zIndex,
      ),
    );
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
    state
      .._constraints = constraints
      .._size = constraints.biggest
      ..performLayout(LayoutRef._(state._element!));
    final Size result = state._size;
    state
      .._constraints = actualConstraints
      .._size = actualConstraints.biggest;
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
