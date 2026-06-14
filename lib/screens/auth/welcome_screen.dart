import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/network_provider.dart';
import '../../config/theme.dart';
import '../../utils/json_ids.dart';

/// Responsabilidad principal:
/// Pantalla de bienvenida que obliga al usuario a unirse al menos a 3 redes comunitarias.
///
/// Flujo dentro de la app:
/// Aparece en el flujo de Onboarding, después de completar el perfil y antes del `HomeScreen`.
///
/// Dependencias críticas:
/// - `NetworkProvider`
///
/// Side Effects:
/// - Despacha peticiones HTTP para unirse a las redes seleccionadas en batch.
/// - Navega a `/home` al finalizar.
///
/// Recordatorios técnicos y CQRS:
/// - Utiliza `parseMongoIdFromMap` de `json_ids.dart` para extracción segura de IDs del payload dinámico.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final Set<String> _selectedNetworks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NetworkProvider>(context, listen: false).fetchRedes();
    });
  }

  void _toggleNetwork(String id) {
    setState(() {
      if (_selectedNetworks.contains(id)) {
        _selectedNetworks.remove(id);
      } else {
        if (_selectedNetworks.length < 3) {
          _selectedNetworks.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Ya has seleccionado 3 redes comunitarias')),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedNetworks.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Debes seleccionar 3 redes para continuar')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final networkProvider = Provider.of<NetworkProvider>(context, listen: false);

    final success = await networkProvider.unirseRedes(_selectedNetworks.toList());

    if (success) {
      if (mounted) {
        context.go('/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(networkProvider.errorMessage ?? 'Error al unirse a las redes')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido a Polired. Únete a tu comunidad universitaria.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -1.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Conecta con estudiantes, comparte proyectos y descubre lo que sucede en tu campus.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REDES RECOMENDADAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF424242),
                          ),
                        ),
                        Text(
                          '${_selectedNetworks.length}/3',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    if (networkProvider.isLoading && networkProvider.redes.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (networkProvider.redes.isEmpty)
                      Text(networkProvider.errorMessage ?? 'No hay redes disponibles', style: const TextStyle(color: Colors.grey))
                    else
                      ...networkProvider.redes.take(10).map((raw) {
                        if (raw is! Map) return const SizedBox.shrink();
                        final red = Map<String, dynamic>.from(raw);
                        final redId = parseMongoIdFromMap(red) ?? '';
                        if (redId.isEmpty) return const SizedBox.shrink();
                        final isSelected = _selectedNetworks.contains(redId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.surfaceContainerHigh,
                                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
                                    image: (red['fotoPerfil'] != null && red['fotoPerfil'].toString().trim().isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(red['fotoPerfil'].toString().trim()),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (red['fotoPerfil'] == null || red['fotoPerfil'].toString().trim().isEmpty)
                                      ? const Center(
                                          child: Icon(Icons.groups, color: AppTheme.secondary),
                                        )
                                      : null,
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      red['nombre'] as String? ?? 'Red Comunitaria',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      red['descripcion'] as String? ?? 'Descripción no disponible',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF424242),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => _toggleNetwork(redId),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.black : Colors.transparent,
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.add,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: networkProvider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3557),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: networkProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
