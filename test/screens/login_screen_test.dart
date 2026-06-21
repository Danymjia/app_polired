import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:polired/providers/auth_provider.dart';
import 'package:polired/screens/auth/login_screen.dart';

@GenerateMocks([AuthProvider])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
  });

  Widget createWidgetUnderTest() {
    // Es crítico envolver la pantalla en un MaterialApp para proporcionar 
    // MediaQuery, Navigator y Theme, y en ChangeNotifierProvider para el Auth.
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuth,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('Muestra error si se intenta iniciar sesión con campos vacíos', (WidgetTester tester) async {
    // Arrange: Montamos el widget
    await tester.pumpWidget(createWidgetUnderTest());

    // Aseguramos que la animación inicial (FadeTransition) concluya
    await tester.pumpAndSettle();

    // Verificamos que los textos de error NO existen inicialmente
    expect(find.text('El correo es obligatorio'), findsNothing);
    expect(find.text('La contraseña es obligatoria'), findsNothing);

    // Act: Hacemos tap en el botón de login sin llenar los campos
    // Usamos find.text para localizar el PrimaryButton o el texto en su interior
    await tester.tap(find.text('Iniciar sesión'));
    
    // Disparamos un frame para que los errores del FormState se rendericen
    await tester.pumpAndSettle();

    // Assert: Verificamos los strings literales exactos
    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });
}
