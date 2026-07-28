import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// A variant of [Padding] that evaluates based on a [SignalComputer<EdgeInsetsGeometry>].
class SignalPadding extends SingleChildRenderObjectWidget {
  /// Creates a [Padding] widget using the provided [SignalComputer] callback.
  const SignalPadding(this.padding, {super.key, required Widget super.child});

  /// The amount of space by which to inset the child.
  final SignalComputer<EdgeInsetsGeometry> padding;

  @override
  RenderPadding createRenderObject(BuildContext context) => RenderPadding(padding: EdgeInsets.zero);

  @override
  SingleChildRenderObjectElement createElement() => _PaddingElement(this);
}

class _PaddingElement extends SingleChildSignalElement<RenderPadding> {
  _PaddingElement(super.widget);

  @override
  void recompute() {
    renderer.padding = (widget as SignalPadding).padding(this);
  }
}