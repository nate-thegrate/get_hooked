part of '../hooks.dart';

/// Caches the instance of a complex object.
///
/// During the first build, [useMemoized] will call [valueGetter] and return its result.
/// Later, when the [HookWidget] rebuilds, the call to [useMemoized] will return the
/// previously created instance.
///
/// A subsequent [useMemoized] call with a different [key] will re-invoke the function
/// to create a new instance.
T useMemoized<T>(ValueGetter<T> valueGetter, {Object? key}) {
  return use(_MemoizedHook<T>.new, key: key, data: valueGetter, debugLabel: 'useMemoized<$T>');
}

class _MemoizedHook<T> extends Hook<T, Function> {
  late T result = data();

  @override
  T build() => result;
}
