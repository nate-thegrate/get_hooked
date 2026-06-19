import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/substitution/substitution.dart';
import 'package:meta/meta.dart';

@internal
abstract interface class Selection {
  factory Selection.merge(Iterable<Selection> selections) = Selections;

  @factory
  static Selection single<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector,
    VoidCallback listener,
  ) {
    return SingleSelection(listenable, selector, listener);
  }

  void activate();
  void deactivate();
}

@internal
class SingleSelection<Result, T> implements Selection {
  SingleSelection(ValueListenable<T> listenable, this.selector, this.listener)
    : _listenable = listenable,
      value = selector(listenable.value);

  ValueListenable<T> _listenable;
  final Result Function(T value) selector;
  final VoidCallback listener;

  Result value;
  void _reselect() {
    final Result newValue = selector(_listenable.value);
    if (newValue == value) return;

    value = newValue;
    listener();
  }

  @override
  void activate() {
    _listenable.addListener(_reselect);
  }

  @override
  void deactivate() {
    _listenable.removeListener(_reselect);
  }
}

@internal
class Selections implements Selection {
  Selections(this.selections);

  final Iterable<Selection> selections;

  @override
  void activate() {
    for (final Selection selection in selections) {
      selection.activate();
    }
  }

  @override
  void deactivate() {
    for (final Selection selection in selections) {
      selection.deactivate();
    }
  }
}

class _ScopedNotifier<T> implements ValueListenable<T> {
  _ScopedNotifier(this.scoped);

  final (Listenable, T) scoped;

  @override
  T get value => scoped.$2;

  @override
  void addListener(VoidCallback listener) => scoped.$1.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => scoped.$1.removeListener(listener);
}

@internal
/// Listens to the scoped version of [root], calling [listener] when the selected value changes.
class ScopedSelection<Result, T> extends SingleSelection<Result, T> {
  ScopedSelection(this.context, this.root, Result Function(T) selector, VoidCallback listener)
    : super(_ScopedNotifier(context.read(root)), selector, listener);

  final BuildContext context;
  final ValueListenable<T> root;

  void rescope() {
    final newScoped = context.read(root);
    if ((_listenable as _ScopedNotifier).scoped.$1 == newScoped.$1) return;

    _listenable.removeListener(_reselect);
    _listenable = _ScopedNotifier(newScoped)..addListener(_reselect);
    _reselect();
  }
}
