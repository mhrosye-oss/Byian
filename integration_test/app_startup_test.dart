import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:itqan/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start reaches the app instead of remaining on splash',
      (tester) async {
    app.main();
    const ready = ValueKey<String>('app-ready-screen');
    const error = ValueKey<String>('app-startup-error');

    for (var attempt = 0; attempt < 120; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(ready).evaluate().isNotEmpty ||
          find.byKey(error).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(error), findsNothing,
        reason: 'A clean install should be able to load settings and session.');
    expect(find.byKey(ready), findsOneWidget,
        reason: 'The startup splash should give way to the actual app.');
    expect(tester.takeException(), isNull);
  });
}
