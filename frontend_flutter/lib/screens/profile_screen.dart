import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/providers/theme_provider.dart';
import 'package:MyKOG/providers/language_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';
import 'package:MyKOG/screens/language_selection_screen.dart';
import 'package:MyKOG/screens/downloads_management_screen.dart';
import 'package:MyKOG/widgets/connection_mode_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: MyKOGColors.accent),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with profile info
                _buildProfileHeader(context, theme, user, userProvider),

                SizedBox(height: 24.h),

                // Stats section
                _buildStatsSection(context, theme, user),

                SizedBox(height: 32.h),

                // Settings section
                _buildSettingsSection(context, theme, userProvider),

                SizedBox(height: 24.h),

                // Network configuration
                const ConnectionModeSelector(),

                SizedBox(height: 100.h), // Bottom padding for mini player
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, ThemeData theme, user, UserProvider userProvider) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 32.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [MyKOGColors.primaryDark, MyKOGColors.secondary]
              : [theme.colorScheme.surface, theme.colorScheme.primaryContainer],
        ),
      ),
      child: Column(
        children: [
          // Profile picture
          Stack(
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      MyKOGColors.accent,
                      MyKOGColors.accentLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MyKOGColors.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: user.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(user.name),
                        ),
                      )
                    : _buildDefaultAvatar(user.name),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: MyKOGColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MyKOGColors.accent,
                      width: 2.w,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _showEditProfile(context, userProvider),
                    icon: Icon(
                      Icons.edit,
                      color: MyKOGColors.accent,
                      size: 18.w,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ).animate().scale(curve: Curves.easeOutCubic),

          SizedBox(height: 16.h),

          // Name
          Text(
            user.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn().slideY(),

          SizedBox(height: 4.h),

          // Email
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn().slideY(),

          SizedBox(height: 8.h),

          // Member since
          Text(
            'Member since ${_formatDate(user.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn().slideY(),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ThemeData theme, user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              theme,
              'Favorites',
              user.favoriteTeachingIds.length.toString(),
              Icons.favorite,
              Colors.red,
            ).animate(delay: 500.ms).fadeIn().slideX(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              context,
              theme,
              'Downloaded',
              user.downloadedTeachingIds.length.toString(),
              Icons.download,
              MyKOGColors.success,
            ).animate(delay: 600.ms).fadeIn().slideX(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              context,
              theme,
              'Recently Played',
              user.recentlyPlayedIds.length.toString(),
              Icons.history,
              MyKOGColors.accent,
            ).animate(delay: 700.ms).fadeIn().slideX(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, ThemeData theme, String title,
      String value, IconData icon, Color color) {
    return GlassCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.w,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, ThemeData theme, UserProvider userProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ).animate(delay: 800.ms).fadeIn().slideX(),
          SizedBox(height: 16.h),
          GlassCard(
            padding: EdgeInsets.all(8.w),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Downloaded Teachings',
                  subtitle: 'Manage offline content',
                  icon: Icons.download,
                  onTap: () => _showDownloadedTeachings(context),
                ).animate(delay: 900.ms).fadeIn().slideX(),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                _buildSettingsTile(
                  context,
                  title: 'Favorite Teachings',
                  subtitle: 'View your liked content',
                  icon: Icons.favorite,
                  onTap: () => _showFavoriteTeachings(context),
                ).animate(delay: 950.ms).fadeIn().slideX(),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                _buildLanguageTile(context).animate(delay: 960.ms).fadeIn().slideX(),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingsTile(
                      context,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      icon: themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                        activeColor: MyKOGColors.accent,
                      ),
                    ).animate(delay: 950.ms).fadeIn().slideX();
                  },
                ),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return _buildSettingsTile(
                      context,
                      title: 'Notifications',
                      subtitle: 'Push notifications for new content',
                      icon: Icons.notifications,
                      trailing: Switch(
                        value: userProvider.notificationsEnabled,
                        onChanged: (value) =>
                            userProvider.toggleNotifications(value),
                        activeColor: MyKOGColors.accent,
                      ),
                    ).animate(delay: 1000.ms).fadeIn().slideX();
                  },
                ),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                _buildSettingsTile(
                  context,
                  title: 'About MyKOG',
                  subtitle: 'Version 1.0.0',
                  icon: Icons.info,
                  onTap: () => _showAbout(context),
                ).animate(delay: 1050.ms).fadeIn().slideX(),
                Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    height: 1),
                _buildSettingsTile(
                  context,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  onTap: () => _showSignOutDialog(context, userProvider),
                ).animate(delay: 1100.ms).fadeIn().slideX(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? MyKOGColors.accent,
        size: 24.w,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                )
              : null),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(userProvider: userProvider),
    );
  }

  void _showDownloadedTeachings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DownloadsManagementScreen(),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final l10n = AppLocalizations.of(context);
        
        return _buildSettingsTile(
          context,
          title: l10n?.language ?? 'Language',
          subtitle: languageProvider.currentLanguageName,
          icon: Icons.language,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageProvider.currentLanguageFlag,
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSelectionScreen(),
            ),
          ),
        );
      },
    );
  }

  void _showFavoriteTeachings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorite teachings feature coming soon')),
    );
  }

  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'About MyKOG',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'MyKOG is a spiritual audio streaming app that combines the sleek design of Spotify with the elegance of Apple Music, offering an immersive experience for faith-based content.\n\nVersion 1.0.0\nBuilt with Flutter',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: theme.colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Sign Out',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to sign out? Your data will be cleared.',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await userProvider.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully')),
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class EditProfileDialog extends StatefulWidget {
  final UserProvider userProvider;

  const EditProfileDialog({
    super.key,
    required this.userProvider,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = widget.userProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Edit Profile',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.tertiary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.tertiary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty) {
              await widget.userProvider
                  .updateUserName(_nameController.text.trim());
            }
            if (_emailController.text.trim().isNotEmpty) {
              await widget.userProvider
                  .updateUserEmail(_emailController.text.trim());
            }
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profile updated successfully'),
                  backgroundColor: MyKOGColors.success,
                ),
              );
            }
          },
          child: Text(
            'Save',
            style: TextStyle(color: theme.colorScheme.tertiary),
          ),
        ),
      ],
    );
  }
}
