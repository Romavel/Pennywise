import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/errors/app_failure.dart';
import 'package:pennywise/features/splash/presentation/splash_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows a loading state, then the dashboard', (tester) async {
    await pumpPennywise(
      tester,
      firebaseInit: () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Getting things ready…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows the failure and recovers after retry', (tester) async {
    var attempts = 0;
    await pumpPennywise(
      tester,
      firebaseInit: () async {
        attempts++;
        if (attempts == 1) throw const FirebaseNotConfiguredFailure();
      },
    );
    await tester.pumpAndSettle();

    expect(
      find.text(const FirebaseNotConfiguredFailure().message),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
