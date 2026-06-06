import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/network_service.dart';
import '../../providers/network_profile_provider.dart';

class NetworkOfficializationScreen extends StatefulWidget {
  final String redId;
  
  const NetworkOfficializationScreen({super.key, required this.redId});

  @override
  State<NetworkOfficializationScreen> createState() => _NetworkOfficializationScreenState();
}

class _NetworkOfficializationScreenState extends State<NetworkOfficializationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _dependenciaCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();
  
  String? _dependenciaSeleccionada;
  String? _cargoSeleccionado;
  
  bool _isSubmitting = false;

  final List<String> _dependencias = ['Rectorado', 'Vicerrectorado', 'Facultad', 'Carrera', 'Departamento', 'Bienestar Universitario', 'Otro'];
  final List<String> _cargos = ['Director', 'Coordinador', 'Docente responsable', 'Administrativo', 'Representante autorizado'];

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
      profileProvider.loadProfile(widget.redId, isMember: true);
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _dependenciaCtrl.dispose();
    _cargoCtrl.dispose();
    _justificacionCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v) => v?.trim().isEmpty == true ? 'Campo obligatorio' : null;

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
    if (_dependenciaSeleccionada == null || _cargoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona dependencia y cargo')));
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final networkService = context.read<NetworkService>();
      final result = await networkService.solicitarOficializacionRed(
        redId: widget.redId,
        nombreRed: nombreRed,
        fechaCreacionRed: fechaCreacionRed,
        cantidadMiembros: cantidadMiembros,
        dependencia: _dependenciaSeleccionada == 'Otro' ? _dependenciaCtrl.text.trim() : _dependenciaSeleccionada!,
        cargo: _cargoSeleccionado!,
        correoInstitucional: _correoCtrl.text.trim(),
        justificacion: _justificacionCtrl.text.trim(),
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
    final profileProvider = context.watch<NetworkProfileProvider>();
    final profile = profileProvider.profile;
    
    if (profileProvider.status == NetworkProfileStatus.loading || profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Solicitud de Oficialización',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Align(
                alignment: Alignment.center,
                child: Container(
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
                            color: const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(Icons.grade, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Oficialización de Red',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF485f84)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Obtén la insignia amarilla y el reconocimiento oficial institucional.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
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
              
              // Datos Básicos
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.outline),
                  const SizedBox(width: 8),
                  Text('Datos básicos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D3557))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOMBRE DE LA RED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    const SizedBox(height: 4),
                    Text(profile.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Información Institucional
              Row(
                children: [
                  const Icon(Icons.account_balance_outlined, size: 20, color: AppTheme.outline),
                  const SizedBox(width: 8),
                  Text('Información institucional', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D3557))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Dependencia universitaria asociada *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true, fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _dependencias.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _dependenciaSeleccionada = v),
                validator: _validateRequired,
              ),
              if (_dependenciaSeleccionada == 'Otro') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dependenciaCtrl,
                  validator: _validateRequired,
                  decoration: InputDecoration(
                    hintText: 'Especificar dependencia',
                    filled: true, fillColor: AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Cargo del solicitante *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true, fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _cargos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _cargoSeleccionado = v),
                validator: _validateRequired,
              ),
              const SizedBox(height: 32),
              
              // Validación Institucional
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 20, color: AppTheme.outline),
                  const SizedBox(width: 8),
                  Text('Validación institucional', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D3557))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Correo institucional responsable *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoCtrl,
                validator: _validateCorreo,
                decoration: InputDecoration(
                  hintText: 'nombre@epn.edu.ec',
                  filled: true, fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info, size: 14, color: Color(0xFF765a05)), // tertiary fixed color from html
                  const SizedBox(width: 8),
                  Text('Debe terminar en el dominio oficial de la universidad.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.outline)),
                ],
              ),
              const SizedBox(height: 32),

              // Justificación
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20, color: AppTheme.outline),
                  const SizedBox(width: 8),
                  Text('Justificación', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D3557))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Motivo de la solicitud *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _justificacionCtrl,
                validator: _validateRequired,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Explique por qué la red representa oficialmente a la dependencia...',
                  filled: true, fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
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

                    return ElevatedButton.icon(
                      onPressed: (_isSubmitting || !cumple) ? null : () => _submit(profile.nombre, profile.creadaPor, profile.cantidadMiembros),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D3557),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.outlineVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send, size: 18),
                      label: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  }
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Al enviar esta solicitud, declaras que la información proporcionada es verídica y cuentas con el aval de la dependencia mencionada.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
