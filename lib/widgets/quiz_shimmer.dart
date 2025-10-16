import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class QuizShimmer extends StatelessWidget {
  final bool
  fullShimmer; // If true, show full shimmer (for reset), else just number shimmer

  const QuizShimmer({super.key, this.fullShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (fullShimmer) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsCardShimmer(),
            SizedBox(height: 24.h),
            _buildQuestionShimmer(),
            SizedBox(height: 24.h),
            _buildOptionShimmer(),
            SizedBox(height: 12.h),
            _buildOptionShimmer(),
            SizedBox(height: 12.h),
            _buildOptionShimmer(),
            SizedBox(height: 12.h),
            _buildOptionShimmer(),
            SizedBox(height: 32.h),
            _buildButtonShimmer(),
          ],
        ),
      );
    }

    // For number shimmer only - return just the shimmering numbers
    return _buildNumberShimmer();
  }

  Widget _buildStatsCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Marks Earned
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 32.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(height: 60.h, width: 2.w, color: Colors.white),
                // Current Question
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 32.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                // Percentage
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 28.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
                // Remaining Questions
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 28.h,
                        width: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.6),
      child: Container(
        height: 32.h,
        width: 60.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  // Small shimmer for percentage and remaining
  Widget buildSmallNumberShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.6),
      child: Container(
        height: 24.h,
        width: 50.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildQuestionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 20.h,
            width: 250.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            // Option letter circle
            Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            // Option text
            Expanded(
              child: Container(
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Radio button
            Container(
              width: 24.w,
              height: 24.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
