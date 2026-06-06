import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/network_service.dart';
import '../../providers/network_profile_provider.dart';

class NetworkVerificationScreen extends StatefulWidget {
  final String redId;
  
  const NetworkVerificationScreen({super.key, required this.redId});

  @override
  State<NetworkVerificationScreen> createState() => _NetworkVerificationScreenState();
}

class _NetworkVerificationScreenState extends State<NetworkVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final profileProvider = context.read<NetworkProfileProvider>();
    if (profileProvider.profile?.id != widget.redId) {
      // isMember doesn't matter much for these forms, assuming true as admin
      profileProvider.loadProfile(widget.redId, isMember: true);
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  String? _validateCorreo(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'El correo institucional es obligatorio';
    if (!RegExp(r'^[^\s@]+@epn\.edu\.ec$').hasMatch(val.toLowerCase())) {
      return 'El correo debe ser institucional (@epn.edu.ec)';
    }
    return null;
  }

  Future<void> _submit(String nombreRed, String fechaCreacionRed, int cantidadMiembros) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final networkService = context.read<NetworkService>();
      final result = await networkService.solicitarVerificacionRed(
        redId: widget.redId,
        nombreRed: nombreRed,
        fechaCreacionRed: fechaCreacionRed,
        cantidadMiembros: cantidadMiembros,
        correoInstitucional: _correoCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Solicitud enviada exitosamente!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Error al enviar solicitud', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We must use context.watch to rebuild when the provider updates the state.
    final profileProvider = context.watch<NetworkProfileProvider>();
    final profile = profileProvider.profile;
    
    if (profileProvider.status == NetworkProfileStatus.loading || profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceContainerLowest,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileProvider.status == NetworkProfileStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profileProvider.errorMessage ?? 'Error al cargar red'),
              ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Solicitud de Verificación',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Section
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.verified_user, size: 40, color: Color(0xFF1D3557)),
                    Positioned(
                      bottom: 0,
                      right: -4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(Icons.grade, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verificación de Red',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF485f84)),
              ),
              const SizedBox(height: 8),
              Text(
                'Obtén la insignia azul y el reconocimiento oficial institucional.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              
              // Basic Info
              Align(
                alignment: Alignment.centerLeft,
                child: Text('INFORMACIÓN DE LA RED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline, letterSpacing: 2)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Nombre'), Text(profile.nombre, style: const TextStyle(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Miembros Totales'), Text(profile.cantidadMiembros.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              // Eligibility Check
              Align(
                alignment: Alignment.centerLeft,
                child: Text('REQUISITOS DE ELEGIBILIDAD', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline, letterSpacing: 2)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12)),
                child: Builder(
                  builder: (context) {
                    final createdDate = profile.createdAt != null ? DateTime.tryParse(profile.createdAt!)?.toLocal() : null;
                    final int? diasDeVida = createdDate != null ? DateTime.now().difference(createdDate).inDays : null;
                    final bool cumpleDias = (diasDeVida ?? 0) >= 30;
                    final bool cumpleMiembros = profile.cantidadMiembros >= 30;

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(cumpleDias ? Icons.check_circle : Icons.cancel, color: cumpleDias ? Colors.green : AppTheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Antigüedad mínima de 30 días', style: TextStyle(fontWeight: FontWeight.bold, color: cumpleDias ? AppTheme.onSurface : AppTheme.error)),
                                  Text(diasDeVida != null ? 'La red tiene $diasDeVida días de antigüedad.' : 'Fecha no disponible', style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(cumpleMiembros ? Icons.check_circle : Icons.cancel, color: cumpleMiembros ? Colors.green : AppTheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mínimo 30 miembros activos', style: TextStyle(fontWeight: FontWeight.bold, color: cumpleMiembros ? AppTheme.onSurface : AppTheme.error)),
                                  Text('La red tiene ${profile.cantidadMiembros} miembros.', style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
              ),
              
              const SizedBox(height: 32),
              // Institutional Validation
              Align(
                alignment: Alignment.centerLeft,
                child: Text('VALIDACIÓN INSTITUCIONAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline, letterSpacing: 2)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoCtrl,
                enabled: !_isSubmitting,
                validator: _validateCorreo,
                decoration: InputDecoration(
                  hintText: 'nombre@epn.edu.ec',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.outline),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info, size: 14, color: Color(0xFFD62828)),
                  const SizedBox(width: 8),
                  Text('Debe terminar en el dominio oficial de la universidad.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Builder(
                  builder: (context) {
                    final createdDate = profile.createdAt != null ? DateTime.tryParse(profile.createdAt!)?.toLocal() : null;
                    final int? diasDeVida = createdDate != null ? DateTime.now().difference(createdDate).inDays : null;
                    final bool cumple = (diasDeVida != null && diasDeVida >= 30) && profile.cantidadMiembros >= 30;

                    return ElevatedButton(
                      onPressed: (_isSubmitting || !cumple) ? null : () => _submit(profile.nombre, profile.creadaPor, profile.cantidadMiembros),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D3557),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.outlineVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Solicitar Verificación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
