// ignore_for_file: public_member_api_docs, procrastinating !

part of '../hooked.dart';

abstract interface class Hooked implements BuildContext {
  static Hooked? active;

  T select<T>(Listenable listenable, ValueGetter<T> selector);

  void vsync(Vsync vsync);
}
