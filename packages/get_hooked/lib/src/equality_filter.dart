import 'package:collection/collection.dart' show Equality;

abstract interface class EqualityFilter {
  Equality<Object?>? get equality;
}

mixin HookedSelector<T> implements EqualityFilter {
  @override
  Equality<Object?>? get equality => null;

  Object? select(T value);
}
