import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

export 'dart:async';

export 'package:flutter/foundation.dart' show AsyncValueGetter;
export 'package:flutter/widgets.dart' show AsyncSnapshot, ConnectionState;

/// A [Function] that returns a [Stream].
///
/// Can be set up using `async*`.
typedef StreamCallback<T> = Stream<T> Function();

AsyncSnapshot<T> _initialSnapshot<T>(T? data) => switch (data) {
  null => const AsyncSnapshot.nothing(),
  _ => AsyncSnapshot.withData(ConnectionState.none, data),
};

/// A variation of [ValueNotifier], set up for [AsyncSnapshot] data.
///
/// The [connectionState] can be set directly without triggering a notification.
class AsyncNotifier<T> with ChangeNotifier implements ValueNotifier<AsyncSnapshot<T>> {
  /// Creates a [ChangeNotifier] that broadcasts [AsyncSnapshot]s.
  AsyncNotifier(this._value);

  /// Creates an async notifier based on initial [data].
  AsyncNotifier.initialData(T? data) : _value = _initialSnapshot(data);

  /// Current state of connection to the asynchronous computation.
  ConnectionState get connectionState => _value.connectionState;
  set connectionState(ConnectionState newValue) {
    _value = _value.inState(newValue);
  }

  @override
  AsyncSnapshot<T> get value => _value;
  AsyncSnapshot<T> _value;
  @override
  set value(AsyncSnapshot<T> snapshot) {
    if (snapshot != _value) {
      _value = snapshot;
      notifyListeners();
    }
  }
}

/// An [AsyncNotifier] that can process [Future] and [Stream] objects.
class AsyncController<T> extends AsyncNotifier<T> {
  /// Creates an [AsyncNotifier] that can process [Future] and [Stream] objects.
  AsyncController({
    this.futureCallback,
    this.streamCallback,
    this.initialData,
    this.cancelOnError = false,
    this.notifyOnCancel = false,
  }) : super.initialData(initialData);

  /// Can be invoked to update the [AsyncNotifier] based on a [Future].
  AsyncValueGetter<T>? futureCallback;

  /// Can be invoked to update the [AsyncNotifier] based on a [Stream].
  StreamCallback<T>? streamCallback;

  // ignore: public_member_api_docs, good luck lol
  T? initialData;

  /// Whether a [StreamSubscription] should end if it encounters an error.
  bool cancelOnError;

  /// Whether the [AsyncNotifier] should send a notification when
  /// the connection ends.
  bool notifyOnCancel;

  Future<T>? _future;
  // ignore: cancel_subscriptions, canceled in clear()
  StreamSubscription<T>? _subscription;

  /// Cancels the [StreamSubscription] and ignores the [Future] if applicable.
  void clear({bool? notify}) {
    bool canceled = false;
    if (_future case final future?) {
      future.ignore();
      _future = null;
      canceled = true;
    }
    if (_subscription case final subscription?) {
      subscription.cancel();
      _subscription = null;
      canceled = true;
    }
    if (canceled) {
      notify ?? notifyOnCancel
          ? value = value.inState(ConnectionState.none)
          : connectionState = ConnectionState.none;
    }
  }

  /// Invokes the stored [StreamCallback], or alternatively can accept a new
  /// [Stream] object.
  void setStream([Stream<T>? stream]) {
    clear();
    stream ??= streamCallback?.call();
    if (stream == null) return;

    _subscription = stream.listen(
      (T data) => value = AsyncSnapshot.withData(ConnectionState.active, data),
      onError: (Object error, StackTrace stackTrace) {
        value = AsyncSnapshot.withError(
          cancelOnError ? ConnectionState.done : ConnectionState.active,
          error,
          stackTrace,
        );
      },
      cancelOnError: cancelOnError,
      onDone: () {
        value = value.inState(ConnectionState.done);
      },
    );
  }

  /// Invokes the stored [futureCallback], or alternatively can accept a new
  /// [Future] object.
  void setFuture([Future<T>? future]) {
    clear();
    _future = future ??= futureCallback?.call();
    if (future == null) return;

    future.then<void>(
      (T data) {
        if (identical(_future, future)) {
          value = AsyncSnapshot<T>.withData(ConnectionState.done, data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_future, future)) {
          value = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
        }
      },
    );

    // An implementation like `SynchronousFuture` may have already called the
    // .then() closure. Do not overwrite it in that case.
    if (connectionState != ConnectionState.done) {
      connectionState = ConnectionState.waiting;
    }
  }
}
