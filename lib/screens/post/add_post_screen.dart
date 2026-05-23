import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../services/command_bus.dart';
import '../../models/commands/feed_command.dart';
import '../../utils/image_compression.dart';
import '../../widgets/safe_network_image.dart';
import '../../providers/network_provider.dart';
import '../../models/feed_context.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../services/api_service.dart';
import '../../models/network_story_model.dart';
import '../../widgets/post_image_carousel.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _postType; // 'imagen' | 'texto'
  String _category = 'Comunidad'; // tipo de contenido (describe QUÉ es)

  // ─── FeedContext EXPLÍCITO: decisor de destino (NO derivado de category) ──
  // El usuario selecciona explícitamente: Home (Mi red) o Global (Explorar)
  FeedContext _feedContext = FeedContext.home();

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

    setState(() {
      _isPreparingImages = true;
    });

    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1440,
        maxHeight: 1440,
      );

      if (pickedFiles.isEmpty) return;

      final availableSlots = 3 - _selectedImages.length;
      final filesToProcess = pickedFiles.take(availableSlots).map((xfile) => File(xfile.path)).toList();

      // Se elimina setState de _statusMessage = 'Comprimiendo...'


      final compressedFiles = await Future.wait(filesToProcess.map((originalFile) async {
        final compressed = await compressPostImageFile(originalFile);
        return compressed ?? originalFile;
      }));

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(compressedFiles);
      });
    } catch (e, stack) {
      debugPrint('[AddPostScreen] Error al preparar imágenes: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al preparar imágenes. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingImages = false;
        });
      }
    }
  }

  bool _isFree = false;
  bool _isPrivacyAccepted = true;
  bool _isLoading = false;
  bool _isPreparingImages = false;

  @override
  void initState() {
    super.initState();

    // Auto-select first joined network if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = Provider.of<NetworkProvider>(
        context,
        listen: false,
      );
      final joinedNetworks = networkProvider.networkStories.where((n) => n.isJoined).toList();
      if (joinedNetworks.isNotEmpty) {
        setState(() {
          _selectedNetwork = joinedNetworks.first;
        });
      } else {
        setState(() {
          _selectedNetwork = null;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _postType == 'texto' ? _titleController.text.trim() : '';
      final content = _descriptionController.text.trim();
      final categoryValue = _category.toLowerCase();
      final feedContext = _feedContext;
      final comunidadId = feedContext == FeedContext.home() ? _selectedNetwork?.id : null;

      if (feedContext == FeedContext.home() && comunidadId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona una red comunitaria')),
          );
        }
        return;
      }

      final commandBus = context.read<CommandBus>();
      final command = CreatePostCommand(
        feedContext: feedContext,
        category: categoryValue,
        content: content,
        postType: _postType ?? 'texto',
        title: title,
        networkId: comunidadId,
        networkName: _selectedNetwork?.name,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        price: _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0),
      );

      final result = await commandBus.dispatch(command);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          // Ya no hacemos refresh manually: la arquitectura CQRS inyecta 
          // el post optimista globalmente. Refrescar aquí destruiría el estado 
          // optimista si el backend aún no ha indexado.
          
          context.read<AuthProvider>().incrementPublicacionesCount();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Error al publicar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);
    final networks = networkProvider.networkStories.where((n) => n.isJoined).toList();

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
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                        // ─── SELECTOR DE DESTINO (FeedContext explícito) ──
                        // ❌ PROHIBIDO: derivar destino desde category
                        // ✅ El usuario elige explícitamente dónde publicar
                        _buildSectionLabel('DESTINO DE PUBLICACIÓN'),
                        const SizedBox(height: 12),
                        _buildDestinationSelector(),
                        const SizedBox(height: 24),

                        _buildSectionLabel('CATEGORÍA'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_feedContext == FeedContext.home())
                              _buildCategoryChip('Comunidad')
                            else ...[
                              _buildCategoryChip('Noticias'),
                              _buildCategoryChip('Venta'),
                              _buildCategoryChip('Cursos'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (_feedContext == FeedContext.home()) ...[
                          _buildSectionLabel('SELECCIONAR RED'),
                          const SizedBox(height: 12),
                          _buildNetworkSelector(networks),
                          const SizedBox(height: 24),
                        ],

                        if (_postType == 'imagen') ...[
                          _buildSectionLabel('IMÁGENES (MÁX. 3)'),
                          const SizedBox(height: 12),
                          if (_selectedImages.isNotEmpty) ...[
                            PostImageCarousel(
                              localFiles: _selectedImages,
                              mediaUrls: const [],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildImagePickerSection(),
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

                        if (_category == 'Venta' || _category == 'Cursos') ...[
                          _buildSectionLabel('PRECIO (\$)'),
                          const SizedBox(height: 8),
                          if (_category == 'Cursos')
                            Theme(
                              data: ThemeData(unselectedWidgetColor: AppTheme.outline),
                              child: CheckboxListTile(
                                title: const Text(
                                  'Es gratis',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                value: _isFree,
                                onChanged: (val) {
                                  setState(() {
                                    _isFree = val ?? false;
                                    if (_isFree) _priceController.clear();
                                  });
                                },
                                activeColor: AppTheme.primary,
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          if (!_isFree)
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

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _isPrivacyAccepted,
                              onChanged: (val) => setState(
                                  () => _isPrivacyAccepted = val ?? false),
                              activeColor: AppTheme.primary,
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
                            onPressed: _isPrivacyAccepted && !_isPreparingImages ? _submit : null,
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
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Qué tipo de publicación deseas crear?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
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
              onTap: _isPreparingImages || _isLoading ? null : _pickImages,
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

  // ─── Selector de destino (FeedContext) ──────────────────────────────────
  Widget _buildDestinationSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _feedContext = FeedContext.home();
              _category = 'Comunidad';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: _feedContext == FeedContext.home()
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _feedContext == FeedContext.home()
                      ? AppTheme.primary
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 18,
                    color: _feedContext == FeedContext.home()
                        ? Colors.white
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Mi Red (Home)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _feedContext == FeedContext.home()
                            ? Colors.white
                            : AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _feedContext = FeedContext.exploreGlobal();
              _category = 'Noticias';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: _feedContext == FeedContext.exploreGlobal()
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _feedContext == FeedContext.exploreGlobal()
                      ? AppTheme.primary
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public_outlined,
                    size: 18,
                    color: _feedContext == FeedContext.exploreGlobal()
                        ? Colors.white
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Red Global',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _feedContext == FeedContext.exploreGlobal()
                            ? Colors.white
                            : AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSelector(List<NetworkStoryModel> networks) {
    if (networks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No estás unido a ninguna red comunitaria. Únete a una red para poder publicar aquí.',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
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
