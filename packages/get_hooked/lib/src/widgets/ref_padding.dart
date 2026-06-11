import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

/// A variant of [Padding] that evaluates based on a [RefComputer<EdgeInsetsGeometry>].
class RefPadding extends SingleChildRenderObjectWidget {
  /// Creates an [Padding] widget using the provided [RefComputer] callback.
  const RefPadding(this.padding, {super.key, required Widget super.child});

  /// The amount of space by which to inset the child.
  final RefComputer<EdgeInsetsGeometry> padding;

  @override
  RenderPadding createRenderObject(BuildContext context) =>
      RenderPadding(padding: EdgeInsets.zero);

  @override
  SingleChildRenderObjectElement createElement() => _PaddingElement(this);
}

class _PaddingElement extends SingleChildComputeElement<RenderPadding> {
  _PaddingElement(super.widget);

  @override
  void recompute() {
    renderer.padding = (widget as RefPadding).padding(this);
  }
}
