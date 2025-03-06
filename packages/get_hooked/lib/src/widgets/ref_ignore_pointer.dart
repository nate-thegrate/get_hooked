import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/element_vsync_mixin.dart';

/// A variant of [IgnorePointer] that evaluates based on a [RefComputer<bool>].
class RefIgnorePointer extends SingleChildRenderObjectWidget {
  /// Initializes [key] for subclasses.
  const RefIgnorePointer({super.key});

  ///
  bool shouldIgnore(ComputeRef ref) => true;

  @override
  RenderIgnorePointer createRenderObject(covariant ComputeContext context) {
    return RenderIgnorePointer(ignoring: shouldIgnore(context));
  }

  @override
  SingleChildRenderObjectElement createElement() => _IgnorePointerElement(this);
}

class _IgnorePointerElement extends SingleChildRenderObjectElement with ElementCompute {
  _IgnorePointerElement(super.widget);

  late final _renderer = renderObject as RenderIgnorePointer;

  @override
  void recompute() {
    _renderer.ignoring = (widget as RefIgnorePointer).shouldIgnore(this);
  }
}
