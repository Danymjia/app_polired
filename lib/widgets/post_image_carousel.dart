import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

/// Carousel or single image renderer for posts.
/// Handles multi-image swiping, "1/3" overlay, and blue dot indicators below.
class PostImageCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final List<File>? localFiles;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final VoidCallback? onDoubleTap;

  const PostImageCarousel({
    super.key,
    required this.mediaUrls,
    this.localFiles,
    this.aspectRatio = 1.0,
    this.borderRadius,
    this.onDoubleTap,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartAnimationController);

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.9).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(0.9), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_heartAnimationController);
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
    }
    _heartAnimationController.forward(from: 0.0);
  }

  bool get _hasLocalFiles => widget.localFiles != null && widget.localFiles!.isNotEmpty;
  int get _itemCount => _hasLocalFiles ? widget.localFiles!.length : widget.mediaUrls.length;

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) return const SizedBox.shrink();

    Widget content;
    if (_itemCount == 1) {
      content = GestureDetector(
        onDoubleTap: _handleDoubleTap,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: _hasLocalFiles 
                  ? _buildLocalImage(widget.localFiles!.first)
                  : _buildImage(widget.mediaUrls.first),
              ),
              _buildAnimatedHeart(),
            ],
          ),
        ),
      );
    } else {
      content = GestureDetector(
        onDoubleTap: _handleDoubleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
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
                  _buildAnimatedHeart(),
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
      ),
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

  Widget _buildAnimatedHeart() {
    return AnimatedBuilder(
      animation: _heartAnimationController,
      builder: (context, child) {
        if (_heartAnimationController.isDismissed) {
          return const SizedBox.shrink();
        }
        return Opacity(
          opacity: _heartOpacityAnimation.value,
          child: Transform.scale(
            scale: _heartScaleAnimation.value,
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 100,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.surfaceContainer,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
        ),
      ),
      errorWidget: (context, url, error) => Container(
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
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
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
