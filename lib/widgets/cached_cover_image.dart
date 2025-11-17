import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedCoverImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const CachedCoverImage({
    super.key,
    required this.url,
    required this.height,
    required this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => Container(
        height: height,
        width: width,
        color: Colors.black26,
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        width: width,
        color: Colors.black26,
        child: const Icon(
          Icons.broken_image,
          color: Colors.white38,
          size: 28,
        ),
      ),
    );

    // aplica borda somente se enviada
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
