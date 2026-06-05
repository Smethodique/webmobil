import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmp_prep_ai/main.dart';

void main() {
  testWidgets('App renders dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FmpPrepApp()));
    expect(find.text('FMP Prep AI'), findsOneWidget);
  });
}
