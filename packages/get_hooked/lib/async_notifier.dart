import 'package:flutter/widgets.dart';

typedef StreamCallback<T> = Stream<T> Function();

class AsyncNotifier<T> with ChangeNotifier implements ValueNotifier<AsyncSnapshot<T>> {
  AsyncNotifier(this._value, {this.autoDispose});

  AsyncNotifier.initialData(T? data, {this.autoDispose})
      : _value = switch (data) {
          null => const AsyncSnapshot.nothing(),
          _ => AsyncSnapshot.withData(ConnectionState.none, data),
        };

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

  final VoidCallback? autoDispose;
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);

    if (!hasListeners) autoDispose?.call();
  }
}
