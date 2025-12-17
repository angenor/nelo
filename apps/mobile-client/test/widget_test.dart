import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_client/app/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the app renders without errors
    expect(find.byType(App), findsOneWidget);
  });
}
