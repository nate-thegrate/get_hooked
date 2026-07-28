import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// A variant of [ConstrainedBox] that evaluates based on a [SignalComputer<BoxConstraints>].
class SignalConstraints extends SingleChildRenderObjectWidget {
  /// Creates a [ConstrainedBox] widget using the provided [SignalComputer] callback.
  const SignalConstraints(this.constrain, {super.key, super.child});

  /// Additional constraints to apply to the [child].
  final SignalComputer<BoxConstraints> constrain;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: const BoxConstraints());
  }

  @override
  SingleChildRenderObjectElement createElement() => _ConstrainElement(this);
}

class _ConstrainElement extends SingleChildSignalElement<RenderConstrainedBox> {
  _ConstrainElement(super.widget);

  @override
  void recompute() {
    renderer.additionalConstraints = (widget as SignalConstraints).constrain(this);
  }
}