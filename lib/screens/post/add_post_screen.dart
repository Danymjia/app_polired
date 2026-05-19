import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../widgets/safe_network_image.dart';
import '../../providers/network_provider.dart';
import '../../providers/global_feed_provider.dart';
import '../../providers/community_feed_provider.dart';
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

  String? _postType; // 'imagen' | 'texto'
  String _category = 'Comunidad'; // 'Comunidad', 'Noticias', 'Venta', 'Cursos'

  NetworkStoryModel? _selectedNetwork;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límite de 3 imágenes alcanzado')),
      );
      return;
    }
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (final file in pickedFiles) {
          if (_selectedImages.length < 3) {
            _selectedImages.add(File(file.path));
          }
        }
      });
    }
  }

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
      final title = _postType == 'texto' ? _titleController.text.trim() : '';
      final content = _descriptionController.text.trim();
      final categoryValue = _category.toLowerCase();
      final comunidadId = _selectedNetwork?.id;

      if (categoryValue == 'comunidad' && comunidadId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Selecciona una red comunitaria',
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
              imageFiles: _postType == 'imagen' ? _selectedImages : null,
            )
          : await _postService.createPost(
              titulo: title,
              contenido: content,
              categoria: categoryValue,
              comunidadId: comunidadId,
              imageFiles: _postType == 'imagen' ? _selectedImages : null,
            );

      if (result.success) {
        if (mounted) {
          try {
            if (categoryValue == 'comunidad') {
              context.read<CommunityFeedProvider>().refreshFeed();
            } else {
              context.read<GlobalFeedProvider>().refreshFeed();
            }
          } catch (_) {}

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
          onPressed: () {
            if (_postType != null) {
              setState(() => _postType = null);
            } else {
              Navigator.pop(context);
            }
          },
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
          : _postType == null
              ? _buildTypeSelection()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        if (_category == 'Comunidad') ...[
                          _buildSectionLabel('SELECCIONAR RED'),
                          const SizedBox(height: 12),
                          _buildNetworkSelector(networks),
                          const SizedBox(height: 24),
                        ],

                        if (_postType == 'texto') ...[
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
                        ],

                        _buildSectionLabel('CONTENIDO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          validator: (value) =>
                              value!.trim().isEmpty ? 'Requerido' : null,
                          maxLines: 4,
                          maxLength: _postType == 'imagen' ? 300 : 1000,
                          buildCounter: (context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) {
                            if (maxLength == null) return null;
                            final isLimitReached = currentLength >= maxLength;
                            return Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLimitReached
                                    ? AppTheme.error
                                    : AppTheme.outline,
                              ),
                            );
                          },
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

                        if (_postType == 'imagen' &&
                            (_category == 'Venta' || _category == 'Cursos')) ...[
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

                        if (_postType == 'imagen') ...[
                          _buildSectionLabel('IMÁGENES (OPCIONAL, MÁX. 3)'),
                          const SizedBox(height: 12),
                          _buildImagePickerSection(),
                          const SizedBox(height: 24),
                        ],

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _isPrivacyAccepted,
                              onChanged: (val) => setState(
                                  () => _isPrivacyAccepted = val ?? false),
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

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isPrivacyAccepted ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary, // Using main global dark blue
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
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTypeSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Qué tipo de publicación deseas crear?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 40),
            _buildTypeCard(
              title: 'Publicación de texto',
              description: 'Comparte una idea, pregunta o noticia en texto.',
              icon: Icons.text_fields_rounded,
              onTap: () => setState(() => _postType = 'texto'),
            ),
            const SizedBox(height: 20),
            _buildTypeCard(
              title: 'Publicación con imagen',
              description: 'Sube fotos, vende artículos o promociona cursos.',
              icon: Icons.image_rounded,
              onTap: () => setState(() => _postType = 'imagen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + (_selectedImages.length < 3 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppTheme.outline,
                  size: 32,
                ),
              ),
            );
          }

          final imageFile = _selectedImages[index];
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
          color: isSelected ? AppTheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
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
                        child: net.imageUrl.trim().isNotEmpty
                            ? SafeNetworkImage(
                                url: net.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: _buildInitialsAvatar(net),
                              )
                            : _buildInitialsAvatar(net),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    net.acronym.isNotEmpty
                        ? net.acronym
                        : (net.name.length >= 3 ? net.name.substring(0, 3) : net.name),
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

  Widget _buildInitialsAvatar(NetworkStoryModel net) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        net.acronym.isNotEmpty ? net.acronym : (net.name.isNotEmpty ? net.name.substring(0, 1).toUpperCase() : '?'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
