import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/theme.dart';

class CoverFlowList extends StatefulWidget {
  final List<Teaching> teachings;
  final Function(Teaching) onTeachingTap;
  final double itemWidth;
  final double itemHeight;

  const CoverFlowList({
    super.key,
    required this.teachings,
    required this.onTeachingTap,
    this.itemWidth = 160,
    this.itemHeight = 160,
  });

  @override
  State<CoverFlowList> createState() => _CoverFlowListState();
}

class _CoverFlowListState extends State<CoverFlowList> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.45);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teachings.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.itemHeight + 60,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.teachings.length,
        itemBuilder: (context, index) {
          final teaching = widget.teachings[index];
          final isCenter = index == _currentIndex;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
              }

              return Center(
                child: SizedBox(
                  height: Curves.easeOut.transform(value) * widget.itemHeight,
                  width: Curves.easeOut.transform(value) * widget.itemWidth,
                  child: child,
                ),
              );
            },
            child: _buildCoverItem(teaching, isCenter),
          );
        },
      ),
    );
  }

  Widget _buildCoverItem(Teaching teaching, bool isCenter) {
    return GestureDetector(
      onTap: () => widget.onTeachingTap(teaching),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isCenter ? 0.4 : 0.2),
                      blurRadius: isCenter ? 12 : 6,
                      offset: Offset(0, isCenter ? 6 : 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      teaching.artworkUrl.startsWith('assets/')
                          ? Image.asset(
                              teaching.artworkUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: MyKOGColors.secondary,
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: teaching.artworkUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: MyKOGColors.secondary,
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: MyKOGColors.secondary,
                                child: const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play button overlay
                      if (isCenter)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: MyKOGColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ).animate(delay: 200.ms).scale(),
                      // New badge
                      if (teaching.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MyKOGColors.success,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      // Featured badge
                      if (teaching.isFeatured)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: MyKOGColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (isCenter) ...[
              const SizedBox(height: 8),
              Text(
                teaching.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                teaching.speaker,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MyKOGColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
