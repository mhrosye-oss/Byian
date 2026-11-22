import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:itqan/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start shows UI and completes local startup', (tester) async {
    app.main();
    const splash = ValueKey<String>('app-startup-splash');
    const ready = ValueKey<String>('app-ready-screen');

    await tester.pump();
    expect(
      find.byKey(splash).evaluate().isNotEmpty ||
          find.byKey(ready).evaluate().isNotEmpty,
      isTrue,
      reason: 'The first Flutter frame should show the splash or app UI.',
    );

    for (var attempt = 0;
        attempt < 120 && find.byKey(ready).evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(ready), findsOneWidget);
  });
}
