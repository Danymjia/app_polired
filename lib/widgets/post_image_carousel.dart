import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'safe_network_image.dart';

/// Carousel or single image renderer for posts.
/// Handles multi-image swiping, "1/3" overlay, and blue dot indicators below.
class PostImageCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final List<File>? localFiles;
  final double height;
  final BorderRadius? borderRadius;

  const PostImageCarousel({
    super.key,
    required this.mediaUrls,
    this.localFiles,
    this.height = 320,
    this.borderRadius,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  int _currentIndex = 0;

  bool get _hasLocalFiles => widget.localFiles != null && widget.localFiles!.isNotEmpty;
  int get _itemCount => _hasLocalFiles ? widget.localFiles!.length : widget.mediaUrls.length;

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) return const SizedBox.shrink();

    Widget content;
    if (_itemCount == 1) {
      content = _hasLocalFiles 
        ? _buildLocalImage(widget.localFiles!.first)
        : _buildImage(widget.mediaUrls.first);
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _itemCount,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _hasLocalFiles 
                      ? _buildLocalImage(widget.localFiles![index])
                      : _buildImage(widget.mediaUrls[index]);
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/$_itemCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_itemCount, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _currentIndex == index ? 8 : 6,
                height: _currentIndex == index ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? AppTheme.primary // Azul oscuro
                      : AppTheme.primary.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: double.infinity,
          child: content,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: content,
    );
  }

  Widget _buildImage(String url) {
    return SafeNetworkImage(
      url: url,
      width: double.infinity,
      height: widget.height,
      fit: BoxFit.cover,
      errorWidget: Container(
        height: widget.height,
        color: AppTheme.surfaceContainer,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildLocalImage(File file) {
    return Image.file(
      file,
      width: double.infinity,
      height: widget.height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: widget.height,
        color: AppTheme.surfaceContainer,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
