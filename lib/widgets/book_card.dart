import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
  color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: book.coverImageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 300, // Optimize memory cache size
                    memCacheHeight: 400,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholderFadeInDuration: const Duration(milliseconds: 150),
                    cacheKey: 'book_cover_${book.id}',
                    maxWidthDiskCache: 600, // Optimize disk cache size
                    maxHeightDiskCache: 800,
                    placeholder:
                        (context, url) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff0C1138),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(
                            child: Icon(
                              Icons.book,
                              size: 40,
                              color: Color(0xff0C1138),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
