import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qapp/main.dart';

void main() {
  testWidgets('Qapp starts on the splash screen', (tester) async {
    await tester.pumpWidget(const Qapp());
    expect(find.byType(Qapp), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
