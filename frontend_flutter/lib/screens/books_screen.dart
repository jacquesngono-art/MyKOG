import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:MyKOG/models/book.dart';
import 'package:MyKOG/services/book_service.dart';
import 'package:MyKOG/widgets/modern_book_tile.dart';
import 'package:MyKOG/theme.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await BookService.getAllBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) return _books;
    return _books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (book.author?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (book.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  Future<void> _openBook(Book book) async {
    Clipboard.setData(ClipboardData(text: book.pdfUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien copié: ${book.title}'),
          backgroundColor: MyKOGColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _filteredBooks.isEmpty
                    ? _buildEmpty()
                    : _isGridView
                        ? _buildGridView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: MyKOGColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: MyKOGColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Books',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              _buildViewToggle(),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(25.r),
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: _isGridView,
            onTap: () => setState(() => _isGridView = true),
          ),
          _buildToggleButton(
            icon: Icons.list_rounded,
            isSelected: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected ? MyKOGColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(
          icon,
          size: 20.w,
          color: isSelected ? Colors.black : MyKOGColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: MyKOGColors.accent.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MyKOGColors.textPrimary,
            ),
        decoration: InputDecoration(
          hintText: 'Rechercher un livre...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MyKOGColors.textSecondary,
              ),
          prefixIcon: Icon(Icons.search, color: MyKOGColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: MyKOGColors.accent),
          SizedBox(height: 16.h),
          Text(
            'Chargement des livres...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MyKOGColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64.w,
            color: MyKOGColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Aucun livre trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MyKOGColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];
        return _buildBookCard(book, index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];
        return ModernBookTile(
          book: book,
        );
      },
    );
  }

  Widget _buildBookCard(Book book, int index) {
    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        decoration: BoxDecoration(
          color: MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MyKOGColors.primaryDark,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MyKOGColors.accent.withValues(alpha: 0.3),
                      MyKOGColors.primaryDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book,
                    size: 48.w,
                    color: MyKOGColors.accent,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: MyKOGColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    if (book.author != null)
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                      ),
                    const Spacer(),
                    if (book.fileSize != null)
                      Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 12.w,
                            color: MyKOGColors.textTertiary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            book.fileSize!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: MyKOGColors.textTertiary,
                                      fontSize: 10.sp,
                                    ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn()
        .scale(curve: Curves.easeOutCubic);
  }

  Widget _buildBookListItem(Book book, int index) {
    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: MyKOGColors.primaryDark,
                borderRadius: BorderRadius.circular(10.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MyKOGColors.accent.withValues(alpha: 0.3),
                    MyKOGColors.primaryDark,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book,
                  size: 28.w,
                  color: MyKOGColors.accent,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  if (book.author != null)
                    Text(
                      book.author!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyKOGColors.textSecondary,
                          ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      if (book.fileSize != null) ...[
                        Icon(
                          Icons.storage,
                          size: 12.w,
                          color: MyKOGColors.textTertiary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          book.fileSize!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textTertiary,
                                    fontSize: 10.sp,
                                  ),
                        ),
                        SizedBox(width: 12.w),
                      ],
                      if (book.pageCount != null) ...[
                        Icon(
                          Icons.article_outlined,
                          size: 12.w,
                          color: MyKOGColors.textTertiary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${book.pageCount} pages',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textTertiary,
                                    fontSize: 10.sp,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: MyKOGColors.textSecondary,
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn()
        .slideX(curve: Curves.easeOutCubic);
  }
}
