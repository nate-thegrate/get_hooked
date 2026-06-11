import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A subclass of [OverlayPortalController] that sends a notification
/// when [show] and [hide] are called.
class OverlayNotifier extends OverlayPortalController
    with ChangeNotifier
    implements ValueListenable<bool> {
  /// Optionally initializes the superclass [debugLabel] field.
  OverlayNotifier({super.debugLabel}) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  bool get value => isShowing;

  @override
  void show() {
    final bool wasShowing = isShowing;
    super.show();
    if (isShowing != wasShowing) notifyListeners();
  }

  @override
  void hide() {
    final bool wasShowing = isShowing;
    super.hide();
    if (isShowing != wasShowing) notifyListeners();
  }
}
