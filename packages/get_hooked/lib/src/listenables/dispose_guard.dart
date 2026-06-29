/// @docImport 'package:flutter/scheduler.dart';
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
  /// [RefWidget] is no longer in use, so the `dispose()` method of a
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

/// Ensures that the notifier only sends updates between frames.
///
/// Throws an error whenever [notifyListeners] is called during
/// [SchedulerPhase.persistentCallbacks].\
/// (In most cases, an error would have been thrown anyway
/// due to [Element.markNeedsBuild] being called during a build.)
mixin StrictNotifier on ChangeNotifier {
  @protected
  @override
  void notifyListeners() {
    if (kDebugMode && WidgetsBinding.instance.schedulerPhase == .persistentCallbacks) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'A $runtimeType tried sending a notification while the widget tree was being built and rendered.',
        ),
        ErrorDescription(
          "Notifiers shouldn't perform updates during a frame, "
          'since in the best case one change results in multiple rebuilds, '
          'and in the worst case it can trigger an infinite loop.',
        ),
        ErrorHint(
          'This error could be bypassed by wrapping the update in a post-frame callback, '
          "but the recommended solution is to rework this notifier's logic "
          'so that updates are sent before a rebuild starts.',
        ),
      ]);
    }
    super.notifyListeners();
  }
}
