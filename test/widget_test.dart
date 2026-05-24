import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/main.dart';

void main() {
  testWidgets('Wallet App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const WalletApp());
    expect(find.byType(WalletApp), findsOneWidget);
  });
}
