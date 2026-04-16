import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:MyKOG/models/book.dart';
import 'package:MyKOG/theme.dart';

class ModernBookTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool showArtwork;

  const ModernBookTile({
    super.key,
    required this.book,
    this.onTap,
    this.showArtwork = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _openBook(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            // Artwork 80x80 comme code.html
            _buildLibraryBookArtwork(),
            SizedBox(width: 16.w),

            // Titre et sous-titre empilés
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titre style code.html
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      color: MyKOGColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Sous-titre (auteur + pages)
                  Text(
                    '${book.author ?? 'Auteur inconnu'}${book.pageCount != null ? ' • ${book.pageCount} pages' : ''}',
                    style: GoogleFonts.manrope(
                      color: MyKOGColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Bouton menu ou download
            _buildCompactActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryBookArtwork() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MyKOGColors.accent.withValues(alpha: 0.4),
                MyKOGColors.primaryDark,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: MyKOGColors.accent,
              size: 36.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, ThemeData theme) {
    return Text(
      book.title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: MyKOGColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16.sp,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAuthorSection(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: MyKOGColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 14.w,
            color: MyKOGColors.accent,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            book.author!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyKOGColors.textSecondary,
              fontSize: 13.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Row(
      children: [
        // Taille du fichier
        if (book.fileSize != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: MyKOGColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage_rounded,
                  size: 12.w,
                  color: MyKOGColors.primary,
                ),
                SizedBox(width: 4.w),
                Text(
                  book.fileSize!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Nombre de pages
        if (book.pageCount != null) ...[
          if (book.fileSize != null) SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: MyKOGColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 12.w,
                  color: MyKOGColors.accent,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${book.pageCount} pages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.accent,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        Spacer(),

        // Badge PDF
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 0.5.w,
            ),
          ),
          child: Text(
            'PDF',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openBook(context),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: MyKOGColors.textSecondary.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.file_download_outlined,
            color: MyKOGColors.textSecondary,
            size: 20.w,
          ),
        ),
      ),
    );
  }

  void _openBook(BuildContext context) {
    Clipboard.setData(ClipboardData(text: book.pdfUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 Lien PDF copié: ${book.title}'),
          backgroundColor: MyKOGColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
