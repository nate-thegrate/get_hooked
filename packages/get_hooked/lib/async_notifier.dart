import 'package:flutter/widgets.dart';

/// A [Function] that returns a [Stream].
///
/// Can be set up using `async*`.
typedef StreamCallback<T> = Stream<T> Function();

/// A variation of [ValueNotifier], set up for [AsyncSnapshot] data.
///
/// The [connectionState] can be set directly without triggering a notification.
class AsyncNotifier<T> with ChangeNotifier implements ValueNotifier<AsyncSnapshot<T>> {
  /// Creates a [ChangeNotifier] that broadcasts [AsyncSnapshot]s.
  AsyncNotifier(this._value, {this.autoDispose});

  /// Creates an async notifier based on initial [data].
  AsyncNotifier.initialData(T? data, {this.autoDispose})
    : _value = switch (data) {
        null => const AsyncSnapshot.nothing(),
        _ => AsyncSnapshot.withData(ConnectionState.none, data),
      };

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

  /// A function called whenever the notifier has removed its last listener.
  final VoidCallback? autoDispose;
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);

    if (!hasListeners) autoDispose?.call();
  }
}
