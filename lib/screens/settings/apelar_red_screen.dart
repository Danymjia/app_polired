import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class ApelarRedScreen extends StatefulWidget {
  final String redId;
  final String nombreRed;

  const ApelarRedScreen({
    Key? key,
    required this.redId,
    required this.nombreRed,
  }) : super(key: key);

  @override
  State<ApelarRedScreen> createState() => _ApelarRedScreenState();
}

class _ApelarRedScreenState extends State<ApelarRedScreen> {
  final TextEditingController _descripcionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitApelacion() async {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un motivo para la apelación.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.post('/apelaciones/red', {
        'redId': widget.redId,
        'descripcion': descripcion,
      });

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apelación enviada correctamente.')),
        );
        Navigator.pop(context);
      } else {
        String errorMessage = 'Ocurrió un error al enviar la apelación.';
        if (result.message != null && result.message!.isNotEmpty) {
          errorMessage = result.message!;
        } else if (result.statusCode == 403) {
          errorMessage = 'Solo el administrador asignado de la red puede apelar.';
        } else if (result.statusCode == 400) {
          errorMessage = 'La red no está deshabilitada.';
        } else if (result.statusCode == 409) {
          errorMessage = 'Ya existe una apelación pendiente para esta red.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error inesperado.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apelar Red'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Red Deshabilitada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nombreRed,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Motivo de la apelación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Explica detalladamente por qué crees que la red no debería estar deshabilitada...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitApelacion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Enviar apelación',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
