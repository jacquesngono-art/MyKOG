import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/modern_list_tile.dart';
import 'package:MyKOG/widgets/modern_teaching_tile.dart';
import 'package:MyKOG/widgets/modern_book_tile.dart';
import 'package:MyKOG/models/teaching.dart';

class DemoModernListsScreen extends StatelessWidget {
  const DemoModernListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      appBar: AppBar(
        title: const Text('Design Moderne'),
        backgroundColor: MyKOGColors.primaryDark,
        foregroundColor: MyKOGColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSectionTitle('Exemples de Listes Modernes'),
          SizedBox(height: 16.h),
          
          // Exemple 1: Icônes
          _buildIconListSection(),
          SizedBox(height: 24.h),
          
          // Exemple 2: Badges
          _buildBadgeListSection(),
          SizedBox(height: 24.h),
          
          // Exemple 3: Teaching Tile
          _buildTeachingListSection(),
          SizedBox(height: 24.h),
          
          // Exemple 4: Book Tile
          _buildBookListSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: MyKOGColors.textPrimary,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildIconListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste avec Icônes',
          style: TextStyle(
            color: MyKOGColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        ModernIconListTile(
          title: 'Paramètres',
          subtitle: 'Gérez les préférences de l\'application',
          icon: Icons.settings_rounded,
          iconColor: MyKOGColors.accent,
          onTap: () {},
        ),
        
        SizedBox(height: 8.h),
        
        ModernIconListTile(
          title: 'Téléchargements',
          subtitle: '12 fichiers téléchargés',
          icon: Icons.download_rounded,
          iconColor: Colors.green,
          onTap: () {},
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '12',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 8.h),
        
        ModernIconListTile(
          title: 'Favoris',
          subtitle: 'Contenus enregistrés',
          icon: Icons.favorite_rounded,
          iconColor: Colors.red,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBadgeListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste avec Badges',
          style: TextStyle(
            color: MyKOGColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        ModernBadgeListTile(
          title: 'Enseignement du jour',
          subtitle: 'La puissance de la prière',
          badgeText: 'A',
          badgeColor: MyKOGColors.accent,
          onTap: () {},
        ),
        
        SizedBox(height: 8.h),
        
        ModernBadgeListTile(
          title: 'Culte prophétique',
          subtitle: 'Message spécial',
          badgeText: 'B',
          badgeColor: Colors.purple,
          onTap: () {},
        ),
        
        SizedBox(height: 8.h),
        
        ModernBadgeListTile(
          title: 'Étude biblique',
          subtitle: 'Livre de l'Apocalypse',
          badgeText: 'C',
          badgeColor: Colors.blue,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildTeachingListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste d\'Enseignements',
          style: TextStyle(
            color: MyKOGColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        ModernTeachingTile(
          teaching: Teaching(
            id: '1',
            title: 'La foi qui déplace les montagnes',
            speaker: 'Pasteur Jacques',
            audioUrl: 'https://example.com/audio1.mp3',
            artworkUrl: 'assets/images/teaching1.jpg',
            duration: Duration(minutes: 45),
            publishedAt: DateTime.now().subtract(const Duration(days: 1)),
            category: 'Culte d\'Impact',
            typeCulte: 'Culte d\'Impact',
            isNew: true,
            isFeatured: true,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        ModernTeachingTile(
          teaching: Teaching(
            id: '2',
            title: 'Le pouvoir de la prière',
            speaker: 'Soeur Marie',
            audioUrl: 'https://example.com/audio2.mp3',
            artworkUrl: 'assets/images/teaching2.jpg',
            duration: Duration(minutes: 32),
            publishedAt: DateTime.now().subtract(const Duration(days: 3)),
            category: 'Culte Prophétique',
            typeCulte: 'Culte Prophétique',
            isFeatured: false,
          ),
        ),
      ],
    );
  }

  Widget _buildBookListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste de Livres',
          style: TextStyle(
            color: MyKOGColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        ModernBookTile(
          book: Book(
            id: '1',
            title: 'La Puissance de la Prière',
            author: 'John Smith',
            pdfUrl: 'https://example.com/book1.pdf',
            fileSize: '2.5 MB',
            pageCount: 156,
            category: 'Spiritualité',
          ),
        ),
        
        SizedBox(height: 8.h),
        
        ModernBookTile(
          book: Book(
            id: '2',
            title: 'Vivre par la Foi',
            author: 'Sarah Johnson',
            pdfUrl: 'https://example.com/book2.pdf',
            fileSize: '1.8 MB',
            pageCount: 98,
            category: 'Développement Personnel',
          ),
        ),
      ],
    );
  }
}

// Classes de données pour la démo
class Book {
  final String id;
  final String title;
  final String? author;
  final String pdfUrl;
  final String? fileSize;
  final int? pageCount;
  final String? category;

  Book({
    required this.id,
    required this.title,
    this.author,
    required this.pdfUrl,
    this.fileSize,
    this.pageCount,
    this.category,
  });
}
