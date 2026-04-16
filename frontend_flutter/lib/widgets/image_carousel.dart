import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/models/teaching.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  List<Teaching> _teachings = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  // Badges pour les slides
  final List<String> _badges = ['À LA UNE', 'NOUVEL ENSEIGNEMENT', 'RECOMMANDÉ'];

  @override
  void initState() {
    super.initState();
    _loadTeachings();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachings() async {
    try {
      final teachings = await TeachingService.getAllTeachings();
      
      // Filtrer uniquement les enseignements avec des URLs Cloudinary valides
      final validTeachings = teachings
          .where((t) => t.artworkUrl.isNotEmpty && 
                        (t.artworkUrl.startsWith('http://') || 
                         t.artworkUrl.startsWith('https://')))
          .toList();
      
      // Mélanger aléatoirement
      validTeachings.shuffle(Random());
      
      // Prendre maximum 5 enseignements pour le carrousel
      final selected = validTeachings.take(5).toList();
      
      if (mounted) {
        setState(() {
          _teachings = selected;
          _isLoading = false;
        });
        
        if (_teachings.isNotEmpty && _teachings.length > 1) {
          _pageController.addListener(_onPageChanged);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement enseignements carrousel: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      setState(() {
        _currentIndex = _pageController.page!.round();
      });
    }
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _teachings.length > 1) {
        _autoPlay();
      }
    });
  }

  void _autoPlay() {
    if (!mounted || _teachings.length <= 1) return;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      
      if (_currentIndex < _teachings.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      
      _autoPlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 256.h,
        child: Center(
          child: CircularProgressIndicator(
            color: MyKOGColors.accent,
            strokeWidth: 2.w,
          ),
        ),
      );
    }

    if (_teachings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 256.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _teachings.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildCarouselSlide(_teachings[index], index);
            },
          ),
        ),
        SizedBox(height: 12.h),
        // Indicateurs de progression
        _buildProgressIndicators(),
      ],
    );
  }

  Widget _buildCarouselSlide(Teaching teaching, int index) {
    final badge = _badges[index % _badges.length];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: teaching.artworkUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MyKOGColors.primaryDark,
                        MyKOGColors.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: MyKOGColors.accent,
                      strokeWidth: 2.w,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MyKOGColors.primaryDark,
                        MyKOGColors.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: MyKOGColors.accent,
                      size: 48.w,
                    ),
                  ),
                ),
              ),
            ),
            
            // Overlay gradient (du noir en bas vers transparent en haut)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            // Contenu en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: badge == 'À LA UNE' 
                            ? MyKOGColors.accent 
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: badge == 'À LA UNE' 
                              ? Colors.black 
                              : Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // Titre
                    Text(
                      teaching.title,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    
                    // Description
                    Text(
                      teaching.description?.isNotEmpty == true
                          ? teaching.description!
                          : 'Découvrez cet enseignement inspirant',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[300],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton play en bas à droite
            Positioned(
              bottom: 20.h,
              right: 20.w,
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: MyKOGColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MyKOGColors.accent.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Implémenter la lecture
                    },
                    borderRadius: BorderRadius.circular(24.r),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 28.w,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    if (_teachings.length <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _teachings.length,
        (index) => _buildIndicatorDot(index),
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isActive = index == _currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: isActive ? 24.w : 6.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: isActive
            ? MyKOGColors.accent
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }
}
