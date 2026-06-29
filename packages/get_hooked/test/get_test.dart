import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

void main() {
  group('Get and ref', () {
    testWidgets('Get.it + ref.watch causes targeted rebuilds', (tester) async {
      final counter = Get.it(0);
      int outerBuilds = 0;
      int innerBuilds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              outerBuilds++;
              return Column(
                children: [
                  Text('outer=$outerBuilds'),
                  RefBuilder((_) {
                    final c = ref.watch(counter);
                    innerBuilds++;
                    return Text('inner=$c builds=$innerBuilds');
                  }),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('outer=1'), findsOneWidget);
      expect(find.text('inner=0 builds=1'), findsOneWidget);
      expect(outerBuilds, 1);
      expect(innerBuilds, 1);

      counter.value = 42;
      await tester.pump();

      // Only the RefBuilder part should rebuild.
      expect(find.text('outer=1'), findsOneWidget);
      expect(find.text('inner=42 builds=2'), findsOneWidget);
      expect(outerBuilds, 1);
      expect(innerBuilds, 2);
    });

    testWidgets('ref.select rebuilds only on selected change', (tester) async {
      final data = Get.it(const _Data(10, 'hello'));
      int selectBuilds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final len = ref.select(data, (d) => d.name.length);
            selectBuilds++;
            return Text('len=$len builds=$selectBuilds');
          }),
        ),
      );
      expect(find.text('len=5 builds=1'), findsOneWidget);

      // Change number (unselected): no rebuild
      data.value = const _Data(99, 'hello');
      await tester.pump();
      expect(find.text('len=5 builds=1'), findsOneWidget);

      // Change name length: rebuild
      data.value = const _Data(1, 'hi');
      await tester.pump();
      expect(find.text('len=2 builds=2'), findsOneWidget);
    });

    testWidgets('ref.compute reacts to watched dependencies', (tester) async {
      final base = Get.it(5);
      final computed = Get.compute((r) => r.watch(base) * 2);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final v = ref.watch(computed);
            return Text('c=$v');
          }),
        ),
      );
      expect(find.text('c=10'), findsOneWidget);

      base.value = 7;
      await tester.pump();
      expect(find.text('c=14'), findsOneWidget);
    });

    testWidgets('Get.list / GetSet / GetMap work as collections and notify', (tester) async {
      final glist = Get.list<int>([1, 2]);
      final gset = Get.set<String>({'a'});
      final gmap = Get.map<String, int>({'x': 1});

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            ref.watch(glist);
            ref.watch(gset);
            ref.watch(gmap);
            return Text('list=${glist.length} set=${gset.length} map=${gmap.length}');
          }),
        ),
      );
      expect(find.text('list=2 set=1 map=1'), findsOneWidget);

      glist.add(3);
      await tester.pump();
      expect(find.text('list=3 set=1 map=1'), findsOneWidget);

      gset.add('b');
      gmap['y'] = 2;
      await tester.pump();
      expect(find.text('list=3 set=2 map=2'), findsOneWidget);
    });

    testWidgets('Get.vsync and Get.vsyncValue animate and notify', (tester) async {
      // Use a bounded vsync double for basic smoke (animation may require vsync in real but here we test subscription)
      final vdouble = Get.vsync(initialValue: 0.0);
      final vvalue = Get.vsyncValue<double>(0.0, duration: const Duration(milliseconds: 10));

      int dBuilds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final d = ref.watch(vdouble);
            final vv = ref.watch(vvalue);
            dBuilds++;
            return Text('d=$d v=$vv');
          }),
        ),
      );
      expect(find.textContaining('d=0'), findsOneWidget);

      vdouble.value = 0.5; // direct set for vsync double works as ValueNotifier-ish
      await tester.pump();
      expect(find.textContaining('d=0.5'), findsOneWidget);
      expect(dBuilds, 2);
    });

    testWidgets('Get.async works with future', (tester) async {
      final future = Future<String>.value('done');
      final gasync = Get.async<String>(() => future, initialData: 'loading');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final snap = ref.watch(gasync);
            return Text('done=${snap.done} val=${snap.value}');
          }),
        ),
      );

      // Initial pump may show loading or done depending on microtask timing.
      await tester.pump();
      // After pump the future should have completed in test env.
      expect(find.textContaining('done=true'), findsOneWidget);
    });
  });
}

@immutable
class _Data {
  const _Data(this.number, this.name);
  final int number;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _Data && other.number == number && other.name == name;

  @override
  int get hashCode => Object.hash(number, name);
}
