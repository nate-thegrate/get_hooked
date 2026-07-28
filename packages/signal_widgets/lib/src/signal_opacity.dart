import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// A variant of [Opacity] that evaluates based on a [SignalComputer<double>].
///
/// Signals read via `.value` inside [opacity] are tracked automatically. When
/// they change, only the [RenderOpacity] is updated — the child is not rebuilt.
///
/// ```dart
/// final fade = signal(1.0);
///
/// SignalOpacity(
///   (context) => fade.value,
///   child: const FlutterLogo(size: 64),
/// );
/// ```
class SignalOpacity extends SingleChildRenderObjectWidget {
  /// Creates an [Opacity] widget using the provided [SignalComputer] callback.
  const SignalOpacity(
    this.opacity, {
    super.key,
    this.alwaysIncludeSemantics = false,
    super.child,
  });

  /// Computes the fraction to scale the child's alpha value.
  ///
  /// An opacity of one is fully opaque. An opacity of zero is fully transparent
  /// (i.e., invisible).
  ///
  /// Values one and zero are painted with a fast path. Other values require
  /// painting the child into an intermediate buffer, which is expensive.
  final SignalComputer<double> opacity;

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

class _OpacityElement extends SingleChildSignalElement<RenderOpacity> {
  _OpacityElement(super.widget);

  @override
  void recompute() {
    renderer.opacity = (widget as SignalOpacity).opacity(this);
  }
}