import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/post_service.dart';

class ReportPostBottomSheet extends StatefulWidget {
  final String postId;

  const ReportPostBottomSheet({super.key, required this.postId});

  @override
  State<ReportPostBottomSheet> createState() => _ReportPostBottomSheetState();
}

class _ReportPostBottomSheetState extends State<ReportPostBottomSheet> {
  final List<String> _options = [
    'Contenido inapropiado',
    'Spam',
    'Acoso o bullying',
    'Información falsa',
    'Otro',
  ];

  String? _selectedOption;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_selectedOption == null) return false;
    if (_selectedOption == 'Otro') {
      return _descriptionController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _submitReport() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final postService = context.read<PostService>();

    try {
      final result = await postService.reportPost(
        postId: widget.postId,
        tipo: _selectedOption!,
        descripcion: _selectedOption == 'Otro'
            ? _descriptionController.text.trim()
            : 'Reportado como $_selectedOption',
      );

      if (result.success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reporte enviado correctamente',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Error al enviar el reporte'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión al enviar el reporte'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Reportar',
            style: GoogleFonts.inter(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold, // font-bold
              color: AppTheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // mb-4

          // Options list
          Column(
            children: _options.map((option) {
              final isSelected = _selectedOption == option;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedOption = option;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12), // py-3
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.surfaceContainerHigh, // border-neutral-100
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 20, // w-5
                        height: 20, // h-5
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(4), // rounded
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant, // border-neutral-300
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // If "Otro" is selected, show details field
          if (_selectedOption == 'Otro') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 150,
              style: GoogleFonts.inter(fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Describe el motivo aquí...',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.outline,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                counterStyle: GoogleFonts.inter(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24), // mb-6

          // Submit button
          ElevatedButton(
            onPressed: _isValid && !_isSubmitting ? _submitReport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, // bg-black
              foregroundColor: Colors.white, // text-white
              disabledBackgroundColor: AppTheme.primary.withAlpha(80),
              disabledForegroundColor: Colors.white.withAlpha(120),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12), // py-3
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // rounded-lg
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Enviar',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600, // font-semibold
                    ),
                  ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
