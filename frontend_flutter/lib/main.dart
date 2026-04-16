import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ignore: unused_import
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:MyKOG/theme.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/providers/theme_provider.dart';
import 'package:MyKOG/providers/teaching_provider.dart';
import 'package:MyKOG/providers/language_provider.dart';
import 'package:MyKOG/providers/badge_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/widgets/responsive_wrapper.dart';
import 'package:MyKOG/services/notification_service.dart';
import 'package:MyKOG/services/navigation_service.dart';
import 'package:MyKOG/services/alarm_service.dart';

import 'package:MyKOG/main_app.dart';
import 'package:MyKOG/screens/onboarding_screen.dart';
import 'package:MyKOG/screens/register_screen.dart';
import 'package:MyKOG/services/first_launch_service.dart';
import 'package:MyKOG/config/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 FORCER Render uniquement (pas de détection locale)
  await ApiConfig.initializeRenderOnly();

  // ⚡ Initialiser Firebase et Audio en parallèle (les 2 critiques)
  await Future.wait<void>([
    Firebase.initializeApp().then((_) {}).catchError((e) {
      debugPrint('⚠️ Erreur initialisation Firebase: $e');
    }),
    JustAudioBackground.init(
      androidNotificationChannelId: 'com.mykog.audio.channel',
      androidNotificationChannelName: 'MyKOG Audio Playback',
      androidNotificationChannelDescription: 'Lecture audio en arrière-plan',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  ]);

  // ⚡ Lancer l'app IMMÉDIATEMENT, les services non-critiques s'initialisent après
  runApp(const MyKOGApp());

  // ⚡ Initialisations non-bloquantes (en arrière-plan après le premier frame)
  _initBackgroundServices();
}

/// Services non-critiques initialisés après le rendu du premier frame
void _initBackgroundServices() {
  Future.microtask(() async {
    try {
      await NotificationService().initialize();
      await NotificationService().subscribeToDefaultTopics();
    } catch (e) {
      debugPrint('⚠️ Erreur initialisation notifications: $e');
    }

    try {
      await AlarmService().initialize();
    } catch (e) {
      debugPrint('⚠️ Erreur initialisation alarmes: $e');
    }
  });
}

class MyKOGApp extends StatelessWidget {
  const MyKOGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (_) => TeachingProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return ResponsiveWrapper(
            child: MaterialApp(
              title: 'MyKOG',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,

              // Localizations
              locale: languageProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,

              // 👇 IMPORTANT : système de routes pour navigation
              navigatorKey: NavigationService().navigatorKey,
              // Utiliser InitialRouteSelector pour déterminer la route initiale
              home: const InitialRouteSelector(),

              routes: {
                "/onboarding": (context) => const OnboardingScreen(),
                "/register": (context) => const RegisterScreen(),
                "/home": (context) => const MainApp(),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Widget qui détermine quelle route afficher au démarrage
class InitialRouteSelector extends StatefulWidget {
  const InitialRouteSelector({super.key});

  @override
  State<InitialRouteSelector> createState() => _InitialRouteSelectorState();
}

class _InitialRouteSelectorState extends State<InitialRouteSelector> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Attendre un minimum pour éviter le flash blanc
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final shouldShowOnboarding =
        await FirstLaunchService.shouldShowOnboarding();
    final shouldShowRegistration =
        await FirstLaunchService.shouldShowRegistration();

    if (shouldShowOnboarding) {
      // Premier lancement : afficher l'onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (shouldShowRegistration) {
      // Onboarding fait mais pas d'inscription : afficher l'inscription
      Navigator.of(context).pushReplacementNamed('/register');
    } else {
      // Tout est fait : aller directement à l'app
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un écran de chargement pendant la vérification
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/kog.png',
              width: 80.w,
              height: 80.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 12.h),
            Text(
              'MyKOG',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: MyKOGColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.sp,
                  ),
            ),
            SizedBox(height: 24.h),
            const CircularProgressIndicator(
              color: MyKOGColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
