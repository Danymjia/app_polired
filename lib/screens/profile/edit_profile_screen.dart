import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/image_compression.dart';
import '../../widgets/safe_network_image.dart';
import 'update_password_screen.dart';

/// Responsabilidad principal:
/// Formulario para actualizar la información personal del usuario logueado (Nombre, Bio, Foto).
///
/// Flujo dentro de la app:
/// Accesible desde la pantalla de Perfil Propio.
///
/// Dependencias críticas:
/// - `AuthProvider` (para obtener datos actuales y despachar la actualización).
/// - `ImagePicker` y compresión de imagen (para captura y optimización de imagen).
///
/// Side Effects:
/// - Sube la nueva foto de perfil al backend y actualiza los datos del usuario en la BD.
///
/// Recordatorios técnicos y CQRS:
/// - La imagen se comprime antes de enviarse para ahorrar ancho de banda y almacenamiento en el servidor.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isProcessingImage = false;

  Future<void> _pickImage() async {
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {

        final originalFile = File(pickedFile.path);
        final compressedFile = await compressProfileImageFile(originalFile);

        if (mounted) {
          setState(() {
            _imageFile = compressedFile ?? originalFile;
          });
        }
      }
    } catch (e, stack) {
      debugPrint('[EditProfileScreen] Error al procesar imagen: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo procesar la imagen. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.biografia ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isProcessingImage) return;

    setState(() {
      _isLoading = true;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.actualizarPerfil(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      username: _usernameController.text,
      biografia: _bioController.text,
      imageFile: _imageFile,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'No se pudo actualizar el perfil'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    String initials = '';
    if (user != null) {
      if (user.nombre.isNotEmpty) initials += user.nombre[0].toUpperCase();
      if (user.apellido.isNotEmpty) initials += user.apellido[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 100,
        leading: TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading || _isProcessingImage ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Listo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar y Botón
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceContainerHighest,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : (user?.fotoPerfil != null &&
                                      user!.fotoPerfil!.trim().isNotEmpty
                                  ? SafeNetworkImage(
                                      url: user.fotoPerfil,
                                      fit: BoxFit.cover,
                                      errorWidget: _buildInitialsAvatar(initials),
                                    )
                                  : _buildInitialsAvatar(initials)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cambiar foto de perfil'),
                    ),
                  ],
                ),
              ),

              // Formulario
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInputField('Nombre', _nombreController),
                    const SizedBox(height: 16),
                    _buildInputField('Apellido', _apellidoController),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Nombre de usuario',
                      _usernameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        if (value.length < 3) return 'Mínimo 3 caracteres';
                        if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value)) {
                          return 'Caracteres no válidos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextAreaField('Descripción', _bioController),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Actualizar contraseña button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpdatePasswordScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerLow,
                      foregroundColor: AppTheme.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: const Text(
                      'Actualizar contraseña',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer Note
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Toda la información se maneja bajo las políticas de privacidad de Polired. Los cambios son visibles para toda la comunidad académica.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.outline,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: AppTheme.primaryText,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            validator:
                validator ??
                (value) => value!.trim().isEmpty ? 'Requerido' : null,
            style: const TextStyle(fontSize: 15, color: AppTheme.onSurface),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            maxLength: 150,
            validator: (value) {
              final v = value ?? '';
              if (v.length > 150) return 'Máximo 150 caracteres';
              return null;
            },
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.onSurface,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: 'Escribe algo sobre ti…',
              hintStyle: TextStyle(color: Color(0xFFDCD9D9)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
