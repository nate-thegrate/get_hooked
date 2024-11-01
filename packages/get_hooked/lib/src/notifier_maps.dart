part of '../get_hooked.dart';

@visibleForTesting
final valueNotifierMap = NotifierMap<GetIt<Object?>>();

@visibleForTesting
final animationMap = NotifierMap<Hooked<Object?>>();

@visibleForTesting
extension type NotifierMap<Notifier extends GetIt>._(Map<Object, Notifier> _map) {
  NotifierMap() : _map = HashMap();

  T putIfAbsent<T extends Notifier>(ValueGetter<T> create, {Object? key}) {
    dispose<T>(key: key);
    return _map.putIfAbsent(key ?? T, create) as T;
  }

  void set<T extends Notifier>(T value, {Object? key}) {
    dispose<T>(key: key);
    _map[key ?? T] = value;
  }

  T? maybeGet<T extends Notifier>({Object? key}) {
    final result = _map[key ?? T];
    if (result is T?) {
      return result;
    }
    throw FlutterError.fromParts([
      ErrorSummary('Retrieved a ${result.runtimeType}, which did not match the type $T.'),
      ErrorHint('Try calling getIt<${result.runtimeType}> instead.'),
    ]);
  }

  T get<T extends Notifier>({Object? key}) {
    final T? result = maybeGet(key: key);

    assert(() {
      if (result != null) return true;

      final locator = key != null ? 'key "$key"' : 'type $T';
      throw FlutterError.fromParts([
        ErrorSummary('The $locator is not registered.'),
        ErrorHint('Try calling setIt() with the $locator before calling getIt()'),
      ]);
    }());

    return result!;
  }

  void dispose<T extends Notifier>({Object? key}) {
    final Notifier? entry = maybeGet<T>(key: key);
    if (entry case Notifier(context: null)) {
      entry.dispose();
      _map.remove(key ?? T);
    }
  }
}
