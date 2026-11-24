// Pruebas que no necesitan conexión a Supabase: formularios, validaciones y
// conversión de modelos a/desde filas de la base de datos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/screens/login_screen.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_form.dart';
import 'package:refugio_huellitas/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() {
    // Cliente apuntando a una URL ficticia: las pruebas nunca llegan a la red.
    serviceLocator.initialize(SupabaseClient('https://example.supabase.co', 'anon-key-de-prueba'));
  });

  group('LoginScreen', () {
    testWidgets('muestra los campos y el botón de iniciar sesión', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('¿No tienes cuenta? Crear cuenta'), findsOneWidget);
    });

    testWidgets('valida correo y contraseña antes de enviar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'correo-invalido');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('permite cambiar a modo crear cuenta', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('¿No tienes cuenta? Crear cuenta'));
      await tester.pump();
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.text('¿Ya tienes cuenta? Inicia sesión'), findsOneWidget);
    });
  });

  group('PetForm', () {
    testWidgets('precarga los datos al editar', (tester) async {
      final pet = Pet(
        id: 'abc',
        name: 'Luna',
        age: 3,
        type: PetType.cat,
        breed: 'Siamés',
        vaccinationStatus: VaccinationStatus.vaccinated,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PetForm(
            initialPet: pet,
            submitText: 'Guardar Cambios',
            loadingText: 'Guardando...',
            onSubmit: (_) async => true,
          ),
        ),
      ));

      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Siamés'), findsOneWidget);
      expect(find.text('Gato'), findsOneWidget);
      expect(find.byType(RadioGroup<VaccinationStatus>), findsOneWidget);
    });

    testWidgets('no envía si faltan campos obligatorios', (tester) async {
      var submitted = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PetForm(
            submitText: 'Registrar Mascota',
            loadingText: 'Registrando...',
            onSubmit: (_) async => submitted = true,
          ),
        ),
      ));

      await tester.ensureVisible(find.text('Registrar Mascota'));
      await tester.tap(find.text('Registrar Mascota'));
      await tester.pump();
      expect(submitted, isFalse);
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
    });
  });

  group('Modelos', () {
    test('Pet.toMap y Pet.fromMap usan las columnas de la tabla mascotas', () {
      final pet = Pet(
        name: 'Max',
        age: 2,
        type: PetType.dog,
        breed: 'Labrador',
        vaccinationStatus: VaccinationStatus.partiallyVaccinated,
        registrationDate: DateTime.utc(2026, 1, 15),
      );
      final map = pet.toMap();
      expect(map['tipo'], 'perro');
      expect(map['estado_vacunacion'], 'parcial');
      expect(map['estado_adopcion'], 'disponible');
      expect(map.containsKey('id'), isFalse);

      final back = Pet.fromMap({...map, 'id': 'uuid-1'});
      expect(back.id, 'uuid-1');
      expect(back.type, PetType.dog);
      expect(back.vaccinationStatus, VaccinationStatus.partiallyVaccinated);
    });

    test('AdoptionRequest.fromMap lee los nombres del join', () {
      final request = AdoptionRequest.fromMap({
        'id': 'r1',
        'mascota_id': 'p1',
        'adoptante_id': 'a1',
        'fecha_solicitud': '2026-02-01T10:00:00Z',
        'estado': 'aprobada',
        'observaciones': null,
        'mascotas': {'nombre': 'Luna'},
        'adoptantes': {'nombre_completo': 'Ana Gómez'},
      });
      expect(request.status, RequestStatus.approved);
      expect(request.petName, 'Luna');
      expect(request.adopterName, 'Ana Gómez');
    });
  });
}
