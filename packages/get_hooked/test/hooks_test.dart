import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

void main() {
  group('Hook functions', () {
    testWidgets('useRef preserves mutable value across rebuilds without causing rebuilds', (tester) async {
      final trigger = Get.it(0);
      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            ref.watch(trigger);
            final obj = useRef(0);
            buildCount++;
            if (buildCount == 1) {
              obj.value = 123;
            }
            return Text('val=${obj.value} builds=$buildCount');
          }),
        ),
      );

      expect(find.text('val=123 builds=1'), findsOneWidget);
      expect(buildCount, 1);

      // Trigger a rebuild via watched value; the ref value should persist.
      trigger.value = 1;
      await tester.pump();
      expect(find.text('val=123 builds=2'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('useMemoized caches value until key changes', (tester) async {
      final trigger = Get.it(0);
      int createCount = 0;

      Widget buildMemo(Object? key) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            ref.watch(trigger);
            final value = useMemoized(() {
              createCount++;
              return 'created#$createCount';
            }, key: key);
            return Text(value);
          }),
        );
      }

      await tester.pumpWidget(buildMemo(null));
      expect(find.text('created#1'), findsOneWidget);
      expect(createCount, 1);

      // Same key (null): no recreate
      trigger.value = 1;
      await tester.pump();
      expect(find.text('created#1'), findsOneWidget);
      expect(createCount, 1);

      // Change key: recreate
      await tester.pumpWidget(buildMemo('new-key'));
      expect(find.text('created#2'), findsOneWidget);
      expect(createCount, 2);
    });

    testWidgets('useEffect runs on key change and disposes previous', (tester) async {
      final keyGet = Get.it<Object?>('a');
      final log = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            final k = ref.watch(keyGet);
            useEffect(() {
              log.add('effect-$k');
              return () => log.add('dispose-$k');
            }, key: k);
            return const SizedBox();
          }),
        ),
      );
      expect(log, ['effect-a']);

      keyGet.value = 'b';
      await tester.pump();
      expect(log, ['effect-a', 'effect-b', 'dispose-a']);
    });

    testWidgets('useValueListenable returns value and rebuilds on change', (tester) async {
      final vn = Get.it('initial');
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            final v = useValueListenable(vn);
            builds++;
            return Text('v=$v builds=$builds');
          }),
        ),
      );
      expect(find.text('v=initial builds=1'), findsOneWidget);

      vn.value = 'updated';
      await tester.pump();
      expect(find.text('v=updated builds=2'), findsOneWidget);
    });

    testWidgets('useListenable subscribes without returning value', (tester) async {
      final ln = Get.it(0); // actually GetValue but used as Listenable
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder((context) {
            useListenable(ln);
            builds++;
            return Text('builds=$builds');
          }),
        ),
      );
      expect(find.text('builds=1'), findsOneWidget);

      ln.value = 99;
      await tester.pump();
      expect(find.text('builds=2'), findsOneWidget);
    });

    testWidgets('HookWidget works (not just HookBuilder)', (tester) async {
      final vn = Get.it(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestHookWidget(vn),
        ),
      );
      expect(find.text('flag=false'), findsOneWidget);

      vn.value = true;
      await tester.pump();
      expect(find.text('flag=true'), findsOneWidget);
    });
  });
}

class _TestHookWidget extends HookWidget {
  const _TestHookWidget(this.flag);

  final ValueListenable<bool> flag;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(flag);
    return Text('flag=$f');
  }
}
