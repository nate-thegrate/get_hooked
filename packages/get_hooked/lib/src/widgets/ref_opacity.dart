import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

/// A variant of [Opacity] that evaluates based on a [RefComputer<double>].
class RefOpacity extends SingleChildRenderObjectWidget {
  /// Creates a [Opacity] widget using the provided [RefComputer] callback.
  const RefOpacity(this.opacity, {super.key, this.alwaysIncludeSemantics = false, super.child});

  /// Computes the fraction to scale the child's alpha value.
  ///
  /// An opacity of one is fully opaque. An opacity of zero is fully transparent
  /// (i.e., invisible).
  ///
  /// Values one and zero are painted with a fast path. Other values require
  /// painting the child into an intermediate buffer, which is expensive.
  final RefComputer<double> opacity;

  /// Whether the semantic information of the children is always included.
  ///
  /// Defaults to false.
  ///
  /// When true, regardless of the opacity settings the child semantic
  /// information is exposed as if the widget were fully visible. This is
  /// useful in cases where labels may be hidden during animations that
  /// would otherwise contribute relevant semantics.
  final bool alwaysIncludeSemantics;

  @override
  RenderOpacity createRenderObject(BuildContext context) {
    return RenderOpacity(alwaysIncludeSemantics: alwaysIncludeSemantics);
  }

  @override
  void updateRenderObject(BuildContext context, RenderOpacity renderObject) {
    renderObject.alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  SingleChildRenderObjectElement createElement() => _OpacityElement(this);
}

class _OpacityElement extends SingleChildComputeElement<RenderOpacity> {
  _OpacityElement(super.widget);

  @override
  void recompute() {
    renderer.opacity = (widget as RefOpacity).opacity(this);
  }
}
