# Refugio Huellitas

App Flutter de adopción de mascotas con **Supabase**: PostgreSQL, Auth con correo y contraseña, y Row Level Security.
Tiene tres entidades: `mascotas`, `adoptantes` y `solicitudes_adopcion`.

## 1. Configurar Supabase

1. Crea un proyecto en <https://supabase.com/dashboard> (New project). Guarda la contraseña de la base de datos.
2. Abre **SQL Editor → New query**, pega todo `supabase/schema.sql` y pulsa **Run**. El script crea:
   - las tablas, los `CHECK` y las FK con `ON DELETE RESTRICT`;
   - RLS y sus políticas;
   - los triggers;
   - la publicación de Realtime para `mascotas`.
3. **Desactiva la confirmación de correo para las pruebas:** en **Authentication → Sign In / Providers → Email**, apaga **Confirm email** y pulsa **Save**. En versiones anteriores del panel está en Authentication → Providers → Email.
   Con esto, "Crear cuenta" inicia sesión de inmediato.
4. Crea el usuario de prueba de una de estas formas:
   - desde la app, con **Crear cuenta**;
   - o en **Authentication → Users → Add user → Create new user**: escribe el correo y la contraseña, y marca *Auto Confirm User*.
5. Copia las credenciales en **Project Settings → API Keys** (la URL está en **Data API** o en el botón *Connect*):
   - `Project URL`;
   - la clave pública **anon** (pestaña *Legacy API keys*) o la **publishable** (`sb_publishable_...`). Las dos sirven.
   - ⚠️ No uses nunca la clave `service_role` ni la `secret`.
6. Comprueba que Realtime está activo: en **Database → Publications → supabase_realtime**, `mascotas` debe aparecer marcada. El script ya la agrega.

## 2. Configurar y ejecutar la app

```bash
cp env.example.json env.json      # en Windows: copy env.example.json env.json
# edita env.json con tu SUPABASE_URL y SUPABASE_ANON_KEY
flutter pub get
flutter run --dart-define-from-file=env.json
```

`env.json` está en `.gitignore`. Si ejecutas la app sin ese archivo, muestra una pantalla que explica cómo arrancarla.

## 3. Prueba de sincronización (checklist de la rúbrica)

- [ ] **Login:** inicia sesión con el usuario de prueba.
- [ ] **Registrar:** en *Registrar Mascota*, guarda una mascota.
- [ ] **Ver en la app:** aparece en *Consultar Mascotas*.
- [ ] **Ver en Supabase:** en **Table Editor → mascotas** está la fila, con tu `user_id`.
- [ ] **Editar:** toca la tarjeta → *Editar* → cambia la raza → *Guardar Cambios*.
- [ ] **Verificar en la BD:** el cambio se ve en el Table Editor.
- [ ] **Extra Realtime:** cambia un campo desde el Table Editor; el listado se actualiza solo.
- [ ] **Eliminar:** en el detalle, *Eliminar* → confirmar.
- [ ] **Verificar en la BD:** la fila ya no existe.
- [ ] **Sin sesión:** cierra sesión (icono del AppBar). La app vuelve al login, y las rutas protegidas también redirigen al login. Con la clave anon y sin sesión, RLS no devuelve filas.
- [ ] **Adopciones:** crea un adoptante y luego una solicitud. La mascota pasa a *En proceso*. Al aprobar pasa a *Adoptada*; al rechazar vuelve a *Disponible*.
- [ ] **RESTRICT:** intenta eliminar una mascota que tiene solicitudes. La app muestra un mensaje y la BD no la borra.

## 4. Dónde está cada parte del código

| Parte | Archivo |
|---|---|
| Configuración (credenciales) | `lib/core/supabase_config.dart`, `env.example.json` |
| Conexión / inicialización | `lib/main.dart` (`Supabase.initialize`), `lib/service_locator.dart` |
| Esquema SQL, RLS y triggers | `supabase/schema.sql` |
| Autenticación | `lib/domain/repositories/auth_repository.dart`, `lib/data/repositories/auth_repository_impl.dart`, `lib/presentation/screens/login_screen.dart`, `lib/presentation/screens/auth_gate.dart` |
| Rutas protegidas | `lib/presentation/app_router.dart` |
| Insert | `insertPet` en `lib/data/datasources/pet_remote_data_source.dart` (y `insertAdopter`, `insertRequest`) |
| Select | `getAllPets`, `getPetById` y `watchPets` (Realtime) en `pet_remote_data_source.dart` |
| Update | `updatePet` en `pet_remote_data_source.dart`; `updateStatus` en `adoption_request_remote_data_source.dart` |
| Delete | `deletePet` en `pet_remote_data_source.dart` (y `deleteAdopter`, `deleteRequest`) |
| Manejo de errores | `lib/core/error_mapper.dart`, `lib/presentation/widgets/app_snackbar.dart` |
| Modelos (`toMap` / `fromMap`) | `lib/domain/models/pet.dart`, `adopter.dart`, `adoption_request.dart` |
| Pantallas | `lib/presentation/screens/` (inicio, listado, registro, detalle, edición, adopciones, login) |

## Nota para Windows

Si la ruta del proyecto tiene tildes (por ejemplo `C:\Users\Juan sebastián V\...`), `flutter analyze` puede fallar con `FormatException`. Es un error del analizador con caracteres no ASCII.
La solución es montar la carpeta en una unidad virtual:

```powershell
subst R: "C:\ruta\con\tilde\refugio_huellitas"
cd R:\refugio_huellitas
flutter analyze
```

Para compilar con plugins en Windows, activa además el **Modo de desarrollador**: ejecuta `start ms-settings:developers`.
