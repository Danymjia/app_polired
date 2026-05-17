# Polired Mobile App

Aplicación móvil de la red social universitaria **Polired**, desarrollada en Flutter para Android e iOS.

## Descripción

Polired es una aplicación de interacción social dirigida a comunidades universitarias. El frontend está diseñado para consumir el backend `BackendV2`, que expone APIs de autenticación, feeds, publicaciones, artículos, redes comunitarias y mensajería.

## Documentación técnica

La documentación de implementación y las decisiones de arquitectura están en:

- `polired/informe_tecnico_polired.md`

## Características principales

- Autenticación JWT y persistencia de sesión
- Feed global y feed por comunidad
- Explore con categorías reales: Noticias, Marketplace y Cursos
- Creación de publicaciones estándar y artículos pagados
- Perfil de usuario con biografía y foto
- Bandeja de mensajes y notificaciones informativas
- Integración con WebSocket / Socket.IO para actualización de conversaciones

## Arquitectura

El proyecto utiliza un patrón de estado simple basado en `provider` con los siguientes componentes clave:

- `ApiService` — capa HTTP con manejo de errores centralizado
- `AuthProvider` — gestión de sesión y token JWT
- `NetworkProvider` — control de redes comunitarias / historias
- `GlobalFeedProvider` — carga del feed de Explore por categoría
- `PostService` — orquesta los endpoints de publicaciones y artículos

## Endpoints principales

El frontend consume las siguientes rutas del backend:

- `POST /auth/login` — autenticación
- `POST /registro-estudiantes` — registro de usuario
- `GET /perfil-estudiante` — perfil completo del usuario
- `PATCH /completar/perfil` — completar perfil inicial
- `PATCH /perfil/username` — cambiar username
- `PATCH /estudiante/:id` — actualizar datos del perfil
- `GET /redes/listar` — redes disponibles
- `GET /estudiantes/listar/redes` — redes del usuario
- `POST /estudiantes/unirse/red` — unirse a una red
- `GET /publicaciones/red/:redId` — feed de una red específica
- `GET /publicaciones/global` — feed global para Explore Noticias
- `GET /publicaciones/articulos/global` — feed global de artículos para Marketplace/Cursos
- `POST /estudiantes/publicaciones` — crear publicación estándar
- `POST /publicaciones/articulos` — crear artículo de Venta o Cursos

> El backend espera JWT en el header `Authorization: Bearer <token>` para la mayoría de operaciones protegidas.

## Requisitos

- Flutter SDK compatible con el proyecto
- Android SDK / emulador o dispositivo iOS
- Backend `BackendV2` corriendo localmente o accesible desde la red

## Configuración local

1. Abre la carpeta `polired`.
2. Ejecuta:
   ```bash
   flutter pub get
   ```
3. Asegúrate de que el backend esté activo en `BackendV2` y que la URL base en `lib/config/constants.dart` apunte al servidor correcto.

## Ejecución

En la carpeta `polired`:

```bash
flutter run
```

Para analizar el proyecto:

```bash
flutter analyze
```

## Notas de despliegue

- En emulador Android se usa `http://10.0.2.2:3000/api`
- En dispositivo físico, sustituye la URL por la IP local del servidor

## Buenas prácticas

- Mantén el token JWT actualizado en `ApiService`
- Usa `flutter analyze` antes de cada compilación
- Consulta `informe_tecnico_polired.md` para los detalles de arquitectura, endpoint y flujo de datos

## Estado actual

- `Home` y `Explore` consumen datos reales del backend
- `Explore` soporta categorías: `Noticias`, `Marketplace`, `Cursos`
- Las publicaciones de `Venta` y `Cursos` usan el endpoint de artículos correcto
- `flutter analyze` se ejecuta sin errores

## Cambios recientes: manejo de imágenes remotas

Se centralizó y endureció el renderizado de imágenes remotas para evitar fallos visibles y unificar la UX de carga/errores.

- Nuevo helper: `SafeNetworkImage` en `lib/widgets/safe_network_image.dart`.
  - Maneja URL vacías, estado de carga (spinner), errores y placeholders.
  - Soporta `borderRadius`, `width`, `height`, `fit` y `errorWidget` personalizado.

- Reemplazos aplicados (renderizado ahora usa `SafeNetworkImage` o `CircularNetworkAvatar`):
  - `lib/widgets/network_avatar.dart`
  - `lib/screens/messages/messages_screen.dart`
  - `lib/screens/post/add_post_screen.dart`
  - `lib/screens/profile/profile_screen.dart`

- Comportamiento conservado:
  - Los placeholders previos (iniciales, iconos de grupo) se mantienen pasando widgets como `errorWidget`.
  - La subida de `fotoPerfil` desde la app sigue siendo la misma (payload Base64); sólo se cambió la forma de renderizar la imagen.

### Cómo validar localmente

1. Instala dependencias y ejecuta análisis estático:

```bash
cd polired
flutter pub get
flutter analyze
```

2. Ejecuta la app en emulador/dispositivo y revisa estas pantallas principales:
   - Perfil: avatar de usuario y edición de foto.
   - Mensajes: lista de conversaciones y avatar en cada conversación.
   - Selección de redes en `Add Post` y `Stories`: imágenes de redes.

3. Qué verificar:
   - Avatares muestran iniciales si no hay URL.
   - Durante carga aparece un spinner pequeño y no se generan excepciones visibles.
   - En error (imagen 404/corrupta) aparece el placeholder configurado.

### Próximos pasos recomendados

- Ejecutar `flutter analyze` y resolver avisos si aparecen (tarea pendiente en el TODO).
- Opcional: migrar `SafeNetworkImage` para usar `cached_network_image` si deseas caching automático y placeholders más avanzados.
- Revisar pantallas adicionales (mensajes, notificaciones, listas de posts) si detectas alguna imagen directa residual.

Si quieres, puedo ejecutar `flutter analyze` ahora y corregir avisos directamente desde el repo.
