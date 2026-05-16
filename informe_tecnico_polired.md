# Informe Técnico Completo — Polired Mobile App

> **Versión:** 1.9 — Integración de publicaciones estándar y flujo de artículos de venta (BackendV2)  
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
        ├── Provider<ApiService>
        ├── Provider<SocketService>
        ├── Provider<NetworkService>
        ├── AuthProvider
        │     ├── AuthService  ──► ApiService  ──► Backend HTTP
        │     └── SocketService ──► Backend Socket.IO (JWT en handshake)
        ├── NetworkProvider
        │     └── NetworkService ──► ApiService ──► Backend HTTP
        ├── NotificationProvider
        └── MessagesInboxProvider (ChangeNotifierProxyProvider<AuthProvider, …>)
              ├── ConversationsRepository ──► ApiService
              ├── NetworkService
              └── SocketService
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
│   ├── post_model.dart
│   ├── conversation_model.dart
│   └── suggested_network_model.dart
├── repositories/
│   └── conversations_repository.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── network_service.dart
│   ├── socket_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── network_provider.dart
│   ├── notification_provider.dart
│   └── messages_inbox_provider.dart
├── screens/
│   ├── main_layout_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── messages/
│   │   └── messages_screen.dart
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
│   ├── validators.dart
│   ├── network_acronym.dart
│   └── json_ids.dart
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
| `GET` | `/mensajes/conversaciones` | Listar conversaciones 1:1 del usuario autenticado (`{ conversaciones }`) |
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

- **Multicategoría y Rutas Diferenciadas:** Soporta creación de publicaciones estándar (Comunidad, Noticias, Cursos) y artículos de Venta, dirigiendo cada tipo al endpoint del backend correspondiente.
- **Formularios Dinámicos:** Muestra campos específicos según la categoría elegida; por ejemplo, solicita el campo **Precio** dinámicamente solo para publicaciones de categoría Venta.
- **Lógica de Redes y Validación:** Carga las redes a las que el estudiante se ha unido. Valida estrictamente la selección de una red cuando se trata de la categoría Comunidad.
- **Integración Segura con ApiService:** Utiliza la instancia global inyectada de `ApiService` con JWT de autenticación para evitar errores 401.
- **Robustez y UX:** Controla los estados de carga con un indicador `_isLoading` y gestiona las respuestas de éxito y error mediante alertas visuales con `AppSnackbar`.

### 7.12 Edit Profile Screen

- **Campos:** Nombre, apellido, nombre de usuario y **Descripción** (`biografia` en API), máximo **150** caracteres.
- **Backend:** `PATCH /estudiante/:id` para nombre, apellido y biografía; si el username cambió, `PATCH /perfil/username`; luego `GET /perfil-estudiante` para refrescar el usuario en memoria y en `SharedPreferences`.
- **Diseño:** Inputs minimalistas tipo iOS.

### 7.13 Settings & Secondary Screens
- **Centro de Control:** Gestión de notificaciones, ayuda, soporte y privacidad.
- **Solicitud de Red:** Formulario para proponer nuevas redes académicas.
- **Logout:** Limpieza de `SharedPreferences` y desconexión de Sockets.

### 7.14 Messages Screen (Bandeja de conversaciones)

- **Layout:** Header con `@username`, buscador deshabilitado (solo UI), banner de estado del socket, carrusel horizontal de “historias” (usuario + redes del estudiante), lista de conversaciones, sección “Redes para seguir”.
- **Datos:** `GET /mensajes/conversaciones`, `GET /estudiantes/listar/redes`, `GET /redes/listar`, `POST /estudiantes/unirse/red`; actualización en vivo vía `mensaje:nuevo` y `mensaje:enviado` (`MessagesInboxProvider` + `SocketService`).
- **Estados:** carga con skeleton animado, vacío, error con reintentar, banner para `connecting` / `reconnecting` / `disconnected`.
- **Sugerencias:** hasta 10 redes aleatorias no unidas, sin repetir en la sesión; al cerrar todas con “X” se genera un nuevo lote. “Seguir” llama al endpoint real de unión a red.
- **Pendiente explícito:** pantalla de chat individual, envío de mensajes y navegación al detalle (no implementado en esta fase).

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
   ├── Index 3: Mensajes (lista de conversaciones + redes + sugerencias)
   └── Index 4: Perfil
       └── logout (previsto) → /login
```

---

## 9. Persistencia de Sesión

1. Login exitoso → `SharedPreferences.setString('auth_token', jwt)` y usuario parcial del JSON de login.
2. Al iniciar app → `AuthProvider._init()` lee token + user guardados, inyecta el token en `ApiService` y marca sesión autenticada.
3. **Sincronización de perfil:** Tras restaurar sesión y tras cada login exitoso, la app ejecuta `GET /perfil-estudiante` (`AuthService.refreshUserFromPerfil`) y **sobrescribe** el usuario local con la respuesta completa (incluye `biografia`, alineado con MongoDB). Lo mismo ocurre tras completar perfil con éxito. Así se evita que desaparezca la biografía al cerrar y reabrir la app (el login solo devuelve un subconjunto de campos).
4. Logout → `StorageService.clear()` → `AuthStatus.unauthenticated` → `SocketService.disconnect()` y `MessagesInboxProvider` limpia sesión vía `ChangeNotifierProxyProvider`.

### Modelo de usuario (`UserModel`)

- Incluye `biografia` (`String?`) además de `_id`, nombre, apellido, email, roles, `username`, `fotoPerfil` y `perfilCompleto`.

---

## 10. WebSocket (Socket.IO)

### Autenticación

El backend (`BackendV2/src/socket.js`) valida el JWT en el **handshake**:

- `socket.handshake.auth.token`, o
- Cabecera `Authorization: Bearer <token>`.

La app móvil envía el mismo token que las peticiones HTTP mediante `OptionBuilder().setAuth({'token': jwt})`. **No** se emite ningún evento de registro adicional (el antiguo `usuario:conectar` del cliente no existe en el servidor).

### Reconexión y estados en UI

`SocketService` expone `ValueNotifier<SocketConnectionPhase>` (`disconnected`, `connecting`, `connected`, `reconnecting`) escuchando también los eventos internos del manager (`reconnect_attempt`, `reconnect`, `reconnect_failed`).

### Eventos utilizados en la bandeja (solo lectura)

| Dirección | Evento | Uso en la app |
|---|---|---|
| Servidor → cliente | `mensaje:nuevo` | Actualizar preview y orden de la conversación en la lista |
| Servidor → cliente | `mensaje:enviado` | Igual (mensaje propio cuando el socket no estaba en la room) |
| Servidor → cliente | `usuario:online` / `usuario:offline` | **No** usados en UI (fase actual) |
| Servidor → cliente | `chat:error` | **No** suscrito en la bandeja (solo errores de `join` / envío) |

La carga inicial de conversaciones es **HTTP**: `GET /mensajes/conversaciones`. Los eventos anteriores mantienen la lista al día cuando alguien envía vía WebSocket (`mensaje:enviar` en servidor). Los mensajes enviados **solo** por HTTP **no** disparan estos eventos en el backend actual.

### Limitaciones conocidas del backend (mensajería)

- **Sin contador de no leídos ni recibos:** el listado HTTP no incluye `unreadCount`. La app muestra un indicador aproximado: mensajes entrantes por socket o último mensaje cuyo `autorId` no es el usuario actual.
- **`GET /redes/listar`** solo devuelve `nombre`, `descripcion`, `cantidadMiembros`, `esOficial`, `esVerificada` (sin `fotoPerfil`). Las tarjetas de sugerencias usan siglas en el círculo.
- **`GET /estudiantes/listar/redes`** hace populate con `nombre` y `descripcion` solamente: en la práctica **no** llega `fotoPerfil` de la red; las historias circulares usan imagen solo si el backend amplía el `select` en el futuro (la app ya contempla fallback por siglas).

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
- [x] Bandeja de Mensajes: lista de conversaciones (HTTP + actualización socket), redes del usuario, sugerencias de redes y estados de conexión WebSocket
- [ ] Pantalla de chat 1:1 (historial `GET /mensajes/conversaciones/:id`, `join:conversacion`, envío `mensaje:enviar` / HTTP según fase)
- [ ] Implementación de funcionalidades de interacción (Likes/Comentarios reales)
- [ ] Sección "Explorar" con Feed Global por categorías (Noticias, Ventas, Cursos)

---

## 16. Normalización de Identificadores (MongoDB Compatibility)

Para garantizar la compatibilidad con el backend (que expone identificadores tanto como `_id` como `id` según el endpoint), se implementó un sistema de normalización centralizado en `lib/utils/json_ids.dart`.

### Problema Identificado
En fases anteriores, el cliente esperaba exclusivamente `_id`. Esto causaba:
- Identificadores vacíos en `SuggestedNetworkModel` cuando el backend devolvía `id`.
- Filtrado erróneo de sugerencias (se omitían redes con `id` en lugar de `_id` debido a validaciones de `isEmpty`).
- Fallos en la pantalla de bienvenida y al unirse a redes (envío de `redId` vacío al backend).

### Solución: `parseMongoId` y `parseMongoIdFromMap`
Se rediseñó la lógica de parsing para ser extremadamente robusta:
- **`parseMongoId`**: 
    - Realiza `trim()` automático a strings.
    - Rechaza strings vacíos.
    - Admite tipos `int`.
    - Soporta mapas complejos (objetos con `$oid` de MongoDB).
    - Evita el uso de `.toString()` sobre mapas arbitrarios para prevenir basura visual como ID.
- **`parseMongoIdFromMap`**: 
    - Intenta obtener el ID buscando en orden de prioridad (configurable, por defecto `_id` -> `id`).
    - Reutiliza `parseMongoId` para manejar los valores encontrados de forma recursiva o anidada.

### Impacto en el Código
- **Modelos:** `SuggestedNetworkModel` ahora utiliza `parseMongoIdFromMap`, permitiendo que el pool de sugerencias se llene correctamente sin importar el formato de la respuesta.
- **Servicios:** `NetworkService.getRedesEstudianteStories` normaliza cada entrada y omite aquellas sin ID válido, previniendo errores en el feed. Se añadió validación previa en `unirseRed`.
- **Providers:** `NetworkProvider.unirseRedes` ahora limpia, normaliza y deduplica los IDs antes de procesar las uniones, devolviendo errores claros si no hay IDs válidos.
- **UI:** En `WelcomeScreen`, se restauró la validación obligatoria de 3 redes y se eliminó cualquier bypass de navegación. Los ítems sin ID válido simplemente no se renderizan para mantener la integridad de la interfaz.

---

## 17. Flujo de Publicaciones y Corrección de Ventas (BackendV2 Integration)

Para alinear el comportamiento del frontend con los requerimientos reales del backend (`BackendV2`) y evitar fallos de autorización (401) y campos faltantes, se realizó una reestructuración profunda en el módulo de creación de publicaciones.

### 17.1 Problemas Detectados en el Flujo Original
1. **Pérdida de Autorización:** La pantalla `AddPostScreen` instanciaba un `ApiService` local (`new ApiService()`) en lugar de heredar el singleton global. Al no contar con el JWT cargado, las solicitudes fallaban con código de error **401 Unauthorized**.
2. **Formulario Incompleto:** Al enviar publicaciones de tipo Comunidad, Noticias o Cursos a `POST /estudiantes/publicaciones`, no se enviaba el parámetro obligatorio `categoria` en el cuerpo de la petición.
3. **Categorías no soportadas en Post Estándar:** El backend no permite crear publicaciones de categoría `Venta` mediante el endpoint de estudiantes estándar (`POST /estudiantes/publicaciones`).
4. **Flujo de Multimedia Incompatible:** El backend de ventas espera un flujo de carga de imágenes e información que difiere del flujo basado en Base64 tradicional para posts estándar.

---

### 17.2 Solución y Correcciones Implementadas

#### A. Reutilización del Servicio Global
- Se modificó `AddPostScreen` para que obtenga e inyecte la instancia global y autenticada de `ApiService` a través de `Provider`:
  ```dart
  PostService(context.read<ApiService>())
  ```
  Esto garantiza que el encabezado `Authorization: Bearer <token>` se envíe de manera consistente en todas las peticiones de creación de posts y artículos.

#### B. Separación de Rutas por Categoría (Estándar vs. Artículos de Venta)
1. **Publicaciones Estándar (Comunidad, Noticias, Cursos)**
   - **Endpoint:** `POST /estudiantes/publicaciones`
   - **Campos enviados:** `titulo`, `contenido`, `categoria` (comunidad, noticias, cursos) y `comunidadId` (requerido únicamente si la categoría es Comunidad).
   - Se removió la interfaz y el soporte de campos no estructurados (ventas/cursos de pago) en este endpoint.
   
2. **Artículos de Venta**
   - **Endpoint:** `POST /publicaciones/articulos`
   - **Campos enviados:**
     - `titulo`
     - `descripcion`
     - `precio` (campo numérico añadido dinámicamente en la UI al seleccionar la categoría "Venta")
     - `comunidadId` (opcional)
     - `imagen` (incluida automáticamente por `PostService` si se selecciona un archivo)
     - `categoria`: `'venta'`

#### C. Cambios en Archivos Clave

| Archivo | Rol de la Corrección |
|---|---|
| `lib/screens/post/add_post_screen.dart` | - Remoción de lógicas visuales de venta/cursos de pago no estructuradas del flujo estándar.<br>- Adición dinámica del campo **Precio** únicamente cuando la categoría seleccionada es **Venta**.<br>- Validación estricta de selección de comunidad para la categoría **Comunidad**.<br>- Gestión de estado de carga (`_isLoading`) para prevenir envíos duplicados.<br>- Manejo robusto de errores mediante `AppSnackbar` (incluyendo respuestas 400 y 401). |
| `lib/services/post_service.dart` | - Actualización del método `createPost` para incluir correctamente el campo `categoria` en el body de la petición HTTP.<br>- Implementación/Mapeo de `createArticle` para redirigir las publicaciones de venta a su endpoint dedicado (`POST /publicaciones/articulos`). |

---

### 17.3 Validación Técnica y Resultados
- **Análisis de Código:** Ejecución de validaciones de análisis estático:
  ```bash
  flutter analyze lib/screens/post/add_post_screen.dart lib/services/post_service.dart
  ```
  **Resultado:** `No issues found! ✅` sin advertencias de tipos, imports o sintaxis.
- **Funcionamiento Real:** Las publicaciones de tipo Comunidad, Noticias y Cursos ahora persisten de forma inmediata en el backend real `BackendV2`. Las publicaciones de Venta se crean exitosamente en el módulo de artículos de venta utilizando su correspondiente tabla y validaciones, retornando respuestas estructuradas al cliente.

---

*Documento actualizado progresivamente con cada fase del desarrollo.*
