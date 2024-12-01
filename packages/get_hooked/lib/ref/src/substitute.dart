part of '../ref.dart';

/// Creates a [Substitution] and automatically applies it to the nearest
/// ancestor [GetScope].
///
/// This can be called inside [HookWidget.build] to achieve the same result
/// as [GetScope.add].
///
/// The substitution is automatically removed when the widget's [BuildContext]
/// is unmounted.
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

/// Causes the static [Ref] methods to reference a different [Get] object.
///
///
/// {@tool snippet}
///
/// A substitution is made by wrapping a [Get] object in a [Ref] constructor
/// and calling a `Ref` instance method, such as [Ref.sub].
///
/// ```dart
/// GetScope(
///   substitutes: {Ref(getValue).sub(getOtherValue)},
///   child: widget.child,
/// );
/// ```
/// {@end-tool}
///
/// See also: [useSubstitute], to create a substitution via a [Hook] function.
abstract final class Substitution<V extends ValueRef> with Diagnosticable {
  Substitution(this.ref, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final V ref;

  /// A [ValueListenable] of the same type as the [ref] which will be referenced
  /// in its place by methods like [Ref.watch] called from descendant widgets.
  V get replacement;

  /// Whether to automatically call [ChangeNotifier.dispose] when the substitution
  /// is no longer part of an active [GetScope].
  ///
  /// Defaults to `true`, but this value is ignored if the notifier is identified
  /// as a [DisposeGuard] instance.
  final bool autoDispose;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<V>('ref', ref));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

/// A generic type that encompasses all [Substitution] objects.
typedef SubAny = Substitution<ValueRef>;

final class _SubEager<V extends ValueRef> extends Substitution<V> {
  _SubEager(super.ref, this.replacement, {super.autoDispose});

  @override
  final V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory<V extends ValueRef> extends Substitution<V> {
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

final class _SubGetFactory<V extends ValueRef> extends Substitution<V> {
  _SubGetFactory(super.ref, this.factory, {super.autoDispose});

  final GetGetter<V> factory;

  @override
  late final V replacement = factory().hooked;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}
