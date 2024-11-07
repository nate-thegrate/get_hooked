class ValueKey<T> {
  const ValueKey(this.value);

  final T value;
}

class WrapperClass<T, K extends ValueKey<T>> {
  const WrapperClass(this.key);

  final K key;
}

extension type const WrapperType<T, K extends ValueKey<T>>(K key) {}

const wrapper = WrapperClass(ValueKey('hello'));
const wrapper2 = WrapperType(ValueKey('world'));
