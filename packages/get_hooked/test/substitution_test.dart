import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked/get_hooked.dart';

void main() {
  group('GetScope and substitutions', () {
    testWidgets('GetScope substitutes a Get for descendants using ref.watch', (tester) async {
      final original = Get.it('orig');
      final replacement = Get.it('repl');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GetScope(
            substitutes: {Substitution(original, replacement)},
            child: RefBuilder((context) {
              final v = ref.watch(original);
              return Text('val=$v');
            }),
          ),
        ),
      );

      expect(find.text('val=repl'), findsOneWidget);
    });

    testWidgets('GetScope.inherit=false does not inherit ancestor subs', (tester) async {
      final key = Get.it('root');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GetScope(
            substitutes: {Substitution(key, Get.it('root-val'))},
            child: GetScope(
              inherit: false,
              child: RefBuilder((context) {
                return Text(ref.watch(key));
              }),
            ),
          ),
        ),
      );
      // Without inherit, should see original
      expect(find.text('root'), findsOneWidget);
    });
  });
}
