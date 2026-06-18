/// Responsabilidad principal:
/// Clase estática que provee funciones puras para validar inputs de formularios (RegEx para emails, contraseñas, etc).
///
/// Flujo dentro de la app:
/// Utilizado directamente por los atributos `validator:` en TextFormField o variables de estado de UI.
///
/// Dependencias críticas:
/// - Ninguna (puro Dart).
///
/// Side Effects:
/// - Ninguno. Funciones 100% puras sin mutación.
///
/// Recordatorios técnicos y CQRS:
/// - Mantener aislado de contexto y estado; ideal para Unit Testing.
class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    if (!value.trim().endsWith('@epn.edu.ec')) {
      return 'El correo debe terminar en @epn.edu.ec';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una letra mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? name(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return '$label solo puede contener letras';
    }
    return null;
  }
}
