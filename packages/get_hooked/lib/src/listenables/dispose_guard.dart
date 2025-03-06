import 'package:flutter/foundation.dart';

/// Mixin for [Get] objects with a [dispose] method.
///
/// {@macro get_hooked.DisposeGuard}
mixin DisposeGuard on Listenable {
  @protected
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  @protected
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

  /// {@template get_hooked.DisposeGuard}
  /// [ref] will automatically free associated resources when its associated
  /// [HookWidget] is no longer in use, so the `dispose()` method of a
  /// [ValueNotifier] or [AnimationController] is unnecessary.
  ///
  /// The [DisposeGuard.dispose] method throws an error.
  /// {@endtemplate}
  @protected
  @visibleForOverriding
  void dispose() {
    assert(
      throw FlutterError.fromParts([
        ErrorSummary('$runtimeType.dispose() was invoked.'),
        ErrorDescription(
          'This $runtimeType uses the "dispose guard" mixin, which is meant for '
          "Listenable objects that persist throughout the app's lifecycle.",
        ),
        ErrorDescription(
          'Calling the `dispose()` method renders the object unable to function '
          'from that point onward.',
        ),
        ErrorHint('Consider removing the dispose() invocation.'),
      ]),
    );
  }
}
