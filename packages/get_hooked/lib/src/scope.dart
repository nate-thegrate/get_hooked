/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/computed_notifier.dart';
import 'package:get_hooked/src/ref_element.dart';
import 'package:get_hooked/src/widgets/hook_widgets.dart';

typedef _V = ValueListenable<Object?>;

/// An immutable description of how one [ValueListenable] object can be used in place of another.
///
/// Most commonly used to create a [GetScope].
abstract final class Substitution with Diagnosticable {
  factory Substitution(
    ValueListenable<Object?> placeholder,
    ValueListenable<Object?> replacement, {
    bool autoDispose,
  }) = _SubReplacement;

  factory Substitution.factory(
    ValueListenable<Object?> placeholder,
    ValueGetter<ValueListenable<Object?>> factory, {
    bool autoDispose,
  }) = _SubFactory;

  /// Create a [Substitution] using a `value` of the matching type.\
  /// This redirects methods like [Ref.watch] to the provided value.
  factory Substitution.value(ValueListenable<Object?> placeholder, Object? value) = _SubValue;

  Substitution._(this.placeholder, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final ValueListenable<Object?> placeholder;

  /// A [ValueListenable] of the same type as the [placeholder] which will be referenced
  /// in its place by methods like [Ref.watch] called from descendant widgets.
  ValueListenable<Object?> get replacement;

  /// Whether to automatically call [ChangeNotifier.dispose] when the substitution
  /// is no longer part of an active [GetScope].
  ///
  /// Defaults to `true`, but this value is ignored if the notifier is identified
  /// as a [DisposeGuard] instance.
  final bool autoDispose;

  /// If a [Substitution] was made, returns the [GetScope] widget that made it.
  ///
  /// The result is always `null` in profile & release mode.
  static GetScope? debugSubWidget(BuildContext context, ValueListenable<Object?> placeholder) {
    return kDebugMode && GetScope.maybeOf(context, placeholder) != null
        ? context.findAncestorStateOfType<_GetScopeState>()?.widget
        : null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<_V>('placeholder', placeholder));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

final class _SubReplacement extends Substitution {
  _SubReplacement(super.placeholder, this.replacement, {super.autoDispose}) : super._();

  @override
  final _V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory extends Substitution {
  _SubFactory(super.placeholder, this.factory, {super.autoDispose}) : super._();

  final ValueGetter<_V> factory;

  @override
  _V get replacement => factory();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}

final class _SubValue with Diagnosticable implements Substitution {
  _SubValue(this.placeholder, this.value);

  @override
  final _V placeholder;

  final Object? value;

  @override
  late final _V replacement = _DummyListenable(value);

  @override
  bool get autoDispose => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

class _DummyListenable implements ValueListenable<Object?> {
  _DummyListenable(this.value);

  @override
  final Object? value;

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// A [Map] where each value is assumed to implement the same interface as the corresponding key.
extension type SubMap<T>._(Map<T, T> _map) implements Map<T, T> {
  /// Applies the [SubMap] interface to the provided [map].
  SubMap([Map<T, T>? map]) : _map = map ?? {};

  Error _notFound(Object? key) {
    if (_map.containsKey(key)) {
      return StateError('Unexpected map entry: (key: "$key", value: "${_map[key]}")');
    }
    return StateError('This map does not contain the key: $key');
  }

  /// Returns the [key]'s corresponding value.
  ///
  /// Throws an error if the map's value does not match the type argument's interface.
  G? maybeGet<G>(G key) => switch (_map[key]) {
    final G? g => g,
    _ => throw _notFound(key),
  };

  /// Returns the [key]'s corresponding value.
  ///
  /// Throws an error if the key is not present,
  /// or if map's value does not match the type argument's interface.
  G get<G>(G key) => switch (_map[key]) {
    final G g => g,
    _ => throw _notFound(key),
  };
}

/// Allows accessing the relevant value from an ancestor [GetScope] in a reasonably
/// concise manner.
extension GetScopeRead on BuildContext {
  /// Returns the [ValueListenable] object relevant to the provided `placeholder`.
  ///
  /// If no such object is found, the placeholder is returned.
  (ValueListenable<Object?>, T) read<T extends Object?>(
    ValueListenable<T> placeholder, {
    bool useScope = true,
    bool createDependency = false,
  }) {
    final scoped = useScope
        ? GetScope.of(this, placeholder, createDependency: createDependency)
        : placeholder;
    return (scoped, scoped.value as T);
  }
}

/// Allows [Substitution]s for [ValueListenable] objects.
///
/// [ref] methods will point to the objects specified in the substitutes
/// by default.
///
/// {@tool snippet}
///
/// In the following example, when the `child` widget (or its descendants)
/// calls `ref.watch(objectA)` or `ref.watch(objectB)`, it will be subscribed to
/// a different object, as defined by the [Substitution].
///
/// ```dart
/// Widget build(BuildContext context) {
///   // ...
///
///   return GetScope(
///     substitutes: {
///       Substitution(objectA, _objectA),
///       Substitution.factory(objectB, ValueNotifier<String>.new),
///     },
///     child: widget.child,
///   );
/// }
/// ```
///
/// {@end-tool}
class GetScope extends StatefulRefWidget {
  /// Enables [Ref.watch] calls to point to new values,
  /// as specified by the [substitutes].
  const GetScope({
    super.key,
    this.substitutes = const {},
    this.inherit = true,
    required this.child,
  });

  /// An iterable (typically a [Set]) that points [Get] objects to new values.
  final Iterable<Substitution> substitutes;

  /// The widget below this one in the tree.
  final Widget child;

  /// Whether this [GetScope] should also include substitutes from an ancestor scope,
  /// if applicable.
  ///
  /// Ancestor substitutes are ignored if the same value is substituted in this scope.
  final bool inherit;

  /// Returns `true` or `false` depending on whether the provided `context`
  /// has a [GetScope] widget as its ancestor.
  static bool hasScope(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SubstitutionModel>() != null;
  }

  /// If the [Get] object is overridden in an ancestor [GetScope], returns that object.
  ///
  /// Returns `null` otherwise.
  static ValueListenable<Object?>? maybeOf(
    BuildContext context,
    ValueListenable<Object?> placeholder, {
    bool? createDependency,
  }) {
    createDependency ??= WidgetsBinding.instance.building;
    final SubstitutionModel? model = createDependency
        ? context.dependOnInheritedWidgetOfExactType()
        : context.getInheritedWidgetOfExactType();

    if (model?.map.maybeGet(placeholder) case final scoped?) return scoped;

    late final _GetScopeState? scopeState = context.findAncestorStateOfType<_GetScopeState>();

    if (placeholder is ComputedNotifier || placeholder is ProxyNotifier) {
      if (model == null || scopeState == null) return null;

      final SubMap<_V> computers = scopeState.computers;
      if (computers.containsKey(placeholder)) return computers.get(placeholder);

      final ValueListenable<Object?> result = switch (placeholder) {
        final ComputedNotifier<Object?> computed => computed.scopeWith(
          model.map,
          scopeState.context,
        ),
        final ProxyNotifier<Object?, Object?> selector => selector.proxyWith(
          of(context, selector.input),
        ),
        _ => throw StateError('Placeholder is a ${placeholder.runtimeType}'),
      };

      return computers[placeholder] = result;
    }

    return null;
  }

  /// Returns the [Get] object that overrides this one.
  ///
  /// If no such object is found, returns the object provided as input.
  ///
  /// If `createDependency` is true, the context will be notified to rebuild
  /// when a [Substitution] is made for the placeholder
  /// (it does not subscribe to the listenable itself).
  ///
  /// See also:
  ///
  /// * [GetScope.maybeOf], which returns `null` if the relevant [Substitution]
  ///   is not found in the ancestor [GetScope].
  static ValueListenable<Object?> of(
    BuildContext context,
    ValueListenable<Object?> placeholder, {
    bool? createDependency,
  }) {
    return maybeOf(context, placeholder, createDependency: createDependency) ?? placeholder;
  }

  @override
  State<GetScope> createState() => _GetScopeState();
}

extension on Iterable<Substitution> {
  bool debugCheckDuplicates([BuildContext? context]) {
    final refs = <Object>{};
    for (final Substitution(placeholder: ref) in this) {
      if (refs.add(ref)) continue;
      throw FlutterError.fromParts([
        ErrorSummary('Duplicate overrides found for the same Get object.'),
        for (final sub in this)
          if (sub.placeholder == ref) sub.toDiagnosticsNode(),
        ErrorDescription(
          'A Get object representing a ${ref.runtimeType} '
          'was assigned multiple overrides in this collection.',
        ),
        if (context != null) ...[
          ErrorDescription('These overrides were added by the following widget:'),
          context.widget.toDiagnosticsNode(),
        ],
      ]);
    }
    return true;
  }

  Substitution? maybeLocate(Object? ref) {
    for (final sub in this) {
      if (sub.placeholder == ref) return sub;
    }
    return null;
  }

  Substitution locate(Object? ref) => maybeLocate(ref)!;
}

extension on Object {
  void dispose() => switch (this) {
    DisposeGuard() => null,
    final ChangeNotifier changeNotifier => changeNotifier.dispose(),
    final AnimationController controller => controller.dispose(),
    _ => null,
  };
}

class _GetScopeState extends State<GetScope> {
  late Iterable<Substitution> widgetSubs = widget.substitutes;
  late final widgetMap = <_V, _V>{
    for (final substitute in widgetSubs) substitute.placeholder: substitute.replacement,
  };

  @override
  RefContext get context => super.context as RefContext;

  @override
  void initState() {
    super.initState();
    assert(widgetSubs.debugCheckDuplicates(context));
  }

  late final computers = SubMap<_V>();

  @override
  void didUpdateWidget(GetScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Iterable<Substitution> newSubs = widget.substitutes;
    assert(newSubs.debugCheckDuplicates(context));

    for (final Object ref in widgetMap.keys) {
      if (newSubs.maybeLocate(ref) == null) {
        final Object? oldReplacement = widgetMap.remove(ref);
        final Substitution oldSub = widgetSubs.locate(ref);
        if (oldSub.autoDispose) oldReplacement?.dispose();
      }
    }

    for (final newSub in newSubs) {
      if (widgetMap[newSub.placeholder] case final oldReplacement?) {
        final Substitution oldSub = widgetSubs.locate(newSub.placeholder);
        if ((oldSub, newSub) case (
          _SubFactory(:final factory),
          _SubFactory(factory: final newFactory),
        ) when factory == newFactory) {
          continue;
        }
        final _V newReplacement = newSub.replacement;
        if (newReplacement != oldReplacement) {
          widgetMap[newSub.placeholder] = newReplacement;
          if (oldSub.autoDispose) oldReplacement.dispose();
        }
      }
    }
  }

  Object tag = Object();
  SubMap<_V>? _map;

  @override
  Widget build(BuildContext context) {
    final map = SubMap<_V>();

    for (final MapEntry(:key, :value) in widgetMap.entries) {
      map[key] ??= value;
    }
    if (widget.inherit) {
      if (context.dependOnInheritedWidgetOfExactType<SubstitutionModel>() case final model?) {
        for (final MapEntry(:key, :value) in model.map.entries) {
          map[key] ??= value;
        }
      }
    }

    for (final Object value in map.values) {
      if (value is VsyncValue<Object?>) this.context.registry.add(value);
    }

    if (_map case final oldMap? when !mapEquals(map, oldMap)) tag = Object();

    return SubstitutionModel(map: _map = map, equalityTag: tag, child: widget.child);
  }
}

/// An [InheritedModel] used by [ref] to store its [Substitution]s
/// and notify dependent widgets.
///
/// [ref] contains methods which can be used in [RefWidget] build methods
/// along with ___ render object stuff.
final class SubstitutionModel extends InheritedModel<_V> {
  /// Creates an [InheritedModel] that stores substitution data.
  const SubstitutionModel({
    super.key,
    required this.map,
    required this.equalityTag,
    required super.child,
  });

  /// The substitution map.
  ///
  /// The key is the original object; the value is the new object.
  final SubMap<ValueListenable<Object?>> map;

  /// Rather than calling [mapEquals] multiple times, the identity of this tag
  /// will change each time the model's map changes.
  ///
  /// This also helps clients determine how much work to perform,
  /// since a [GetScope] change might need a more thorough reset than a different dependency.
  final Object equalityTag;

  @override
  bool updateShouldNotify(SubstitutionModel oldWidget) => equalityTag != oldWidget.equalityTag;

  @override
  bool updateShouldNotifyDependent(
    SubstitutionModel oldWidget,
    Set<ValueListenable<Object?>> dependencies,
  ) {
    for (final _V dependency in dependencies) {
      if (map.maybeGet(dependency) != oldWidget.map.maybeGet(dependency)) return true;
    }
    return false;
  }
}
