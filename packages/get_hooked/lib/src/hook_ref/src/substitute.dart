part of '../hook_ref.dart';

/// Creates a [Substitution] and automatically applies it to the nearest
/// ancestor [SubScope].
///
/// This can be called inside [HookWidget.build] to achieve the same result
/// as [SubScope.add].
///
/// The substitution is automatically removed when the widget's [BuildContext]
/// is unmounted.
G useSubstitute<G extends ValueListenable<Object?>>(G get, Object replacer, {Object? key}) {
  return use(_SubHook.new, data: (get, replacer), key: key, debugLabel: 'useSubstitute<$G>');
}

class _SubHook<G extends ValueListenable<Object?>> extends Hook<G, (G, Object?)> {
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
    SubScope.add(context, map: {replaced: newGet});
  }

  @override
  G build() => newGet;
}
