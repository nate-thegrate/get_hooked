import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import 'ref_constraints.dart';

/// A variant of [SizedBox] that evaluates based on a [RefComputer<Sized>].
///
/// (See also: [BoxSize])
class RefSizedBox extends RefConstraints {
  /// There's no reason to use this constructor over [RefConstraints.new],
  /// aside from how restricting the [constrain] callback's return type
  /// could tweak autofill suggestions to slightly improve development speed :)
  const RefSizedBox(RefComputer<BoxSize> super.constrain, {super.key, super.child});
}

/// Stores the configuration for a [SizedBox] without specifying a `child`.
///
/// This class extends [BoxConstraints] rather than [Size] so that the width/height
/// parameters can be optional.
class BoxSize extends BoxConstraints {
  /// Specifies constraints in a manner similar to the default [SizedBox.new] constructor.
  const BoxSize({super.width, super.height}) : super.tightFor();

  /// Specifies constraints in a manner similar to [SizedBox.expand].
  const BoxSize.expand({
    double super.width = double.infinity,
    double super.height = double.infinity,
  }) : super.tightFor();

  /// Specifies constraints in a manner similar to [SizedBox.shrink].
  const BoxSize.shrink({double super.width = 0.0, double super.height = 0.0}) : super.tightFor();

  /// Specifies constraints in a manner similar to [SizedBox.square].
  const BoxSize.square([double? dimension]) : this(width: dimension, height: dimension);
}
