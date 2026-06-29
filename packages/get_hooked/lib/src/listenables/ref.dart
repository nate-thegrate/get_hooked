/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart' show BuildContext;

import 'animations/vsync.dart';

/// Signature for a callback that computes a result using a provided [Ref].
typedef RefComputer<Result> = Result Function(Ref ref);

/// An object (usually an [Element]) that can subscribe to notifications
/// from [ValueListenable] objects.
abstract interface class Ref {
  /// Returns the [ValueListenable.value], and triggers a re-computation when notifications
  /// are sent.
  ///
  /// A [RefComputer] should only watch an object once. Additional `watch()` calls
  /// must use the same arguments for `autoVsync` and `useScope`
  /// as the first call (but it's probably best just to reuse the variable from earlier).
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true});

  /// Returns the [selector]'s result and triggers a re-compute when that result changes.
  ///
  /// A [RefComputer] can have at most one selector per listenable object, for example:
  /// ```dart
  /// // BAD
  /// (ComputeRef ref) {
  ///   final isNegative = ref.select(number, (value) => value.isNegative);
  ///   final isEven = ref.select(number, (value) => value.isEven);
  /// }
  ///
  /// // GOOD
  /// (ComputeRef ref) {
  ///   final (isNegative, isEven) = ref.select(number, (value) {
  ///     return (value.isNegative, value.isEven);
  ///   });
  /// }
  /// ```
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  });
}

/// A fancy [BuildContext] that also implements the following interfaces:
///
/// - [Ref]
/// - [Vsync]
/// - [TickerProvider] (supertype of [Vsync])
abstract class RefContext implements Ref, Vsync, BuildContext {
  /// The context that is currently performing a build or update.
  ///
  /// See also: [ref], which points to this value.
  static RefContext? current;
}
