part of '../get_hooked.dart';

@visibleForTesting
final tickers = <Ticker>{};

class Vsync implements TickerProvider {
  Vsync([this.context]);

  BuildContext? context;

  static void detach(BuildContext context) {
    final detachedContext = context;

    for (final Ticker ticker in tickers) {
      if (ticker is _VsyncTicker && ticker.vsync.context == detachedContext) {
        ticker
          ..detach()
          ..vsync.context = null
          ..muted = true;
      }
    }
  }

  static Duration defaultDuration = Durations.medium1;
  static Curve defaultCurve = Curves.linear;

  static bool get muted => _muted;
  static bool _muted = false;
  static set muted(bool newValue) {
    if (newValue == _muted) return;

    _muted = newValue;

    for (final Ticker ticker in tickers) {
      if (ticker is! _VsyncTicker) {
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
          ErrorHint(
            'If using a GetItVsync, consider attaching an active BuildContext '
            'before creating a ticker.',
          ),
        ]);
      }
      return true;
    }());

    late final _VsyncTicker ticker;

    void tickerCallback(Duration elapsed) {
      if (context case final context?) {
        if (!context.mounted) {
          return ticker.stop(canceled: true);
        }
        ticker.updateNotifier(context);
        if (ticker.muted) return;
      }
      onTick(elapsed);
    }

    return ticker = _VsyncTicker(tickerCallback, this);
  }
}

class _VsyncTicker extends Ticker {
  _VsyncTicker(super.onTick, this.vsync) {
    tickers.add(this);
    if (vsync.context case final context? when context.mounted) {
      updateNotifier(context);
    }
  }

  final Vsync vsync;
  ValueListenable<bool> enabledNotifier = const _UnsetNotifier();

  void updateNotifier(BuildContext context) {
    final newNotifier = TickerMode.getNotifier(context);
    if (newNotifier != enabledNotifier) {
      detach();
      enabledNotifier = newNotifier..addListener(_listener);
      _listener();
    }
  }

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
            'If using a GetItVsync, consider attaching an active BuildContext '
            'before starting the ticker.',
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
  /// Supports [removeListener] but nothing else.
  const _UnsetNotifier();

  @override
  Never get value => throw StateError('Ticker notifier is not set');

  @override
  Never addListener(VoidCallback listener) => value;

  @override
  void removeListener(VoidCallback listener) {}
}
