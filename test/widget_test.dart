import 'package:flutter_test/flutter_test.dart';
import 'package:calcul_projet/app.dart';

void main() {
  testWidgets('Accueil affiche les modules de calcul', (tester) async {
    await tester.pumpWidget(const CalculBtpApp(showSplash: false));
    await tester.pumpAndSettle();
    expect(find.text('Terrassement'), findsOneWidget);
    expect(find.text('Gros œuvre'), findsOneWidget);
    expect(find.text('Électricité'), findsOneWidget);
    expect(find.text('Finitions'), findsOneWidget);
  });
}
