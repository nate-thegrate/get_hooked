part of '../ref.dart';

G useSubstitute<G extends GetAny>(G get, Object replacer, {Object? key}) {
  return use(_SubHook.new, data: (get, replacer), key: key, debugLabel: 'useSubstitute<$G>');
}

class _SubHook<G extends GetAny> extends Hook<G, (G, Object?)> {
  late final G newGet;

  @override
  void initHook() {
    var (G replaced, Object? replacer) = data;
    if (replacer is ValueGetter<Object?>) replacer = replacer();
    assert(() {
      if (replacer is G) return true;
      throw ArgumentError(
        'Invalid replacer passed to useSubstitute.\n'
        'The useSubstitute function expects the replacer '
        'to be an instance of $G (or an instance of the listenable it encapsulates). '
        'Instead, a ${data.runtimeType} was received.\n'
        'Consider double-checking the arguments passed to useSubstitute.',
      );
    }());
    newGet = replacer is G ? replacer : replaced;
    GetScope.add(context, getObjects: {replaced: newGet});
  }

  @override
  G build() => newGet;
}

abstract final class Substitute<V extends ValueRef> with Diagnosticable {
  Substitute(this.ref, {this.autoDispose = true});

  final V ref;

  V get replacement;

  final bool autoDispose;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<V>('ref', ref));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

typedef SubAny = Substitute<ValueRef>;

final class _SubEager<V extends ValueRef> extends Substitute<V> {
  _SubEager(super.ref, this.replacement, {super.autoDispose});

  @override
  final V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory<V extends ValueRef> extends Substitute<V> {
  _SubFactory(super.ref, this.factory, {super.autoDispose});

  final ValueGetter<V> factory;

  @override
  late final V replacement = factory();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}

final class _SubGetFactory<V extends ValueRef> extends Substitute<V> {
  _SubGetFactory(super.ref, this.factory, {super.autoDispose});

  final ValueGetter<Get<Object?, V>> factory;

  @override
  late final V replacement = factory().hooked;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}
