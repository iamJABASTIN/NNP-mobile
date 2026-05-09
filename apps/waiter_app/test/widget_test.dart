import 'package:flutter_test/flutter_test.dart';
import 'package:waiter_app/main.dart';

void main() {
  testWidgets('WaiterApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WaiterApp());
    // App should render without crashing
    expect(find.text('INITIALIZING POS...'), findsOneWidget);
  });
}
