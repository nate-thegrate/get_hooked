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

@internal
/// Listens to the scoped version of [root], calling [listener] when the selected value changes.
class ScopedSelection<Result, T> extends SingleSelection<Result, T> {
  ScopedSelection(this.context, this.root, Result Function(T) selector, VoidCallback listener)
    : super(context.read(root), selector, listener);

  final BuildContext context;
  final ValueListenable<T> root;

  void rescope() {
    final ValueListenable<T> newScoped = context.read(root);
    if (newScoped == _listenable) return;

    _listenable.removeListener(_reselect);
    _listenable = newScoped..addListener(_reselect);
    _reselect();
  }
}
