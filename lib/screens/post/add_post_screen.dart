import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
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
  
  String _postType = 'Texto'; // 'Texto', 'Imagen'
  String _category = 'Comunidad'; // 'Comunidad', 'Noticias', 'Venta', 'Cursos'
  bool _isCoursePaid = false;
  
  NetworkStoryModel? _selectedNetwork;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  
  bool _isPrivacyAccepted = true;
  bool _isLoading = false;

  late PostService _postService;

  @override
  void initState() {
    super.initState();
    _postService = PostService(ApiService()); // Idealmente inyectado via Provider, pero instanciamos aquí por simplicidad
    
    // Auto-select first network if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage();
      if (selectedImages.isNotEmpty) {
        setState(() {
          // Max 5 images
          _images.addAll(selectedImages);
          if (_images.length > 5) {
            _images = _images.sublist(0, 5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Puedes subir un máximo de 5 imágenes')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<String?> _getBase64Images() async {
    if (_images.isEmpty) return null;
    
    // Convert multiple images to a single comma-separated base64 string
    // Or just send the first one as base64 to test (since backend takes 1 string for now)
    try {
      List<String> base64List = [];
      for (var img in _images) {
        final bytes = await img.readAsBytes();
        final base64String = base64Encode(bytes);
        base64List.add('data:image/jpeg;base64,$base64String');
      }
      return base64List.join(',');
    } catch (e) {
      debugPrint("Error encoding image: $e");
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;


    if (_postType == 'Imagen' && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos una imagen')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String title = _titleController.text.trim();
      if (_postType == 'Imagen' && title.isEmpty) {
        // Backend requiere título, auto generamos uno si está vacío
        title = _descriptionController.text.trim();
        if (title.length > 30) {
          title = '${title.substring(0, 30)}...';
        } else if (title.isEmpty) {
          title = 'Publicación de imagen';
        }
      }

      String? mediaUrl = await _getBase64Images();
      String? redId = _category == 'Comunidad' ? _selectedNetwork?.id : null;

      ApiResult result;

      if (_category == 'Venta' || (_category == 'Cursos' && _isCoursePaid)) {
        double price = double.tryParse(_priceController.text) ?? 0.0;
        result = await _postService.createArticle(
          titulo: title,
          descripcion: _descriptionController.text.trim(),
          precio: price,
          comunidadId: redId,
          imagen: mediaUrl,
        );
      } else {
        result = await _postService.createPost(
          titulo: title,
          contenido: _descriptionController.text.trim(),
          comunidadId: redId,
          mediaUrl: mediaUrl,
        );
      }

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación creada con éxito')),
          );
          Navigator.pop(context); // Volver al home o limpiar formulario
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Error al publicar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
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
                    // Post Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton('Texto', Icons.text_fields),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeButton('Imagen', Icons.image),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Image Preview Area (Only for 'Imagen' type)
                    if (_postType == 'Imagen') ...[
                      _buildImagePreviewArea(),
                      const SizedBox(height: 24),
                    ],

                    // Categories Selector
                    _buildSectionLabel('CATEGORÍA'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Comunidad', 'Noticias', 'Venta', 'Cursos']
                          .map((cat) => _buildCategoryChip(cat))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Cursos Paid/Free Selector
                    if (_category == 'Cursos') ...[
                      _buildSectionLabel('TIPO DE CURSO'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCourseTypeButton('Gratis', false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCourseTypeButton('Paga', true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

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
                    if (_postType == 'Texto' || _category == 'Venta' || _category == 'Cursos') ...[
                      _buildSectionLabel('TÍTULO'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        validator: (value) => value!.trim().isEmpty ? 'Requerido' : null,
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
                    ],

                    // Description Field
                    _buildSectionLabel('DESCRIPCIÓN'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      validator: (value) => value!.trim().isEmpty ? 'Requerido' : null,
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

                    // Price Field (Only for 'Venta' or 'Cursos' Paga)
                    if (_category == 'Venta' || (_category == 'Cursos' && _isCoursePaid)) ...[
                      _buildSectionLabel('PRECIO (\$)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (double.tryParse(value) == null) return 'Precio inválido';
                          return null;
                        },
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                          onChanged: (val) => setState(() => _isPrivacyAccepted = val ?? false),
                          activeColor: AppTheme.primaryText,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const Expanded(
                          child: Text(
                            'Esta publicación no viola las políticas de privacidad de la aplicación',
                            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildTypeButton(String title, IconData icon) {
    bool isSelected = _postType == title;
    return InkWell(
      onTap: () => setState(() => _postType = title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryText : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryText : AppTheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.onSurface),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.onSurface,
              ),
            ),
          ],
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
          if (cat != 'Cursos') _isCoursePaid = false;
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

  Widget _buildCourseTypeButton(String title, bool isPaid) {
    bool isSelected = _isCoursePaid == isPaid;
    return InkWell(
      onTap: () => setState(() => _isCoursePaid = isPaid),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryText : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryText : AppTheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSelector(List<NetworkStoryModel> networks) {
    if (networks.isEmpty) {
      return const Text('No tienes redes disponibles', style: TextStyle(color: Colors.grey));
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
                        child: Image.network(
                          net.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.group),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    net.acronym.isNotEmpty ? net.acronym : net.name.substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryText : AppTheme.outline,
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

  Widget _buildImagePreviewArea() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _images.isEmpty
          ? Center(
              child: InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_photo_alternate, size: 48, color: AppTheme.outline),
                      SizedBox(height: 12),
                      Text('Toca para agregar imágenes\n(Máximo 5)', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.outline)),
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                // Horizontal scroll for multiple images
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 40, // Full width minus padding
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_images[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Indicator and Add Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_images.length}/5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_images.length < 5)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: InkWell(
                      onTap: _pickImages,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.black, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
