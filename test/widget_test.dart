import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:carsync_app/features/auth/login_screen.dart';

void main() {
  testWidgets('renders login and register options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Entrar'), findsAtLeastNWidgets(1));
    expect(find.text('Cadastrar'), findsAtLeastNWidgets(1));
  });
}
