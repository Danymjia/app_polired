import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../widgets/safe_network_image.dart';
import '../../providers/network_provider.dart';
import '../../services/post_service.dart';
import '../../services/api_service.dart';
import '../../models/network_story_model.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();

  String _category = 'Comunidad'; // 'Comunidad', 'Noticias', 'Venta', 'Cursos'

  NetworkStoryModel? _selectedNetwork;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isPrivacyAccepted = true;
  bool _isLoading = false;

  late PostService _postService;

  @override
  void initState() {
    super.initState();
    _postService = PostService(context.read<ApiService>());

    // Auto-select first network if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = Provider.of<NetworkProvider>(
        context,
        listen: false,
      );
      if (networkProvider.networkStories.isNotEmpty) {
        setState(() {
          _selectedNetwork = networkProvider.networkStories.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final content = _descriptionController.text.trim();
      final categoryValue = _category.toLowerCase();
      final comunidadId = _category == 'Comunidad'
          ? _selectedNetwork?.id
          : null;

      if (categoryValue == 'comunidad' && comunidadId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Selecciona una red comunitaria para la categoría Comunidad',
              ),
            ),
          );
        }
        return;
      }

      final result = (categoryValue == 'venta' || categoryValue == 'cursos')
          ? await _postService.createArticle(
              titulo: title,
              descripcion: content,
              precio: double.tryParse(_priceController.text.trim()) ?? 0.0,
              categoria: categoryValue,
              comunidadId: comunidadId,
            )
          : await _postService.createPost(
              titulo: title,
              contenido: content,
              categoria: categoryValue,
              comunidadId: comunidadId,
            );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación creada con éxito')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          final errorMessage = result.statusCode == 401
              ? 'No autorizado. Verifica tu sesión e intenta de nuevo.'
              : result.message ?? 'Error al publicar';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final networks = networkProvider.networkStories;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nueva publicación',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories Selector
                    _buildSectionLabel('CATEGORÍA'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Comunidad',
                        'Noticias',
                        'Venta',
                        'Cursos',
                      ].map((cat) => _buildCategoryChip(cat)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Cursos Paid/Free Selector

                    // Network Selector (Only show for 'Comunidad')
                    if (_category == 'Comunidad') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel('SELECCIONAR RED'),
                          const Text(
                            'Ver todas',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNetworkSelector(networks),
                      const SizedBox(height: 24),
                    ],

                    // Title Field (Mandatory for Text, optional/hidden logic for others)
                    _buildSectionLabel('TÍTULO'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Requerido' : null,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Añade un título...',
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Field
                    _buildSectionLabel('DESCRIPCIÓN'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Requerido' : null,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Escribe algo...',
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_category == 'Venta' || _category == 'Cursos') ...[
                      _buildSectionLabel('PRECIO (\$)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (_category != 'Venta' && _category != 'Cursos') {
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.attach_money, size: 20),
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Privacy Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _isPrivacyAccepted,
                          onChanged: (val) =>
                              setState(() => _isPrivacyAccepted = val ?? false),
                          activeColor: AppTheme.primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Esta publicación no viola las políticas de privacidad de la aplicación',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPrivacyAccepted ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryText,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black12,
                        ),
                        child: const Text(
                          'Publicar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // Padding for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppTheme.outline,
      ),
    );
  }

  Widget _buildCategoryChip(String cat) {
    bool isSelected = _category == cat;
    return InkWell(
      onTap: () {
        setState(() {
          _category = cat;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryText : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryText : AppTheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          cat,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSelector(List<NetworkStoryModel> networks) {
    if (networks.isEmpty) {
      return const Text(
        'No tienes redes disponibles',
        style: TextStyle(color: Colors.grey),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: networks.length,
        itemBuilder: (context, index) {
          final net = networks[index];
          final isSelected = _selectedNetwork?.id == net.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedNetwork = net),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Colors.black, Colors.grey],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : null,
                      color: isSelected ? null : AppTheme.surfaceContainerHigh,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: SafeNetworkImage(
                          url: net.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.group),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    net.acronym.isNotEmpty
                        ? net.acronym
                        : net.name.substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryText
                          : AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
