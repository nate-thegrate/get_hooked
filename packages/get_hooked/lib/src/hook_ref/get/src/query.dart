part of '../get.dart';

/// Encapsulates a [MediaQueryNotifier].
extension type GetQuery<T>._(MediaQueryNotifier<T> _hooked)
    implements Get<T, MediaQueryNotifier<T>> {
  /// {@macro get_hooked.MediaQueryNotifier.assignView}
  void assignView(FlutterView view) => _hooked.assignView(view);

  /// Encapsulates a [ValueListenable] that stores the current screen [Size].
  ///
  /// [GetQuery.width] and [GetQuery.height] can be used for the individual values.
  static GetViewData<Size> size = GetViewData._(_Observer.size);

  /// A [ValueListenable] that houses the current [Size.width] of the screen.
  static final width = GetViewData<double>._(Get.select(GetQuery.size, (size) => size.width));

  /// A [ValueListenable] that houses the current [Size.height] of the screen.
  static final height = GetViewData<double>._(Get.select(GetQuery.size, (size) => size.height));

  /// Encapsulates a [ValueListenable] that stores the current platform [Brightness].
  static final brightness = GetBrightness._(_Observer.brightness);
}

class _Observer with WidgetsBindingObserver {
  _Observer() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final instance = _Observer();

  /// Making this an instance field and referencing it in `_WidgetsBindingNotifier()`
  /// ensures that the observer is initialized when any of the relevant notifiers are accessed.
  MediaQueryData get query {
    final Iterable<FlutterView> views = WidgetsBinding.instance.platformDispatcher.views;
    return MediaQueryData.fromView(views.first);
  }

  static final size = _WidgetsBindingNotifier((data) => data.size);
  static final brightness = _WidgetsBindingNotifier((data) => data.platformBrightness);

  @override
  void didChangeMetrics() {
    final MediaQueryData newData = query;
    size.value = newData.size;
    brightness.value = newData.platformBrightness;
  }
}

class _WidgetsBindingNotifier<T> extends ValueNotifier<T> {
  _WidgetsBindingNotifier(T Function(MediaQueryData data) selector)
    : super(selector(_Observer.instance.query));
}

/// A variation of the [Get] API that double-checks the [FlutterView] count
/// when retrieving the [value].
extension type GetViewData<T>._(ValueListenable<T> _hooked) implements Get<T, ValueListenable<T>> {
  @redeclare
  T get value {
    if (kDebugMode &&
        debugCheckViewCount &&
        WidgetsBinding.instance.platformDispatcher.views.length > 1) {
      throw FlutterError.fromParts([
        ErrorSummary('Multiple FlutterViews were found within the platform dispatcher.'),
        ErrorDescription(
          'This listenable assumes a single view, '
          'since, for instance, a multi-window app does not have a single screen size.',
        ),
        ErrorHint(
          'Consider accessing this value via context.read(), '
          'or calling MediaQuery.of(context) instead.',
        ),
        ErrorHint(
          'This check can be bypassed by setting GetViewData.debugCheckViewCount as false.',
        ),
      ]);
    }
    return _hooked.value;
  }

  /// Whether APIs that assume a single window should throw an error when multiple [FlutterView]s
  /// are found.
  ///
  /// This value is referenced in [GetQuery.size] and [GetQuery.brightness].
  static bool debugCheckViewCount = true;
}

/// An interface for obtaining the current platform [Brightness].
///
/// Includes an [isDark] field
extension type GetBrightness._(ValueNotifier<Brightness> _hooked)
    implements Get<Brightness, ValueListenable<Brightness>> {
  static final _isDark = Get.select(GetQuery.brightness, (value) => value == Brightness.dark);

  /// A [ValueListenable] that converts the [Brightness] to a boolean value for convenience.
  GetSelection<bool, Brightness> get isDark => _isDark;
}
