import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// A variant of [AspectRatio] that evaluates based on a [SignalComputer<double>].
class SignalAspectRatio extends SingleChildRenderObjectWidget {
  /// Creates an [AspectRatio] widget using the provided [SignalComputer] callback.
  const SignalAspectRatio(this.ratio, {super.key, super.child});

  /// Returns the aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final SignalComputer<double> ratio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) => RenderAspectRatio(aspectRatio: 1);

  @override
  SingleChildRenderObjectElement createElement() => _AspectRatioElement(this);
}

class _AspectRatioElement extends SingleChildSignalElement<RenderAspectRatio> {
  _AspectRatioElement(super.widget);

  @override
  void recompute() {
    renderer.aspectRatio = (widget as SignalAspectRatio).ratio(this);
  }
}