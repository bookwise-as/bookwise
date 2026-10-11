import 'package:flutter_test/flutter_test.dart';

import 'package:book_recommendation_app/main.dart';

void main() {
  testWidgets('BookWise app renders the public welcome screen', (tester) async {
    await tester.pumpWidget(const BookApp());
    expect(find.text('BookWise'), findsOneWidget);
    expect(find.text('READ MORE.\nFEEL MORE.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
