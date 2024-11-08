import 'package:flutter/foundation.dart';

class ProxyNotifier<T, L extends Listenable> with ChangeNotifier implements ValueListenable<T> {
  ProxyNotifier(this.getValue, {required this.listenable}) {
    _value = value;
  }

  final T Function(L) getValue;

  final L listenable;

  @override
  T get value => getValue(listenable);
  late T _value;
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
