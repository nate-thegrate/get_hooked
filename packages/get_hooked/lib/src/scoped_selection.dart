// ignore: invalid_internal_annotation, my preference :)
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/hook_ref/hook_ref.dart';
import 'package:get_hooked/src/substitution/substitution.dart';
import 'package:meta/meta.dart';

@internal
/// Listens to the scoped version of [root], calling [listener] when the selected value changes.
class ScopedSelection<Result, T> {
  ScopedSelection(this.context, this.root, this.selector, this.listener)
    : scoped = GetScope.of(context, root) {
    scoped.addListener(_scopedListener);
    value = selector(scoped.value);
  }

  final BuildContext context;
  final ValueListenable<T> root;
  ValueListenable<T> scoped;

  final Result Function(T) selector;
  late Result value;
  final VoidCallback listener;

  void _scopedListener() {
    final Result newValue = selector(scoped.value);
    if (newValue == value) return;

    value = newValue;
    listener();
  }

  void rescope() {
    final ValueListenable<T> newScoped = SubScope.of(context, root);
    if (newScoped == scoped) return;

    scoped.removeListener(_scopedListener);
    scoped = newScoped..addListener(_scopedListener);
    _scopedListener();
  }

  void dispose() {
    scoped.removeListener(_scopedListener);
  }
}
