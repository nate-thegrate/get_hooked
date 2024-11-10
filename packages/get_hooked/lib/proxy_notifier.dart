import 'package:flutter/foundation.dart';

/// Transforms any [Listenable] into a [ValueListenable].
class ProxyNotifier<T, L extends Listenable> with ChangeNotifier implements ValueListenable<T> {
  /// Transforms any [Listenable] into a [ValueListenable].
  ProxyNotifier(this.listenable, this.getValue) : _value = getValue(listenable);

  /// Retrieves a [value] using the provided [listenable].
  final T Function(L) getValue;

  /// The input [Listenable] object.
  final L listenable;

  @override
  T get value => getValue(listenable);
  T _value;
  void _updateValue() {
    final T oldValue = _value;
    final T newValue = _value = value;

    if (newValue != oldValue) notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      listenable.addListener(_updateValue);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      listenable.removeListener(_updateValue);
    }
  }
}
