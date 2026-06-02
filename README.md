<div align="center">
  <h1>PoliRed Mobile App</h1>
  <p><strong>Red Social Universitaria para Comunidades Académicas</strong></p>

  ![Flutter](https://img.shields.io/badge/Flutter-%5E3.10.1-02569B?style=flat&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-Enabled-0175C2?style=flat&logo=dart&logoColor=white)
  ![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS-lightgrey)
  ![Arquitectura](https://img.shields.io/badge/Arquitectura-CQRS%20%2B%20Provider-success)
</div>

---

## 📖 Descripción

**PoliRed** es una aplicación móvil desarrollada en Flutter diseñada para transformar la manera en la que los estudiantes interactúan en su ecosistema universitario. El objetivo de la plataforma es crear redes académicas y sociales seguras, permitiendo a los usuarios descubrir comunidades, consumir noticias relevantes, acceder a cursos y participar en un marketplace exclusivo.

El cliente (Frontend) consume los servicios del `BackendV2`, el cual provee un robusto ecosistema de APIs para autenticación, mensajería en tiempo real, feeds dinámicos y publicaciones.

## ✨ Características Principales

- 🔐 **Autenticación Segura:** Manejo de sesiones persistentes con JWT.
- 🌐 **Feeds Dinámicos:** Feed global y feeds segregados por comunidad/red.
- 🔍 **Módulo Explore:** Categorización inteligente en Noticias, Marketplace y Cursos.
- 📝 **Gestión de Contenido:** Creación de publicaciones estándar y artículos transaccionales.
- 👤 **Perfiles Personalizables:** Biografía, foto de perfil y métricas.
- 💬 **Mensajería en Tiempo Real:** Integración con WebSocket (Pusher) para actualización síncrona de chats y notificaciones.
- 🗺️ **Geolocalización:** Despliegue de mapas interactivos utilizando Mapbox.

## 🏗️ Arquitectura del Proyecto

El proyecto sigue una arquitectura limpia orientada por capas y hace uso de patrones de diseño empresariales:

- **Manejo de Estado (`provider`)**: Uso extensivo de `ChangeNotifierProxyProvider` para componer dependencias reactivas.
- **Patrón CQRS**: Separación de las operaciones de lectura (Query) y escritura (Command) a través de un `CommandBus` (`PostStoreProvider`), garantizando un estado atómico sin renders innecesarios.
- **Inyección de Dependencias**: Inicialización centralizada de servicios en `main.dart`.
- **Enrutamiento Seguro**: Uso de `go_router` con guards de autenticación que interceptan y redirigen flujos no autorizados.

### Estructura de Capas
- **`ApiService`**: Wrapper HTTP con manejo centralizado de excepciones y headers.
- **`AuthProvider`**: Gestión del ciclo de vida de la sesión de usuario.
- **`PostService`**: Orquestador principal de publicaciones.
- **`SocketService`**: Conexiones Pub/Sub para chat y notificaciones.

## 🚀 Guía de Inicio Rápido (Local)

### Requisitos Previos
- SDK de Flutter compatible (`^3.10.1`).
- Dispositivo físico o emulador (Android SDK / iOS Simulator).
- Acceso a `BackendV2` (ya sea localmente o mediante la URL de producción).

### Instalación
1. Abre tu terminal en la carpeta principal del proyecto:
   ```bash
   cd app_polired
   ```
2. Instala las dependencias de Flutter:
   ```bash
   flutter pub get
   ```
3. Verifica la configuración en `lib/config/constants.dart`.
   - *Nota:* Para emuladores Android usando un backend local, utiliza `http://10.0.2.2:3000/api`. En dispositivos físicos, usa tu IP de red local o la de producción.

### Ejecución
Para compilar y correr el proyecto en el dispositivo activo:
```bash
flutter run
```
Para ejecutar el analizador estático y verificar la calidad del código:
```bash
flutter analyze
```

## 📚 Documentación Técnica

Para conocer a fondo las decisiones arquitectónicas, estructura de archivos y análisis del código, consulta el reporte técnico oficial:
👉 **[Informe Técnico de PoliRed](informe_tecnico_polired.md)**

## 📡 Endpoints Destacados

PoliRed interactúa con diversas rutas del servidor. Todas las rutas protegidas requieren enviar el token JWT en el header (`Authorization: Bearer <token>`):

- `POST /auth/login` | `GET /perfil-estudiante`
- `GET /redes/listar` | `POST /estudiantes/unirse/red`
- `GET /publicaciones/global` | `GET /publicaciones/articulos/global`
- `POST /estudiantes/publicaciones` | `POST /publicaciones/articulos`

---
