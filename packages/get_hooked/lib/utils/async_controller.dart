import 'async_notifier.dart';

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
