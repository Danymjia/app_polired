# Informe Técnico Completo — Polired Mobile App

> **Versión:** 1.6 — Perfil, biografía y sincronización con el servidor  
> **Fecha:** Mayo 2026  
> **Plataforma:** Flutter (Android / iOS)  
> **Backend:** Node.js + Express + MongoDB (BackendV2)

---

## 1. Descripción del Proyecto

**Polired** es una aplicación móvil tipo red social universitaria inspirada en Instagram, conectada a un backend existente en `/BackendV2`. Se desarrolla de forma progresiva, ordenada y documentada.

---

## 2. Arquitectura Implementada

### Patrón

```
Provider + Repository Pattern simplificado
```

**Decisión técnica:** No se usa Clean Architecture ni Bloc/Riverpod por criterio de simplicidad, claridad y mantenibilidad.

### Árbol de capas

```
main.dart
  └── MultiProvider
        ├── AuthProvider
        │     ├── AuthService  ──► ApiService  ──► Backend HTTP
        │     └── SocketService ──► Backend Socket.IO
        └── NetworkProvider
              └── NetworkService ──► ApiService ──► Backend HTTP
```

---

## 3. Estructura del Proyecto

```
lib/
├── main.dart
├── config/
│   ├── constants.dart
│   ├── routes.dart
│   └── theme.dart
├── models/
│   ├── user_model.dart
│   ├── network_story_model.dart
│   └── post_model.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── network_service.dart
│   ├── socket_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── network_provider.dart
├── screens/
│   ├── main_layout_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── post/
│   │   └── add_post_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── settings_screen.dart
│   └── settings/
│       ├── notifications_screen.dart
│       ├── help_screen.dart
│       ├── support_screen.dart
│       ├── about_screen.dart
│       ├── privacy_screen.dart
│       └── request_network_screen.dart
├── utils/
│   ├── app_snackbar.dart
│   └── validators.dart
└── widgets/
    ├── polired_logo.dart
    ├── primary_button.dart
    ├── app_text_field.dart
    ├── network_avatar.dart
    └── post_card.dart
```

---

## 4. Dependencias Instaladas

| Paquete | Versión | Uso |
|---|---|---|
| `provider` | ^6.1.5 | Gestión de estado |
| `http` | ^1.6.0 | Peticiones HTTP al backend |
| `socket_io_client` | ^3.1.4 | WebSocket con el backend |
| `shared_preferences` | ^2.5.5 | Persistencia de token y usuario |
| `go_router` | ^17.2.3 | Navegación declarativa con redirects |
| `google_fonts` | ^8.1.0 | Tipografía Inter |
| `flutter_launcher_icons` | ^0.13.1 | Generación de íconos de la app |
| `image_picker` | ^1.2.2 | Selección de foto de perfil desde galería |

---

## 5. Backend — Endpoints Utilizados (Fase 1)

### Base URL

```
http://10.0.2.2:3000/api   (emulador Android)
```

> Para dispositivo físico cambiar a la IP local del servidor en `lib/config/constants.dart`

### Endpoints

| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/auth/login` | Login con email + password |
| `POST` | `/registro-estudiantes` | Crear cuenta nueva |
| `POST` | `/recuperar-password-e` | Enviar email de recuperación |
| `GET` | `/perfil-estudiante` | Obtener datos completos del usuario autenticado (incluye `biografia`) |
| `PATCH` | `/completar/perfil` | Completar perfil: `username`, `fotoPerfil` (base64, opcional) y `biografia` (opcional, máx. 150 caracteres) |
| `PATCH` | `/perfil/username` | Cambiar nombre de usuario (perfil ya completo) |
| `PATCH` | `/estudiante/:id` | Actualizar datos de perfil: `nombre`, `apellido`, `biografia` (máx. 150 caracteres), etc. |
| `GET` | `/redes/listar` | Listar comunidades disponibles |
| `POST` | `/estudiantes/unirse/red` | Unirse a una comunidad específica |
| `POST` | `/estudiantes/publicaciones` | Crear post estándar (Comunidad/Noticias) |
| `POST` | `/publicaciones/articulos` | Crear post de Venta o Cursos pagados |
| `GET` | `/estudiantes/listar/redes` | Listar redes inscritas por el usuario |
| `GET` | `/publicaciones/red/:redId` | Obtener feed filtrado por red (Home) |
| `GET` | `/publicaciones/global` | Feed global (Reservado para Explorar) |
| `GET` | `/notificaciones` | Listar notificaciones del usuario |
| `PATCH` | `/notificaciones/:id/leida` | Marcar notificación como leída |

> Rutas de perfil adicionales declaradas en `lib/config/constants.dart`: `perfilUsernameEndpoint` → `/perfil/username`. La ruta `PATCH /estudiante/:id` se arma en código con el `_id` del usuario autenticado.

### Respuesta del Login

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "usuario": {
    "_id": "...",
    "nombre": "...",
    "apellido": "...",
    "email": "...",
    "roles": ["estudiante"],
    "username": null,
    "fotoPerfil": null,
    "perfilCompleto": false
  }
}
```

**Nota (app móvil):** El objeto `usuario` del login es **reducido** y no incluye `biografia`. Para que la descripción y el resto de campos coincidan siempre con MongoDB, la app llama a `GET /perfil-estudiante` tras iniciar sesión y al restaurar la sesión guardada (ver §9).

### JWT

- Firmado con `JWT_SECRET`, expiración: `1d`
- Payload: `{ id, roles, context }`
- Header: `Authorization: Bearer <token>`

---

## 6. Sistema de Diseño (Tema Claro)

Los tokens fueron extraídos directamente de los HTMLs de referencia proporcionados.

| Token | Valor | Uso |
|---|---|---|
| `background` | `#fbf9f8` | Fondo de pantallas |
| `surfaceContainerLow` | `#f5f3f3` | Fondo de campos de texto |
| `primary` (botones) | `#1D3557` | Botones principales |
| `primaryText` | `#000000` | Títulos "Polired" |
| `onSurface` | `#1b1c1c` | Texto principal |
| `onSurfaceVariant` | `#474747` | Texto secundario |
| `outline` | `#777777` | Bordes y captions |
| `outlineVariant` | `#c6c6c6` | Bordes suaves |
| `error` | `#ba1a1a` | Mensajes de error |

**Fuente:** Inter (Google Fonts)  
**Border radius campos:** 8px (`0.5rem`)

---

## 7. Pantallas Implementadas

### 7.1 Splash Screen

- Fondo blanco, logo centrado (128px circular), nombre "Polired" en azul marino
- Footer: "ECOSISTEMA UNIVERSITARIO"
- Animación: fade + scale de entrada (900ms)
- Navega a `/home` o `/login` a los 2 segundos

### 7.2 Login Screen

- Logo circular 80px + título "Polired" (negro, peso 900)
- Campos: email/usuario, contraseña (con toggle)
- Botón azul marino "Iniciar sesión"
- Link "¿Olvidaste tu contraseña?" → `/forgot-password`
- Línea de acento superior (gradiente)
- Footer fijo: link de registro + copyright
- **UX:** Notificaciones modernas (`AppSnackbar`) para errores de red o credenciales incorrectas.

### 7.3 Register Screen

- Fondo `#f9f9f9`, tarjeta blanca con bordes
- Campos: **nombre**, **apellido**, correo, contraseña, confirmar contraseña
- ⚠️ **Sin username** — se solicita en pantalla post-login (Fase 2)
- Texto legal con referencias a políticas
- Tarjeta secundaria con link a login
- Footer copyright
- **UX:** Registro exitoso muestra mensaje de activación de cuenta y redirige a login tras 2 segundos.

### 7.4 Forgot Password Screen

- AppBar: flecha back + "Polired"
- Logo con esquinas redondeadas (`rounded-2xl`)
- Título "Recupera tu acceso" + descripción
- Campo con etiqueta "CORREO UNIVERSITARIO" y ícono mail
- Botón "Enviar enlace" con ícono flecha →
- Estado de éxito con animación fade (transición suave)
- Link "¿Volver al inicio de sesión?"

### 7.5 Complete Profile Screen

- Se activa tras primer login cuando `perfilCompleto === false`.
- Avatar interactivo con `image_picker` + badge flotante "+".
- Campo obligatorio para **Nombre de Usuario** (mínimo 3 caracteres, validación asíncrona en backend).
- Campo opcional **Descripción** (en API: `biografia`), máximo **150** caracteres, con contador en el campo.
- Botón "Continuar" azul marino (editorial-shadow).
- Conversión de imagen a **Base64** para envío directo en el JSON del patch (`PATCH /completar/perfil`).

### 7.6 Welcome Screen

- Título de bienvenida + descripción de comunidad.
- Listado de **5 redes aleatorias** (obtenidas del backend y mezcladas localmente).
- Contador de selección: obliga a elegir **exactamente 3 redes**.
- Botón "Continuar" que realiza peticiones secuenciales de unión.
- Navegación final a `/home` tras éxito.

### 7.7 Main Layout (Bottom Navigation)

- Implementado como contenedor principal (`Scaffold`) con `IndexedStack` para preservar el estado de las pestañas.
- **BottomNavigationBar:** 5 apartados (Home, Explorar, Publicar, Mensajes, Perfil).
- **Estética:** Glassmorphism/Backdrop Blur (10px) en la barra inferior, sincronizada con el diseño de Threads/Instagram.

### 7.8 Home Screen (Feed Real)

- **Integración con Backend:** El feed ya no utiliza datos mock. Consume publicaciones reales mediante `GET /publicaciones/red/:redId`.
- **TopAppBar:** Efecto blur, botón `add_box`, título "Polired" y acceso a notificaciones (icono búho).
- **Network Stories:** Lista horizontal de las redes del estudiante (`GET /estudiantes/listar/redes`).
    - **Lógica de Filtrado:** Al seleccionar una red, se carga automáticamente su feed específico.
    - **Sin Fallback Global:** Si el usuario no tiene redes o la red seleccionada está vacía, se muestra un estado informativo. No se mezcla con el feed global por arquitectura.
- **Feed:** Lista de `PostCard` que renderiza contenido real (texto e imágenes).
- **UX:** Manejo de estados `loading`, `empty` (sin publicaciones), `error` (fallo de red) y `pull-to-refresh`.

### 7.9 Notifications Screen

- **Diseño Informativo:** Las notificaciones se presentan como una lista cronológica agrupada (Hoy, Esta semana, Anteriormente).
- **Tipos de Notificación:** Soporta `like`, `comentario`, `respuesta_comentario` y `mensaje`.
- **Restricción de Interacción:** Por requerimiento de arquitectura, las notificaciones son **solo informativas**. No son clickeables ni navegan a otras pantallas.
- **Sincronización:** Consume `GET /notificaciones` y muestra el estado real (leída/no leída) mediante indicadores visuales.

### 7.10 Profile Screen

- **Datos Reales:** Integración con `AuthProvider` y `NetworkProvider`. Muestra nombre completo, username en la AppBar y foto real.
- **Descripción:** Si el usuario tiene `biografia` en el modelo (proveniente de la base de datos), se muestra debajo del subtítulo "Estudiante de Polired".
- **Conteo de Redes:** Consumo dinámico de `/estudiantes/listar/redes`.
- **Limpieza de Mocks:** Se eliminó el conteo de publicaciones falso y la cuadrícula de imágenes placeholder.
- **Estado Vacío:** Si el usuario no tiene publicaciones (funcionalidad de "Mis Publicaciones" pendiente en backend), se muestra un estado informativo limpio.
- **Acciones:** Botón de edición de perfil y acceso a configuración.

### 7.11 Add Post Screen (Publicar)

- **Multicategoría:** Soporte para Comunidad, Noticias, Venta y Cursos.
- **Lógica de Redes:** Permite elegir entre las redes suscritas del usuario.
- **Gestión de Multimedia:** Selector de imágenes con previsualización.
- **Sincronización:** Conecta con `POST /estudiantes/publicaciones` y variantes.

### 7.12 Edit Profile Screen

- **Campos:** Nombre, apellido, nombre de usuario y **Descripción** (`biografia` en API), máximo **150** caracteres.
- **Backend:** `PATCH /estudiante/:id` para nombre, apellido y biografía; si el username cambió, `PATCH /perfil/username`; luego `GET /perfil-estudiante` para refrescar el usuario en memoria y en `SharedPreferences`.
- **Diseño:** Inputs minimalistas tipo iOS.

### 7.13 Settings & Secondary Screens
- **Centro de Control:** Gestión de notificaciones, ayuda, soporte y privacidad.
- **Solicitud de Red:** Formulario para proponer nuevas redes académicas.
- **Logout:** Limpieza de `SharedPreferences` y desconexión de Sockets.

---

## 8. Flujo de Navegación

```
/splash
   ├── token guardado → /home
   └── sin token     → /login

/login
   ├── login OK (perfilCompleto=false) → /complete-profile
   ├── login OK (perfilCompleto=true)  → /home
   ├── → /register
   └── → /forgot-password

/complete-profile
   └── éxito → /welcome

/welcome
   └── 3 redes seleccionadas → éxito → /home

/home (MainLayout)
   ├── Index 0: Home / Feed
   ├── Index 1: Explorar (Placeholder)
   ├── Index 2: Publicar (Placeholder)
   ├── Index 3: Mensajes (Placeholder)
   └── Index 4: Perfil
       └── logout (previsto) → /login
```

---

## 9. Persistencia de Sesión

1. Login exitoso → `SharedPreferences.setString('auth_token', jwt)` y usuario parcial del JSON de login.
2. Al iniciar app → `AuthProvider._init()` lee token + user guardados, inyecta el token en `ApiService` y marca sesión autenticada.
3. **Sincronización de perfil:** Tras restaurar sesión y tras cada login exitoso, la app ejecuta `GET /perfil-estudiante` (`AuthService.refreshUserFromPerfil`) y **sobrescribe** el usuario local con la respuesta completa (incluye `biografia`, alineado con MongoDB). Lo mismo ocurre tras completar perfil con éxito. Así se evita que desaparezca la biografía al cerrar y reabrir la app (el login solo devuelve un subconjunto de campos).
4. Logout → `StorageService.clear()` → `AuthStatus.unauthenticated`

### Modelo de usuario (`UserModel`)

- Incluye `biografia` (`String?`) además de `_id`, nombre, apellido, email, roles, `username`, `fotoPerfil` y `perfilCompleto`.

---

## 10. WebSocket

Se inicializa al tener sesión autenticada (tras **login exitoso** o al **restaurar** token y usuario en `_init`):

```dart
socketService.connect(userId);
// Emite: 'usuario:conectar' con el ID del estudiante
```

Los eventos de chat real (`mensaje:privado`, `mensaje:recibido`) se implementarán en Fase 3.

---

## 11. Assets

| Archivo | Ruta |
|---|---|
| Logo de la app | `assets/images/logo_v5.2.png` |

> **Acción realizada:** Configurado como ícono de lanzador para Android e iOS mediante `flutter_launcher_icons`. Nombre de la app actualizado a **"Polired"**.

---

## 12. Validaciones y UX

### Sistema de Notificaciones (`AppSnackbar`)
Implementado en `lib/utils/app_snackbar.dart`, inspirado en Threads/Discord.
- **Éxito (Verde):** Acciones completadas correctamente.
- **Error (Rojo):** Errores de validación o fallos de red. `ApiService` está configurado para parsear tanto mensajes simples (`msg`) como arreglos de errores complejos de `express-validator`, extrayendo la descripción específica del fallo.
- **Info (Azul):** Avisos de sistema (ej. "Cuenta no activada").

### Validaciones (`Validators`)
Centralizadas en `lib/utils/validators.dart`.

#### Login
- Usuario/Email: no vacío.
- Password: no vacío, mínimo 8 caracteres (sincronizado con backend).
- **Manejo de errores:** Detección robusta de cuenta no activada, usuario inexistente y contraseña incorrecta mediante el mapeo exacto de mensajes del backend (`confirma`, `registrado`, `incorrecta`).

#### Registro
- Nombre/Apellido: requerido, solo letras (regex), sincronizado con las restricciones del backend.
- Email: regex estricto de correo electrónico.
- Password: fuerte (mínimo 8 caracteres, 1 mayúscula, 1 número).
- Confirmar password: debe coincidir exactamente.

#### Recuperar contraseña
- Email: requerido, formato válido.
- **UX:** Muestra estado de éxito dentro de la pantalla o error si el correo no se encuentra en la base de datos (mapeo de excepción `registrado`).

#### Completar y editar perfil (descripción)
- Campo **Descripción** / `biografia`: máximo **150** caracteres en cliente y backend; opcional al completar perfil, editable en "Editar perfil".

---

## 13. QA — Resultados

```
flutter analyze → No issues found ✅
```

---

## 14. Decisiones Técnicas

| Decisión | Alternativa | Razón |
|---|---|---|
| Provider | Riverpod / Bloc | Menor complejidad |
| GoRouter | Navigator 2.0 | Redirects de auth declarativos |
| `package:http` | Dio | Suficiente para la escala |
| Tema claro | Tema oscuro | Los HTMLs de referencia son light |
| DI manual | GetIt | Evitar overhead |
| `10.0.2.2` | `localhost` | IP del host en emulador Android |
| Refresco de perfil tras login e `_init` | Confiar solo en el JSON del login | El backend no envía `biografia` en el login; sin `GET /perfil-estudiante` la descripción se perdía al guardar sesión |

---

## 15. Pendiente — Fase 2 (Continuación)

- [x] Pantalla completar perfil (username + foto + descripción / `biografia`, máx. 150 caracteres)
- [x] Pantalla bienvenida (elección de redes)
- [x] Home Screen con feed dinámico por red (Datos Reales)
- [x] Bottom NavBar con 5 apartados y glassmorphism
- [x] Profile Screen dinámica sin mocks (muestra `biografia` cuando existe en el servidor)
- [x] Pantalla "Agregar Publicación" (Integrada)
- [x] Centro de Configuración y Subpantallas
- [x] Pantalla "Editar Perfil" (persistencia real: `PATCH /estudiante/:id`, username vía `/perfil/username`, refresco con `GET /perfil-estudiante`)
- [x] Integración de Notificaciones Informativas
- [ ] Implementación de funcionalidades de interacción (Likes/Comentarios reales)
- [ ] Implementación de flujo de Chat y Mensajería (Socket.io)
- [ ] Sección "Explorar" con Feed Global por categorías (Noticias, Ventas, Cursos)

---

*Documento actualizado progresivamente con cada fase del desarrollo.*
