import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_app/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('OM Finance'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
