import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/element_vsync_mixin.dart';

/// A variant of [IgnorePointer] that evaluates based on a [RefComputer<bool>].
abstract class RefIgnorePointer extends SingleChildRenderObjectWidget {
  /// Creates an [IgnorePointer] widget using the provided [RefComputer] callback.
  const factory RefIgnorePointer(
    RefComputer<bool> shouldIgnore, {
    Key? key,
    required Widget child,
  }) = _RefIgnorePointer;

  /// Initializes [key] for subclasses.
  const RefIgnorePointer.constructor({super.key, required Widget super.child});

  /// Whether the [child] and its descendants should be exposed to pointer events.
  ///
  /// Returning `true` will cause pointer events to be ignored.
  bool shouldIgnore(Ref ref);

  @override
  RenderIgnorePointer createRenderObject(BuildContext context) => RenderIgnorePointer();

  @override
  SingleChildRenderObjectElement createElement() => _IgnorePointerElement(this);
}

class _RefIgnorePointer extends RefIgnorePointer {
  const _RefIgnorePointer(this._shouldIgnore, {super.key, required super.child})
    : super.constructor();

  final RefComputer<bool> _shouldIgnore;

  @override
  bool shouldIgnore(Ref ref) => _shouldIgnore(ref);
}

class _IgnorePointerElement extends SingleChildComputeElement<RenderIgnorePointer> {
  _IgnorePointerElement(super.widget);

  @override
  void recompute() {
    renderObject.ignoring = (widget as RefIgnorePointer).shouldIgnore(this);
  }
}
