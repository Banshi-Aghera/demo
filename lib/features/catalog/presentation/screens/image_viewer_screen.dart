import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

/// Full-screen, pinch-to-zoom gallery.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  final List<String> images;
  final int initialIndex;
  final String? heroTag;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final image = InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: AppNetworkImage(
                  url: widget.images[i], fit: BoxFit.contain),
            ),
          );
          return i == widget.initialIndex && widget.heroTag != null
              ? Hero(tag: widget.heroTag!, child: image)
              : image;
        },
      ),
    );
  }
}
