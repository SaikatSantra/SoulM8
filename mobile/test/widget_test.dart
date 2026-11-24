import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulem8_app/app/app.dart';

void main() {
  testWidgets('Soulm8 App builds and renders initial login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Soulm8App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Soulm8App), findsOneWidget);
  });
}
