import 'package:flutter/foundation.dart';

/// Selects a value from an existing [ValueListenable] and notifies when that value changes.
class ProxyNotifier<Result, Input> with ChangeNotifier implements ValueListenable<Result> {
  /// Transforms any [Listenable] into a [ValueListenable].
  ProxyNotifier(this.input, this.getValue);

  /// The input [Listenable] object.
  final ValueListenable<Input> input;

  /// Retrieves a [value] using the provided [input].
  final Result Function(Input value) getValue;

  @override
  Result get value => hasListeners ? _value : _value = getValue(input.value);
  late Result _value = getValue(input.value);

  void _listener() {
    final Result newValue = getValue(input.value);
    if (newValue == _value) return;

    _value = newValue;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      input.addListener(_listener);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      input.removeListener(_listener);
    }
  }

  /// Returns a copy of this notifier that uses a different [input] object
  /// of the same type.
  ProxyNotifier<Result, Input> proxyWith(ValueListenable<Input> newInput) {
    return ProxyNotifier(newInput, getValue);
  }

  @override
  void dispose() {
    input.removeListener(_listener);
    super.dispose();
  }
}
