import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Signature for a [ValueGetter] that returns a [FlutterView].
typedef ViewFinder = FlutterView Function();

/// This notifier's purpose is similar to obtaining information from the ancestor [MediaQuery]
/// widget but allows interfacing with APIs that accept [ValueListenable] objects.
///
/// This notifier propagates notifications when the [PlatformDispatcher] handles an update
/// to the screen metrics, rather than waiting for the [MediaQuery] widget to be rebuilt.
class MediaQueryNotifier<T>
    with ChangeNotifier, WidgetsBindingObserver
    implements ValueListenable<T> {
  /// Subscribes to updates via [WidgetsBindingObserver.didChangeMetrics] and
  /// notifies its listeners when the [query] result changes.
  ///
  /// The `view` and `viewFinder` parameters allow configuring multiple notifiers
  /// (or mutating an existing one) for multi-window applications.
  MediaQueryNotifier(this.query, {FlutterView? view, ViewFinder? viewFinder})
    : _view = view,
      _viewFinder = viewFinder ?? _defaultViewFinder {
    WidgetsBinding.instance.addObserver(this);
    _value = _newValue;
  }
  static FlutterView _defaultViewFinder() {
    return WidgetsBinding.instance.platformDispatcher.views.first;
  }

  final ViewFinder _viewFinder;

  /// Obtains the relevant information by parsing a [MediaQueryData] object.
  final T Function(MediaQueryData data) query;

  @override
  T get value => _value;
  late T _value;
  T get _newValue => query(MediaQueryData.fromView(_view ?? _viewFinder()));
  void _checkValueChanged() {
    final T newValue = _newValue;
    if (newValue == _value) return;

    _value = newValue;
    notifyListeners();
  }

  @protected
  @override
  void didChangeMetrics() {
    _checkValueChanged();
  }

  @protected
  @override
  void didChangePlatformBrightness() {
    _checkValueChanged();
  }

  @protected
  @override
  void didChangeTextScaleFactor() {
    _checkValueChanged();
  }

  FlutterView? _view;

  /// {@template get_hooked.MediaQueryNotifier.assignView}
  /// This method allows the [FlutterView] to be updated manually
  /// (e.g. when [GlobalKey] reparenting causes an existing element to rebuild
  /// under a different view in a multi-window application).
  ///
  /// The [ViewFinder] callback will not be used after this method has been called
  /// at least once.
  /// {@endtemplate}
  void assignView(FlutterView view) {
    if (view == _view) return;

    _view = view;
    didChangeMetrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
