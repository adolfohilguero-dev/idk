# Chuleta SMX · app nativa en Flutter

Contenido: apuntes (21 secciones, con buscador e índice), calendario con avaluables,
mini tests, login/registro local, contador de registrados y avisos programados.

## Cómo compilar el APK

1. Instala Flutter (flutter.dev) y Android Studio (para el SDK de Android).
   Comprueba con `flutter doctor`.
2. Crea un proyecto vacío y copia estos archivos encima:
   ```
   flutter create --org com.smx --project-name chuleta_smx chuleta_smx
   ```
   Copia dentro de `chuleta_smx/`: la carpeta `lib/`, la carpeta `assets/`,
   `pubspec.yaml` (reemplaza el existente) y `patch_android.py`.
3. Dentro de `chuleta_smx/`:
   ```
   python3 patch_android.py          # permisos, avisos, nombre de la app
   flutter pub get
   dart run flutter_launcher_icons   # icono de la app
   flutter build apk --release
   ```
4. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
   Pásalo al móvil e instálalo (hay que permitir "instalar apps desconocidas").

Si `patch_android.py` falla, aplica a mano:
- `AndroidManifest.xml`: permisos INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED
  y los receptores `ScheduledNotificationReceiver` / `ScheduledNotificationBootReceiver`
  de flutter_local_notifications.
- `android/app/build.gradle(.kts)`: activar `coreLibraryDesugaring` y añadir
  `com.android.tools:desugar_jdk_libs:2.0.4`.

## Notas
- Las cuentas se guardan solo en el móvil (contraseña con hash + sal). No es seguridad real.
- El contador de registrados usa counterapi.dev (el mismo que la web) y necesita internet.
- Los avisos se programan con el móvil (día antes 9:00 y mismo día 8:00) y funcionan con la app cerrada.
  Android puede retrasarlos unos minutos para ahorrar batería.
- Para actualizar apuntes: `assets/content.json`; calendario: `assets/events.json`;
  tests: `assets/quiz.json`.
