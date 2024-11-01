part of '../get_hooked.dart';

sealed class GetIt<T> implements ValueNotifier<T> {
  factory GetIt(
    T initialValue, [
    BuildContext? context,
  ]) = _Notifier<T>;

  @protected
  @override
  // Overridden here to get past "protected" lints in this library.
  bool get hasListeners;

  @protected
  abstract final BuildContext? context;
}

class _Notifier<T> extends ValueNotifier<T> implements GetIt<T> {
  _Notifier(super.value, [this.context]);

  @override
  final BuildContext? context;
}

GetIt<T> getIt<T>({Object? key}) => valueNotifierMap.get(key: key);

GetIt<T> setIt<T>(T value, {Object? key}) {
  final result = GetIt<T>(value);
  valueNotifierMap.set(result);
  return result;
}

/// Similar to [useState], but globally scoped.
GetIt<T> useIt<T>(
  T initialValue, {
  Object? key,
  bool listen = true,
  bool autoDispose = false,
}) {
  return use(_UseItHook(initialValue, key, listen, autoDispose));
}

class _UseItHook<T> extends Hook<GetIt<T>> {
  const _UseItHook(this.initialValue, this.key, this.listen, this.autoDispose);

  final T initialValue;
  final Object? key;
  final bool listen, autoDispose;

  @override
  _UseItState<T> createState() => _UseItState<T>();
}

class _UseItState<T> extends HookState<GetIt<T>, _UseItHook<T>> {
  late GetIt<T> _notifier;

  void rebuild() => setState(() {});

  @override
  void initHook() {
    _notifier = setIt(hook.initialValue)..addListener(rebuild);
  }

  @override
  void didUpdateHook(_UseItHook<T> oldHook) {
    final shouldListen = hook.listen;
    if (shouldListen != oldHook.listen) {
      shouldListen ? _notifier.addListener(rebuild) : _notifier.removeListener(rebuild);
    }
    assert(() {
      if (hook.key == oldHook.key) return true;
      throw FlutterError.fromParts([
        ErrorSummary('useIt() was rebuilt with a different key.'),
        ErrorDescription("Switching keys during a HookWidget's lifecycle is not supported."),
        ErrorHint('(old key: ${oldHook.key}, new key: ${hook.key})'),
      ]);
    }());
  }

  @override
  void dispose() {
    if (hook.autoDispose) {
      valueNotifierMap.dispose<GetIt<T>>(key: hook.key);
      _notifier.dispose();
    } else {
      _notifier.removeListener(rebuild);
    }
  }

  @override
  GetIt<T> build(BuildContext context) => _notifier;
}
