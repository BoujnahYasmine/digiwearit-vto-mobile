import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/main.dart';
void main() { testWidgets('renders Digiwearit UI', (tester) async { await tester.pumpWidget(const DigiwearitApp()); expect(find.text('Digiwearit'), findsOneWidget); expect(find.text('Utiliser ce filtre'), findsOneWidget); expect(find.text('Catalogues'), findsOneWidget); }); }
