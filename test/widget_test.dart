import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_kesif_haritasi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TurkiyeKesifApp());
    expect(find.byType(TurkiyeKesifApp), findsOneWidget);
  });
}
