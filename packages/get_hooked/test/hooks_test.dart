import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

void main() {
  group('RefWidget and ref', () {
    testWidgets('ref.watch subscribes and rebuilds on change', (tester) async {
      final vn = Get.it('initial');
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final v = ref.watch(vn);
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

    testWidgets('ref.watch can be called conditionally without errors', (tester) async {
      final a = Get.it(10);
      final b = Get.it(20);
      final showB = Get.it(false);
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final aVal = ref.watch(a);
            final bVal = ref.watch(showB) ? ref.watch(b) : 0;
            builds++;
            return Text('a=$aVal b=$bVal builds=$builds');
          }),
        ),
      );

      expect(find.text('a=10 b=0 builds=1'), findsOneWidget);

      // Turn on watching b
      showB.value = true;
      await tester.pump();
      expect(find.text('a=10 b=20 builds=2'), findsOneWidget);

      // Now changing b should trigger rebuild
      b.value = 30;
      await tester.pump();
      expect(find.text('a=10 b=30 builds=3'), findsOneWidget);
    });

    testWidgets('ref.watch same listenable twice is safe', (tester) async {
      final counter = Get.it(0);
      int builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RefBuilder((context) {
            final a = ref.watch(counter);
            final b = ref.watch(counter); // same listenable again
            builds++;
            return Text('a=$a b=$b builds=$builds');
          }),
        ),
      );

      expect(find.text('a=0 b=0 builds=1'), findsOneWidget);

      counter.value = 5;
      await tester.pump();
      expect(find.text('a=5 b=5 builds=2'), findsOneWidget);
      expect(builds, 2);
    });

    testWidgets('RefWidget works (not just RefBuilder)', (tester) async {
      final vn = Get.it(false);

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: _TestRefWidget(vn)),
      );
      expect(find.text('flag=false'), findsOneWidget);

      vn.value = true;
      await tester.pump();
      expect(find.text('flag=true'), findsOneWidget);
    });
  });
}

class _TestRefWidget extends RefWidget {
  const _TestRefWidget(this.flag);

  final ValueListenable<bool> flag;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(flag);
    return Text('flag=$f');
  }
}
