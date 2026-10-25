import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../services/cloudflare_service.dart';
import 'vocab_detail_screen.dart';
import '../../core/utils/page_transitions.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  CloudflareService get _cloudflareService => context.read<CloudflareService>();
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, String>> _filteredBookmarks = [];
  bool _isLoading = true;
  bool _isAscending = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _searchController.addListener(_filterBookmarks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final list = await _cloudflareService.getBookmarksList(uid);
      if (mounted) {
        setState(() {
          _bookmarks = list;
          _filteredBookmarks = List.from(_bookmarks);
          _sortBookmarks();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterBookmarks() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBookmarks = List.from(_bookmarks);
      } else {
        _filteredBookmarks = _bookmarks
            .where((item) =>
                item['word']!.toLowerCase().contains(query) ||
                item['translation']!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _sortBookmarks() {
    setState(() {
      _filteredBookmarks.sort((a, b) {
        return _isAscending
            ? a['word']!.toLowerCase().compareTo(b['word']!.toLowerCase())
            : b['word']!.toLowerCase().compareTo(a['word']!.toLowerCase());
      });
    });
  }

  Future<void> _removeBookmark(String word) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _cloudflareService.toggleBookmark(uid, word, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã bỏ đánh dấu từ "$word"')),
      );
      _loadBookmarks();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Từ Vựng Đã Lưu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
        actions: [
          IconButton(
            icon: Icon(
              _isAscending ? Icons.sort_by_alpha_rounded : Icons.sort_rounded,
              color: context.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortBookmarks();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Search Input
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: context.textColor),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm từ đã lưu...',
                  hintStyle: GoogleFonts.outfit(color: context.subTextColor.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search_rounded, color: context.subTextColor),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bookmarks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBookmarks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border_rounded, size: 64, color: context.subTextColor),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có từ vựng nào được lưu',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hãy tra cứu từ mới và bấm biểu tượng Bookmark để lưu.',
                                style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredBookmarks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _filteredBookmarks[index];
                            final word = item['word'] ?? '';
                            final translation = item['translation'] ?? '';

                            return Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: context.borderColor, width: 1),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.softBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.star_rounded, color: context.primaryColor),
                                ),
                                title: Text(
                                  word,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  translation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: context.errorRed),
                                  onPressed: () => _removeBookmark(word),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      page: VocabDetailScreen(searchWord: word),
                                    ),
                                  ).then((_) => _loadBookmarks());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

