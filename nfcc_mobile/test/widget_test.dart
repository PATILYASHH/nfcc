import 'package:flutter_test/flutter_test.dart';
import 'package:nfcc_mobile/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const NfccApp());
    expect(find.text('NFCC'), findsOneWidget);
  });
}
