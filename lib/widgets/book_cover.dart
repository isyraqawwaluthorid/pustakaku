import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/extensions.dart';
import '../models/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.width = 72,
    this.height = 104,
    this.size = CoverSize.medium,
    this.heroTag,
  });

  final String? url;
  final double width;
  final double height;
  final CoverSize size;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: context.colors.surfaceContainerHighest,
      child: Icon(Icons.menu_book_rounded, color: context.colors.outline),
    );

    Widget child = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
    if (heroTag != null) child = Hero(tag: heroTag!, child: child);
    return child;
  }
}
