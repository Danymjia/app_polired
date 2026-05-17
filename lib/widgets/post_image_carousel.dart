import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'safe_network_image.dart';

/// Carousel or single image renderer for posts.
/// Handles multi-image swiping and dot indicators up to 3 images.
class PostImageCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final double height;
  final BorderRadius? borderRadius;

  const PostImageCarousel({
    super.key,
    required this.mediaUrls,
    this.height = 320,
    this.borderRadius,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) return const SizedBox.shrink();

    Widget content;
    if (widget.mediaUrls.length == 1) {
      content = _buildImage(widget.mediaUrls.first);
    } else {
      content = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildImage(widget.mediaUrls[index]);
            },
          ),
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.mediaUrls.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentIndex == index ? 8 : 6,
                  height: _currentIndex == index ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: content,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
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
}
