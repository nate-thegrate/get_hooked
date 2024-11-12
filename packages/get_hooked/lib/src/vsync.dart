part of '../get_hooked.dart';

/// Stores each [Ticker] managed by a [Vsync] instance.
@visibleForTesting
final tickers = <VsyncTicker>{};

/// A [TickerProvider] implementation that can arbitrarily
/// reconfigure its attached [BuildContext].
class Vsync implements TickerProvider {
  /// Creates a [TickerProvider] that can arbitrarily
  /// reconfigure its attached [BuildContext].
  Vsync([this._context]);

  /// The [BuildContext] associated with this `vsync`.
  ///
  /// Setting a context isn't necessary if the vsync is being managed
  /// by [Ref.vsync].
  BuildContext? get context => _context;
  BuildContext? _context;
  set context(BuildContext? newContext) {
    if (newContext == _context) return;

    if (newContext != null) {
      for (final VsyncTicker ticker in tickers) {
        final Vsync vsync = ticker.vsync;
        if (vsync._context == _context) {
          vsync._context = newContext;
        } else if (vsync._context != newContext) {
          continue;
        }
        ticker.updateNotifier(newContext);
      }
    } else {
      for (final VsyncTicker ticker in tickers) {
        if (ticker.vsync._context == _context) {
          ticker
            ..stop(canceled: true)
            ..detach()
            ..vsync.context = null
            ..muted = _muted;
        }
      }
    }

    _context = newContext;
  }

  /// The default [Duration] to apply to `vsync` animations, e.g.
  /// those created via [Get.vsync].
  static Duration defaultDuration = Durations.medium1;

  /// The default [Curve] to apply to `vsync` animations, e.g.
  /// those created via [Get.vsync].
  static Curve defaultCurve = Curves.linear;

  /// Whether tickers without an attached [context] should be muted.
  static bool get muted => _muted;
  static bool _muted = false;

  /// Controls the [Ticker.muted] value for each ticker without a [context].
  static set muted(bool newValue) {
    if (newValue == _muted) return;

    _muted = newValue;

    for (final Ticker ticker in tickers) {
      if (ticker is! VsyncTicker) {
        ticker.muted = newValue;
      }
    }
  }

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
        case hooked || null:
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
    tickers.add(this);
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
      detach();
      enabledNotifier = newNotifier..addListener(_listener);
      _listener();
    }
  }

  /// Unsubscribes from the [enabledNotifier].
  void detach() {
    enabledNotifier.removeListener(_listener);
  }

  void _listener() {
    muted = !enabledNotifier.value;
  }

  @override
  TickerFuture start() {
    assert(() {
      if (vsync.context case BuildContext(mounted: false)) {
        throw FlutterError.fromParts([
          ErrorSummary('Ticker.start() called after dispose().'),
          ErrorHint(
            'Consider setting an active context for its vsync before starting the ticker.',
          ),
        ]);
      }
      return true;
    }());
    return super.start();
  }

  @override
  void dispose() {
    enabledNotifier.removeListener(_listener);
    tickers.remove(this);
    super.dispose();
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

/// A placeholder value, signifying that a [VsyncTicker] is being managed by [Ref.vsync].
@visibleForTesting
const BuildContext hooked = _Hooked();

class _Hooked implements BuildContext {
  const _Hooked();

  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError('"Hooked" acts as a placeholder value for a Vsync BuildContext.');
  }
}
