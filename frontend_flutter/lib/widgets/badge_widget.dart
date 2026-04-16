import 'package:flutter/material.dart';
import 'package:MyKOG/theme.dart';

class BadgeWidget extends StatefulWidget {
  final Widget child;
  final bool showBadge;
  final Color? badgeColor;
  final double? badgeSize;
  final bool shouldBlink;

  const BadgeWidget({
    super.key,
    required this.child,
    required this.showBadge,
    this.badgeColor,
    this.badgeSize,
    this.shouldBlink = true,
  });

  @override
  State<BadgeWidget> createState() => _BadgeWidgetState();
}

class _BadgeWidgetState extends State<BadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.showBadge && widget.shouldBlink) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BadgeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBadge && widget.shouldBlink) {
      if (!_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }
    } else {
      _blinkController.stop();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBadge) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: -2,
          top: -2,
          child: widget.shouldBlink
              ? FadeTransition(
                  opacity: _blinkAnimation,
                  child: Container(
                    width: widget.badgeSize ?? 10,
                    height: widget.badgeSize ?? 10,
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MyKOGColors.primaryDark,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.badgeColor ?? Colors.green)
                              .withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  width: widget.badgeSize ?? 10,
                  height: widget.badgeSize ?? 10,
                  decoration: BoxDecoration(
                    color: widget.badgeColor ?? Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MyKOGColors.primaryDark,
                      width: 1.5,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

