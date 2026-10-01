import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Cached image with a shimmer while loading and an icon when missing.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) =>
          ShimmerBox(width: width, height: height, radius: 0),
      errorWidget: (context, _, _) => fallback,
    );
  }
}
