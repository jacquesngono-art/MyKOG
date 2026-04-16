import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'dart:math';
import '../services/first_launch_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  late AnimationController breathingCtrl;
  late AnimationController meditateCtrl;
  late AnimationController exploreCtrl;

  @override
  void initState() {
    super.initState();

    breathingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    meditateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    exploreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    breathingCtrl.dispose();
    meditateCtrl.dispose();
    exploreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == 2;

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: [
                  _buildPage(
                    title: "Bienvenu sur MyKOG",
                    subtitle: "Restez connectez,\n a votre église.",
                    animation: _BreathingAnimation(controller: breathingCtrl),
                  ),
                  _buildPage(
                    title: "Enseignement",
                    subtitle:
                        "Accedez a une large bibliotheque d'enseignement\n.",
                    animation: _MeditationAnimation(controller: meditateCtrl),
                  ),
                  _buildPage(
                    title: "Explore",
                    subtitle: "Suivez le culte en live\n.",
                    animation: _ExploreAnimation(controller: exploreCtrl),
                  ),
                ],
              ),
            ),
            _buildDots(),
            SizedBox(height: 30.h),
            _buildButton(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required Widget animation,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 50.h),
        animation,
        SizedBox(height: 50.h),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: MyKOGColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: MyKOGColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          height: 8.h,
          width: _pageIndex == index ? 24.w : 8.w,
          decoration: BoxDecoration(
            color: _pageIndex == index ? MyKOGColors.accent : MyKOGColors.textTertiary,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(bool isLast) {
    return SizedBox(
      width: 200.w,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () async {
          if (isLast) {
            // Marquer l'onboarding comme complété
            await FirstLaunchService.setOnboardingCompleted();
            
            // Vérifier si l'inscription est déjà faite
            final isRegistered = await FirstLaunchService.isRegistrationCompleted();
            
            if (isRegistered) {
              // Si déjà inscrit, aller directement à l'app
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              // Sinon, aller à l'inscription
              Navigator.pushReplacementNamed(context, '/register');
            }
          } else {
            _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: MyKOGColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: Text(
          isLast ? "Commencer" : "Suivant",
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Animations
class _BreathingAnimation extends StatelessWidget {
  final AnimationController controller;

  const _BreathingAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + controller.value * 0.2,
          child: Container(
            width: 150.w,
            height: 150.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  MyKOGColors.accent.withValues(alpha: 0.3),
                  MyKOGColors.accent.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.favorite,
              size: 80.sp,
              color: MyKOGColors.accent,
            ),
          ),
        );
      },
    );
  }
}

class _MeditationAnimation extends StatelessWidget {
  final AnimationController controller;

  const _MeditationAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * pi,
          child: Container(
            width: 150.w,
            height: 150.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: MyKOGColors.accent,
                width: 3.w,
              ),
            ),
            child: Icon(
              Icons.self_improvement,
              size: 80.sp,
              color: MyKOGColors.accent,
            ),
          ),
        );
      },
    );
  }
}

class _ExploreAnimation extends StatelessWidget {
  final AnimationController controller;

  const _ExploreAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            sin(controller.value * 2 * pi) * 20.w,
            0,
          ),
          child: Container(
            width: 150.w,
            height: 150.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  MyKOGColors.accent.withValues(alpha: 0.2),
                  MyKOGColors.accent.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.explore,
              size: 80.sp,
              color: MyKOGColors.accent,
            ),
          ),
        );
      },
    );
  }
}