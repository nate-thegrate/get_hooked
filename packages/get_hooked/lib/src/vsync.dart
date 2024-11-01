part of '../get_hooked.dart';

@visibleForTesting
final tickers = <VsyncTicker>{};

class Vsync implements TickerProvider {
  Vsync([this._context]);

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

  static Duration defaultDuration = Durations.medium1;
  static Curve defaultCurve = Curves.linear;

  static bool get muted => _muted;
  static bool _muted = false;
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
      if (ticker.vsync.context case final context?) {
        if (!context.mounted) {
          return ticker.stop(canceled: true);
        }
        ticker.updateNotifier(context);
        if (ticker.muted) return;
      }
      onTick(elapsed);
    }

    return ticker = VsyncTicker(tickerCallback, this);
  }
}

@visibleForTesting
class VsyncTicker extends Ticker {
  // ignore: matching_super_parameters, super-class param is poorly named
  VsyncTicker(super.onTick, this.vsync) {
    tickers.add(this);
    if (vsync.context case final context? when context.mounted) {
      updateNotifier(context);
    }
  }

  final Vsync vsync;
  ValueListenable<bool> enabledNotifier = const _UnsetNotifier();

  void updateNotifier(BuildContext context) {
    final ValueListenable<bool> newNotifier = TickerMode.getNotifier(context);
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
