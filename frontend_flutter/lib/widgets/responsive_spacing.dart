import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget helper pour les espacements responsive
/// Utilisation : RSpacing(height: 16) au lieu de SizedBox(height: 16.h)
class RSpacing extends StatelessWidget {
  final double? width;
  final double? height;
  
  const RSpacing({super.key, this.width, this.height});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?.w,
      height: height?.h,
    );
  }
}

