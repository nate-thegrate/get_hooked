/// @docImport 'proxy_notifier.dart';
library;

import 'package:flutter/scheduler.dart';

/// {@template get_hooked.SchedulerBuilding}
/// Provides an estimate regarding whether a build is imminent.
///
/// This allows classes such as [ProxyNotifier] to decide whether to
/// fire immediately or use [Future.microtask] to mitigate duplicate notifications.
/// {@endtemplate}
extension SchedulerBuilding on SchedulerBinding {
  /// {@macro get_hooked.SchedulerBuilding}
  bool get building => switch (schedulerPhase) {
    SchedulerPhase.midFrameMicrotasks || SchedulerPhase.persistentCallbacks => true,
    SchedulerPhase.postFrameCallbacks ||
    SchedulerPhase.transientCallbacks ||
    SchedulerPhase.idle =>
      false,
  };
}
