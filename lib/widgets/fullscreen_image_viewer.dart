import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    required this.imageUrls,
    this.initialIndex = 0,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    List<String> urls, {
    int initialIndex = 0,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenImageViewer(
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: widget.imageUrls.length > 1
            ? Text('${_current + 1} / ${widget.imageUrls.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain, // imagen completa, sin recortar
                placeholder: (context, url) => const CircularProgressIndicator(
                  color: Colors.white,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
