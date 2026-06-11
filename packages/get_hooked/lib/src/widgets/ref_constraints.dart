import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

/// A variant of [ConstrainedBox] that evaluates based on a [RefComputer<BoxConstraints>].
class RefConstraints extends SingleChildRenderObjectWidget {
  /// Creates a [ConstrainedBox] widget using the provided [RefComputer] callback.
  const RefConstraints(this.constrain, {super.key, super.child});

  /// The transformation to apply to the [child] (and its descendants).
  final RefComputer<BoxConstraints> constrain;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: const BoxConstraints());
  }

  @override
  SingleChildRenderObjectElement createElement() => _ConstrainElement(this);
}

class _ConstrainElement extends SingleChildComputeElement<RenderConstrainedBox> {
  _ConstrainElement(super.widget);

  @override
  void recompute() {
    renderer.additionalConstraints = (widget as RefConstraints).constrain(this);
  }
}
