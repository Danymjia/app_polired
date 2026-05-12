# Informe Técnico Completo — Polired Mobile App

> **Versión:** 1.3 — Fase 3 (Publicación, Edición y Configuración)  
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
| `GET` | `/perfil-estudiante` | Obtener datos del usuario (con token) |
| `PATCH` | `/completar/perfil` | Guardar username y foto (base64) |
| `GET` | `/redes/listar` | Listar comunidades disponibles |
| `POST` | `/estudiantes/unirse/red` | Unirse a una comunidad específica |
| `POST` | `/estudiantes/publicaciones` | Crear post estándar (Comunidad/Noticias) |
| `POST` | `/publicaciones/articulos` | Crear post de Venta o Cursos pagados |

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
- Botón "Continuar" azul marino (editorial-shadow).
- Conversión de imagen a **Base64** para envío directo en el JSON del patch.

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

### 7.8 Home Screen (Feed)

- **TopAppBar:** Efecto blur, botón `add_box`, título "Polired" y acciones (`map`, `favorite_border`).
- **Network Stories:** Lista horizontal de redes.
    - Si es miembro: Borde degradado activo.
    - Si no es miembro: Badge "+" para invitar a unirse.
    - Interacción: Al seleccionar una red, el feed se filtra automáticamente.
- **Feed:** Lista de `PostCard` con soporte para imágenes, likes, comentarios y tiempo transcurrido.
- **UX:** Manejo de estados de carga (`CircularProgressIndicator`) y estado vacío (`EmptyFeedState`).

### 7.9 Profile Screen

- Diseño tipo Instagram minimalista.
- **Header Dinámico:** Integración con `AuthProvider` para mostrar nombre real, username y foto.
- **Avatar con Iniciales:** Lógica de fallback que genera un avatar con las iniciales del usuario si no hay foto de perfil cargada.
- **Edit Button:** Acceso directo a `EditProfileScreen`.
- **Settings Button:** Ícono de 3 puntos que abre el centro de configuración.
- **Tabs:** Selector visual entre cuadrícula de fotos (`grid_on`) y vídeos (`video_library`).
- **Post Grid:** Cuadrícula de 3 columnas para visualización rápida de contenido.

### 7.10 Add Post Screen (Publicar)

- **Multicategoría:** Soporte para Comunidad, Noticias, Venta y Cursos.
- **Lógica de Redes:**
    - Categoría "Comunidad": Permite elegir entre Red Global o redes suscritas.
    - Otras categorías: Forzadas a Red Global (Network ID null).
- **Gestión de Multimedia:** Selector de hasta 5 imágenes con previsualización en carrusel horizontal.
- **Cursos:** Toggle dinámico entre "Gratis" y "Paga" con campo de precio condicional.
- **Validaciones:** Botón de publicar habilitado solo tras aceptar políticas de privacidad y completar campos obligatorios.

### 7.11 Edit Profile Screen

- **Estética iOS:** Diseño minimalista con bordes inferiores (`ios-input-border`).
- **Campos:** Edición de Nombre, Apellido, Username y Presentación (Bio).
- **Regla de Negocio (Username):** Preparado para validar cambio de nombre de usuario cada 30 días (lógica de control en backend requerida).

### 7.12 Settings & Secondary Screens

- **Centro de Control:** Acceso centralizado a interacción, ajustes y soporte.
- **Notificaciones:** Gestión de preferencias (Push y Email) mediante toggles.
- **Ayuda & FAQ:** Listado de preguntas frecuentes con navegación a guías detalladas.
- **Asistencia:** Formulario de reporte de problemas con selección de categoría y descripción técnica.
- **Información & Privacidad:** Despliegue de términos legales y detalles de versión (v2.4.0).
- **Solicitud de Red:** Formulario especializado para proponer nuevos nodos académicos (EPN watermark design).
- **Logout:** Cierre de sesión funcional con limpieza de almacenamiento y redirección a login.

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

1. Login exitoso → `SharedPreferences.setString('auth_token', jwt)`
2. Al iniciar app → `AuthProvider._init()` lee token + user guardados
3. Si válidos → `AuthStatus.authenticated` + `ApiService.setToken(token)`
4. Logout → `StorageService.clear()` → `AuthStatus.unauthenticated`

---

## 10. WebSocket

Se inicializa al hacer login exitoso:

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

---

## 15. Pendiente — Fase 2 (Continuación)

- [x] Pantalla completar perfil (username + foto)
- [x] Pantalla bienvenida (elección de redes)
- [x] Home Screen con feed dinámico por red (Mock Data)
- [x] Bottom NavBar con 5 apartados y glassmorphism
- [x] Profile Screen dinámica con iniciales y datos reales
- [x] Pantalla "Agregar Publicación" con lógica de categorías y multimedia
- [x] Centro de Configuración y Subpantallas (Ayuda, Privacidad, etc.)
- [x] Pantalla "Editar Perfil" con diseño iOS
- [ ] Integración real de API para carga de posts
- [ ] Implementación de funcionalidades de interacción (Likes/Comentarios)

---

*Documento actualizado progresivamente con cada fase del desarrollo.*
