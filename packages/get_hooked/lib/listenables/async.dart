import 'dart:async';

import 'package:flutter/foundation.dart';

export 'dart:async';

export 'package:flutter/foundation.dart' show AsyncValueGetter;
export 'package:flutter/widgets.dart' show AsyncSnapshot, ConnectionState;

/// A data class that stores information about an asynchronous operation,
/// which could be a [Future] or [Stream].
///
/// This `sealed class` has 3 subtypes: [AsyncLoading], [AsyncData], and
/// [AsyncError].
@immutable
sealed class AsyncValue<T> {
  const factory AsyncValue.loading() = AsyncLoading<T>;

  const factory AsyncValue.data(T value, {bool done}) = AsyncData<T>;

  const factory AsyncValue.error(Object error, StackTrace stackTrace, {bool done}) =
      AsyncError<T>;

  factory AsyncValue._initial(T? data) {
    return data != null ? AsyncData(data) : const AsyncLoading();
  }

  /// Returns an [AsyncValue] based on the provided [future] callback.
  ///
  /// Returns an [AsyncError] if an error is encountered; if [test] returns `false`
  /// the error is rethrown.
  static Future<AsyncValue<T>> guard<T>(
    AsyncValueGetter<T> future, [
    bool Function(Object)? test,
  ]) async {
    try {
      return AsyncValue.data(await future());
    } catch (error, stackTrace) {
      if (test?.call(error) ?? true) {
        return AsyncValue.error(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// The value(s) returned by the associated [Future] or [Stream].
  T? get value;

  /// {@template get_hooked.AsyncValue.done}
  /// Whether the asynchronous operation is finised.
  ///
  /// For [Future]s, this is true when the future is completed.
  ///
  /// For [Stream]s, this is true when the stream is closed or when the subscription
  /// is canceled.
  /// {@endtemplate}
  bool get done;
}

/// An [AsyncValue] representing a [Future] that has yet to complete
/// or a [Stream] that has yet to yield any values.
final class AsyncLoading<T> implements AsyncValue<T> {
  /// Creates an [AsyncLoading] instance.
  const AsyncLoading();

  @override
  Null get value => null;

  @override
  bool get done => false;

  @override
  bool operator ==(Object other) => other is AsyncLoading;

  @override
  int get hashCode => (AsyncLoading).hashCode;
}

/// An [AsyncValue] representing an operation that has completed or yielded
/// a relevant result.
final class AsyncData<T> implements AsyncValue<T> {
  /// Creates an [AsyncValue] representing an operation that has completed
  /// or yielded a relevant result.
  const AsyncData(this.value, {this.done = true});

  @override
  final T value;

  @override
  final bool done;

  @override
  bool operator ==(Object other) {
    return other is AsyncData && other.value == value && other.done == done;
  }

  @override
  int get hashCode => Object.hash(value, done);
}

/// Signifies that an asynchronous operation has encountered an error.
class AsyncError<T> implements AsyncValue<T> {
  /// Creates an object that signifies an error encountered during an
  /// asynchronous operation.
  const AsyncError(this.error, this.stackTrace, {this.done = true});

  /// The object thrown during the operation.
  ///
  /// Typically this is an instance of [Exception] or [Error].
  final Object error;

  /// Contains information about the call sequence that triggered this error.
  final StackTrace stackTrace;

  @override
  Null get value => null;

  @override
  final bool done;
}

/// A [Function] that returns a [Stream].
///
/// Can be set up using `async*`.
typedef StreamCallback<T> = Stream<T> Function();

/// A [ValueNotifier] that can process [Future] and [Stream] objects.
class AsyncNotifier<T> with ChangeNotifier implements ValueListenable<T?> {
  /// Creates a [ValueNotifier] that can process [Future] and [Stream] objects.
  AsyncNotifier({
    this.futureCallback,
    this.streamCallback,
    this.initialData,
    this.cancelOnError = false,
    this.notifyOnCancel = false,
  }) : _asyncValue = AsyncValue._initial(initialData);

  /// Can be invoked to update this controller based on a [Future].
  AsyncValueGetter<T>? futureCallback;

  /// Can be invoked to update this controller based on a [Stream].
  StreamCallback<T>? streamCallback;

  // ignore: public_member_api_docs, good luck lol
  T? initialData;

  /// Whether a [StreamSubscription] should end if it encounters an error.
  bool cancelOnError;

  /// Whether the controller should send a notification when
  /// the connection ends.
  bool notifyOnCancel;

  Future<T>? _future;
  // ignore: cancel_subscriptions, canceled in clear()
  StreamSubscription<T>? _subscription;

  /// Cancels the [StreamSubscription] and ignores the [Future] if applicable.
  void clear({bool? notify}) {
    if (_future case final future?) {
      future.ignore();
      _future = null;
    }
    if (_subscription case final subscription?) {
      subscription.cancel();
      _subscription = null;
    }
  }

  /// Invokes the stored [StreamCallback], or alternatively can accept a new
  /// [Stream] object.
  void setStream([Stream<T>? stream]) {
    clear();
    stream ??= streamCallback?.call();
    if (stream == null) return;

    _subscription = stream.listen(
      (T data) => asyncValue = AsyncData(data, done: false),
      onError: (Object error, StackTrace stackTrace) {
        asyncValue = AsyncError(error, stackTrace, done: cancelOnError);
      },
      cancelOnError: cancelOnError,
      onDone: () {
        if (asyncValue case AsyncData(:final value?, done: false)) {
          asyncValue = AsyncData(value);
        }
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
          asyncValue = AsyncData<T>(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_future, future)) {
          asyncValue = AsyncError(error, stackTrace);
        }
      },
    );
  }

  /// An [AsyncValue] representing this controller's current state.
  AsyncValue<T> get asyncValue => _asyncValue;
  AsyncValue<T> _asyncValue;
  set asyncValue(AsyncValue<T> newValue) {
    if (newValue == _asyncValue) return;
    _asyncValue = newValue;
    notifyListeners();
  }

  /// The current [AsyncValue.value] of this operation.
  ///
  /// This value is of the type `T` if the current [asyncValue] is an
  /// [AsyncData] object and is `null` otherwise.
  @override
  T? get value => _asyncValue.value;

  /// {@macro get_hooked.AsyncValue.done}
  bool get done => _asyncValue.done;
}
