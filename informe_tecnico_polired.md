# Informe Técnico Completo — Polired Mobile App

> **Versión:** 1.0 — Fase 1 (Auth)  
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
        └── AuthProvider
              ├── AuthService  ──► ApiService  ──► Backend HTTP
              └── SocketService ──► Backend Socket.IO
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
│   └── user_model.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── socket_service.dart
│   └── storage_service.dart
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   └── home/
│       └── home_screen.dart
└── widgets/
    ├── polired_logo.dart
    ├── primary_button.dart
    └── app_text_field.dart
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

### 7.3 Register Screen

- Fondo `#f9f9f9`, tarjeta blanca con bordes
- Campos: **nombre**, **apellido**, correo, contraseña, confirmar contraseña
- ⚠️ **Sin username** — se solicita en pantalla post-login (Fase 2)
- Texto legal con referencias a políticas
- Tarjeta secundaria con link a login
- Footer copyright

### 7.4 Forgot Password Screen

- AppBar: flecha back + "Polired"
- Logo con esquinas redondeadas (`rounded-2xl`)
- Título "Recupera tu acceso" + descripción
- Campo con etiqueta "CORREO UNIVERSITARIO" y ícono mail
- Botón "Enviar enlace" con ícono flecha →
- Estado de éxito con animación fade (transición suave)
- Link "¿Volver al inicio de sesión?"

---

## 8. Flujo de Navegación

```
/splash
   ├── token guardado → /home
   └── sin token     → /login

/login
   ├── login OK      → /home
   ├── → /register
   └── → /forgot-password

/register
   └── éxito → dialog → /login

/forgot-password
   └── envío OK → estado éxito (in-screen)
   └── volver   → /login

/home
   └── logout → /login
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

> **Acción requerida:** Copiar `logo_v5.2.png` a `polired/assets/images/`

---

## 12. Validaciones por Pantalla

### Login
- Email: no vacío
- Password: no vacío, mínimo 6 caracteres

### Registro
- Nombre: requerido, mínimo 2 caracteres
- Apellido: requerido, mínimo 2 caracteres
- Email: regex `^[\w\.\+\-]+@[\w\-]+\.\w{2,}$`
- Password: mínimo 6 caracteres
- Confirmar password: debe coincidir

### Recuperar contraseña
- Email: requerido, formato válido

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

## 15. Pendiente — Fase 2

- [ ] Pantalla completar perfil (username + foto) — se muestra una sola vez tras primer login cuando `perfilCompleto === false`
- [ ] Home Screen con feed de publicaciones
- [ ] Tabs: Home, Explorar, Publicar, Mensajes, Perfil
- [ ] API: cargar y crear publicaciones

---

*Documento actualizado progresivamente con cada fase del desarrollo.*
