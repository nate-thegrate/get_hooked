import 'package:flutter/foundation.dart' show ValueListenable;

import 'animations/vsync.dart';

/// The parameter used in a [RefComputer] callback.
abstract interface class ComputeRef {
  /// Returns the [ValueListenable.value], and triggers a re-computation when notifications
  /// are sent.
  ///
  /// A compute callback ideally should only watch an object once.
  /// Any additional `watch()` calls must use the same arguments for `autoVsync` and
  /// `useScope` as the first call (or, you know, just read the variable from earlier).
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true});

  /// Returns the [selector]'s result and triggers a re-compute when that result changes.
  ///
  /// A compute callback can have at most one selector per listenable object, for example:
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
  ///
  /// ## Performance consideration
  ///
  /// Since a `select()` call has its own overhead, it's most useful when the compute callback
  /// is already doing a lot of work.
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  });
}

/// Soon I will turn [Ref] into a global constant that implements this interface, cause why not.
abstract interface class HookRef implements ComputeRef {
  /// TBD :)
  Result compute<Result>(RefComputer<Result> callback);
}

/// Signature for a callback that computes a result using a provided [ComputeRef].
typedef RefComputer<Result> = Result Function(ComputeRef ref);

/// A very fancy [BuildContext] that also implements the following interfaces:
///
/// - [ComputeRef]
/// - [Vsync]
/// - [TickerProvider] (supertype of [Vsync])
abstract class ComputeContext implements VsyncContext, ComputeRef {}
