import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/cubits/images/images_cubit.dart';

class ImageCardStack extends StatefulWidget {
  final ImagesLoaded state;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const ImageCardStack({
    super.key,
    required this.state,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<ImageCardStack> createState() => _ImageCardStackState();
}

class _ImageCardStackState extends State<ImageCardStack>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  double _dragDistance = 0.0;
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragDistance += details.delta.dx;
          });
        }
      },
      onPanEnd: (details) {
        _isDragging = false;
        
        // Determine swipe direction and velocity
        final velocity = details.velocity.pixelsPerSecond.dx;
        final dragThreshold = 100.0;
        
        if (_dragDistance.abs() > dragThreshold || velocity.abs() > 500) {
          if (_dragDistance > 0 || velocity > 0) {
            // Swipe right - previous image
            widget.onSwipeRight?.call();
          } else {
            // Swipe left - next image
            widget.onSwipeLeft?.call();
          }
        }
        
        // Reset drag distance
        setState(() {
          _dragDistance = 0.0;
        });
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background cards (stacked behind)
            ..._buildBackgroundCards(),
            
            // Main card (on top)
            _buildMainCard(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCards() {
    final cards = <Widget>[];
    final maxBackgroundCards = math.min(3, widget.state.images.length - 1);
    
    for (int i = 1; i <= maxBackgroundCards; i++) {
      final cardIndex = (widget.state.currentIndex + i) % widget.state.images.length;
      final scale = 1.0 - (i * 0.05); // Each card is 5% smaller
      final offset = i * 8.0; // Each card is offset by 8px
      
      cards.add(
        Positioned(
          top: offset,
          left: offset,
          right: offset,
          bottom: offset,
          child: Transform.scale(
            scale: scale,
            child: _buildCard(
              widget.state.images[cardIndex],
              opacity: 0.8 - (i * 0.2), // Each card is more transparent
            ),
          ),
        ),
      );
    }
    
    return cards.reversed.toList(); // Reverse to show cards in correct order
  }

  Widget _buildMainCard() {
    final currentImage = widget.state.images[widget.state.currentIndex];
    final rotation = _dragDistance * 0.001; // Convert drag distance to rotation
    final opacity = math.max(0.0, 1.0 - (_dragDistance.abs() * 0.002));
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_dragDistance, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity,
              child: _buildCard(currentImage),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(ImageModel image, {double opacity = 1.0}) {
    return Container(
      margin: EdgeInsets.only(
        top: 10.h,
        bottom: 40.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(20.r)),
        child: Stack(
          children: [
            // Image
            Image.network(
              image.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
            
            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8 * opacity),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                ),
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image title
                    Text(
                      image.title,
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        color: Colors.white.withOpacity(opacity),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Download button
                        _buildActionButton(
                          icon: Icons.download,
                          onTap: () {
                            // Download functionality will be handled by parent
                          },
                          opacity: opacity,
                        ),
                        SizedBox(width: 12.w),
                        
                        // Share button
                        _buildActionButton(
                          icon: Icons.share,
                          onTap: () {
                            // Share functionality will be handled by parent
                          },
                          opacity: opacity,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required double opacity,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2 * opacity),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(opacity),
          size: 24.sp,
        ),
      ),
    );
  }
}
