import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/first_launch_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  static const List<Map<String, dynamic>> _pages = [
    {
      'title': 'VISION',
      'text':
          '« RÉVÉLER LA LUMIÈRE ET LA GLOIRE DE CHRIST AUX NATIONS ET AUX ROIS »',
      'reference': 'COLOSSIENS 1:27',
      'isMission': false,
    },
    {
      'title': 'MANDAT\n(18 OCTOBRE 2018)',
      'text': 'VA ET DÉLIVRE MON PEUPLE,\nJE SERAI AVEC TOI',
      'reference': '',
      'isMission': false,
    },
    {
      'title': 'ORDRE DE MISSION',
      'text': '',
      'reference': '',
      'isMission': true,
    },
  ];

  static const List<String> _missions = [
    'Conduire le peuple de Dieu à la repentance et à la véritable conversion',
    'Faire connaître au peuple de Dieu leur identité en Christ',
    'Conduire le peuple de Dieu dans son couloir d’appel et vers sa destinée',
    'Annoncer les mystères du royaume',
    'Élargir les limites de leurs pensées',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: [
                  for (final page in _pages) _buildPage(page),
                ],
              ),
            ),
            _buildDots(),
            SizedBox(height: 30.h),
            _buildButton(isLast),
            SizedBox(height: 20.h),
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
            color: context.appColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: context.appColors.textSecondary,
          ),
          SizedBox(height: 24.h),
          if (page['isMission']) ...[
            for (var i = 0; i < _missions.length; i++)
              _buildMissionItem(i + 1, _missions[i]),
          ] else ...[
            Text(
              page['text'],
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                color: MyKOGColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (page['reference'] != null && page['reference'].isNotEmpty) ...[
              SizedBox(height: 28.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MyKOGColors.accent.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Text(
                  page['reference'],
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    color: MyKOGColors.accentLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildMissionItem(int number, String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MyKOGColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  MyKOGColors.accent,
                  MyKOGColors.accentLight,
                ],
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14.5.sp,
                  color: MyKOGColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          height: 8.h,
          width: _pageIndex == index ? 24.w : 8.w,
          decoration: BoxDecoration(
            color: _pageIndex == index ? MyKOGColors.accent : context.appColors.textTertiary,
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

            if (!mounted) return;

            // Vérifier si l'inscription est déjà faite
            final isRegistered =
                await FirstLaunchService.isRegistrationCompleted();

            if (!mounted) return;

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
