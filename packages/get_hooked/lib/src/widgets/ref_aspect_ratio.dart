import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';

/// A variant of [AspectRatio] that evaluates based on a [RefComputer<Matrix4>].
class RefAspectRatio extends SingleChildRenderObjectWidget {
  /// Initializes fields for subclasses.
  const RefAspectRatio(this.ratio, {super.key, super.child});

  /// Returns the aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final RefComputer<double> ratio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) => RenderAspectRatio(aspectRatio: 1);

  @override
  SingleChildRenderObjectElement createElement() => _DecorationElement(this);
}

class _DecorationElement extends SingleChildComputeElement<RenderAspectRatio> {
  _DecorationElement(super.widget);

  @override
  void recompute() {
    renderer.aspectRatio = (widget as RefAspectRatio).ratio(this);
  }
}
