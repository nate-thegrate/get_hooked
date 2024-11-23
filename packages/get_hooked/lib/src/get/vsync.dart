part of '../get.dart';

/// Creates an [Animation] using a [TickerProvider].
typedef VsyncBuilder<A extends Animation<Object?>> = A Function(TickerProvider vsync);

/// A [TickerProvider] implementation that can arbitrarily
/// reconfigure its attached [BuildContext].
///
/// `Vsync` has 3 modes:
///
/// 1. No context: its [ticker] will always be unmuted.
/// 2. Any context: attaching to an arbitrary [BuildContext] will
///    subscribe this Vsync to its ancestor [TickerMode] notifier,
///    and verify that it has the correct notifier each animation frame.
/// 3. [Vsync.auto]: The ticker is automatically managed by [Ref.vsync], which
///    functions similarly to [useSingleTickerProvider].
///
/// ### Reliability Consideration
///
/// The "any context" mode is nearly always guaranteed to accurately manage
/// the ticker's muted status, except in rare cases where the ticker is muted
/// and then a change to the widget tree (e.g. a [GlobalKey] causing the
/// [BuildContext] to be transported to another location) results in the [context]
/// inheriting from a different [TickerMode].
///
/// Should this edge case arise, the ticker could be updated by calling
/// [VsyncTicker.updateNotifier] inside [State.activate] or [StatelessWidget.build],
/// or by using [Ref.vsync] instead.
class Vsync implements TickerProvider {
  /// Creates a [TickerProvider] that can arbitrarily
  /// reconfigure its attached [BuildContext].
  Vsync([BuildContext? context]) : _context = context;

  /// A placeholder value, signifying that a [VsyncTicker]
  /// is being managed by the [Ref.vsync] hook.
  static const BuildContext auto = _AutoManaged();

  /// Optionally allows an object to keep track of its [Vsync].
  ///
  /// [Animation]s created via [Vsync.build] are automatically registered.
  @visibleForTesting
  static final cache = Expando<Vsync>();

  /// Creates an animation using the provided [VsyncBuilder],
  /// and registers it to the [Vsync.cache].
  static A build<A extends Animation<Object?>>(VsyncBuilder<A> builder) {
    final vsync = Vsync();
    final A animation = builder(vsync);
    Vsync.cache[animation] = vsync;
    return animation;
  }

  /// Whether a [VsyncTicker] is currently assigned.
  bool get hasTicker => _ticker != null;

  /// The [VsyncTicker] being managed by this ticker provider.
  VsyncTicker? get ticker => _ticker;
  VsyncTicker? _ticker;
  set ticker(VsyncTicker? newTicker) {
    if (newTicker == _ticker) return;
    _ticker?.dispose();
    _ticker = newTicker;
  }

  /// The [BuildContext] associated with this `vsync`.
  ///
  /// Setting a context isn't necessary if the vsync is being managed
  /// by [Ref.vsync].
  BuildContext? get context => _context;
  BuildContext? _context;
  set context(BuildContext? newContext) {
    switch (newContext) {
      case Vsync.auto:
        break;
      case null:
        _ticker?.detach();
      default:
        _ticker?.updateNotifier(newContext);
    }

    _context = newContext;
  }

  /// The default [Duration] to apply to `vsync` animations, e.g.
  /// those created via [Get.vsync].
  static Duration defaultDuration = Durations.medium1;

  /// The default [Curve] to apply to `vsync` animations, e.g.
  /// those created via [Get.vsync].
  static Curve defaultCurve = Curves.linear;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (context case BuildContext(mounted: false)) {
        throw FlutterError.fromParts([
          ErrorSummary('Vsync.createTicker() called after dispose().'),
          ErrorHint('Consider attaching an active BuildContext before creating a ticker.'),
        ]);
      }
      return true;
    }());

    late final VsyncTicker ticker;

    void tickerCallback(Duration elapsed) {
      switch (ticker.vsync.context) {
        case auto || null:
          break;

        case BuildContext(mounted: false):
          return ticker.stop(canceled: true);

        case final BuildContext context:
          ticker.updateNotifier(context);
          if (ticker.muted) return;
      }

      onTick(elapsed);
    }

    return ticker = VsyncTicker(tickerCallback, this);
  }
}

/// A [Ticker] created by a [Vsync].
@visibleForTesting
class VsyncTicker extends Ticker {
  /// Creates a [VsyncTicker].
  VsyncTicker(super.onTick, this.vsync) {
    vsync._ticker = this;
    if (vsync.context case final context? when context.mounted) {
      updateNotifier(context);
    }
  }

  /// The [Vsync] associated with this ticker.
  final Vsync vsync;

  /// A [ValueListenable] that notifies when the [muted] status should change.
  ValueListenable<bool> enabledNotifier = const _UnsetNotifier();

  /// Updates the [enabledNotifier] if its identity changes
  /// (may happen if an ancestor [TickerMode] is added to/removed from the tree.)
  void updateNotifier(BuildContext context) {
    final ValueListenable<bool> newNotifier = TickerMode.getNotifier(context);
    if (newNotifier != enabledNotifier) {
      enabledNotifier.removeListener(_listener);
      enabledNotifier = newNotifier..addListener(_listener);
      _listener();
    }
  }

  /// Sets the ticker as "no longer managed by a [BuildContext]".
  void detach() {
    muted = false;
    stop(canceled: true);
    enabledNotifier.removeListener(_listener);
  }

  void _listener() {
    muted = !enabledNotifier.value;
  }

  @override
  TickerFuture start() {
    assert(() {
      if (vsync.context case null || Vsync.auto || BuildContext(mounted: true)) {
        return true;
      }

      throw FlutterError.fromParts([
        ErrorSummary('Ticker.start() called after dispose().'),
        ErrorHint('Consider setting an active context for its vsync before starting the ticker.'),
      ]);
    }());
    return super.start();
  }

  @override
  void dispose() {
    enabledNotifier.removeListener(_listener);
    super.dispose();
    vsync._ticker = null;
  }
}

class _UnsetNotifier implements ValueListenable<bool> {
  /// Throws unless it's [removeListener] being called.
  const _UnsetNotifier();

  @override
  Never get value => throw StateError('Ticker notifier is not set');

  @override
  Never addListener(VoidCallback listener) => value;

  @override
  void removeListener(VoidCallback listener) {}
}

class _AutoManaged implements BuildContext {
  const _AutoManaged();

  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError('"Hooked" acts as a placeholder value for a Vsync BuildContext.');
  }
}
