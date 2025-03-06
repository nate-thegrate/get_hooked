part of '../hook_functions.dart';

/// Invokes the [effect] callback, and calls it again whenever the [key] changes.
///
/// If the effect returns a function, that function will be called when the key
/// changes as well.
///
/// A non-`const` object without an [operator==] override can be constructed
/// as a new instance each time the widget builds and will cause the effect to
/// always trigger.
///
/// ```dart
/// // Prints 'hello' once.
/// useEffect(() {
///   print('hello');
///   return null;
/// });
///
/// // Prints 'hello' and 'goodbye' during each rebuild.
/// useEffect(
///   () {
///     print('hello');
///     return () => print('goodbye');
///   },
///   key: Object(),
/// );
/// ```
void useEffect(ValueGetter<VoidCallback?> effect, {Object? key}) {
  use(_EffectHook.new, data: effect, key: key, debugLabel: 'useEffect');
}

class _EffectHook extends Hook<void, ValueGetter<VoidCallback?>> {
  VoidCallback? onDispose;

  @override
  void initHook() => onDispose = data();

  @override
  void dispose() => onDispose?.call();

  @override
  void build() {}
}
