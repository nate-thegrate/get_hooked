part of '../get.dart';

/// Might as well use a fun little class for the scope errors!
class ScopedGetError extends UnsupportedError {
  /// Might as well use a fun little class for the scope errors!
  ScopedGetError(super.message);
}

/// Creates pseudo-listenable objects that throw when properties are accessed.
///
/// `ScopedGet` can be used to define a top-level [Get] object, ensuring that only a
/// different "scoped" version is accessed.
///
/// Since these static methods are called without arguments, the type arguments
/// should be added explicitly.
///
/// ```dart
/// // BAD
/// final x = ScopedGet.async();
///
/// // GOOD
/// final x = ScopedGet.async<String>();
/// ```
class ScopedGet<T> implements ValueListenable<T> {
  /// [ScopedGet] "implements" any interface by throwing an error
  /// any time an attempt is made to access an instance member.
  @override
  Never noSuchMethod(Invocation invocation) {
    throw ScopedGetError('Attempted to access ${invocation.memberName} on $this');
  }

  @override
  String toString() => describeIdentity(this);

  /// Placeholder for a [ValueNotifier].
  @factory
  static GetValue<T> it<T>() => GetValue._(_ScopeValue());

  /// Placeholder for a [ListNotifier].
  @factory
  static GetList<E> list<E>() => GetList._(_ScopeList());

  /// Placeholder for a [SetNotifier].
  @factory
  static GetSet<E> set<E>() => GetSet._(_ScopeSet());

  /// Placeholder for a [MapNotifier].
  @factory
  static GetMap<K, V> map<K, V>() => GetMap._(_ScopeMap());

  /// Placeholder for an [AnimationController].
  @factory
  static GetVsyncDouble vsync() => GetVsyncDouble._(_ScopeVsync());

  /// Placeholder for a [ValueAnimation].
  @factory
  static GetVsyncValue<T> vsyncValue<T>() => GetVsyncValue._(_ScopeValue());

  /// Placeholder for an [AsyncNotifier].
  @factory
  static GetAsync<T> async<T>() => GetAsync._(_ScopeAsync());

  /// Placeholder for an [AsyncNotifier].
  static GetAsync<T> stream<T>() => async();

  /// Placeholder for a [ComputedNotifier].
  @factory
  static GetComputed<Result> compute<Result>() => GetComputed._(_ScopeValue());
}

class _ScopeValue<T> extends ScopedGet<T>
    implements ValueNotifier<T>, ValueAnimation<T>, ComputedNotifier<T> {}

class _ScopeList<E> extends ScopedGet<List<E>> implements ListNotifier<E> {}

class _ScopeSet<E> extends ScopedGet<Set<E>> implements SetNotifier<E> {}

class _ScopeMap<K, V> extends ScopedGet<Map<K, V>> implements MapNotifier<K, V> {}

class _ScopeVsync extends ScopedGet<double> implements VsyncDouble {}

class _ScopeAsync<T> extends ScopedGet<AsyncValue<T>> implements AsyncNotifier<T> {}
