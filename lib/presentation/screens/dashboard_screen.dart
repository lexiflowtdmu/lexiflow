import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../core/constants/daily_words.dart';
import '../../core/utils/page_transitions.dart';
import '../../services/cloudflare_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/flashcard_bloc.dart';
import 'vocab_detail_screen.dart';
import 'flashcard_study_screen.dart';
import 'ocr_translator_screen.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';
import 'bookmarks_screen.dart';
import 'friends_screen.dart';
import 'word_battle_screen.dart';
import 'group_leaderboard_screen.dart';
import 'farm_screen.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import '../widgets/dashboard/word_of_day_card.dart';
import '../widgets/dashboard/study_stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Map<String, String> _wordOfTheDay = {};

  CloudflareService get _cloudflareService => context.read<CloudflareService>();

  bool _loadingStats = true;
  int _totalCards = 0;
  int _newCards = 0;
  int _learningCards = 0;
  int _memorizedCards = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _wordOfTheDay = DailyWords.getWordOfTheDay();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    context.read<SearchBloc>().add(HistoryLoadRequested());
    context.read<FlashcardBloc>().add(FlashcardLoadRequested());
    _loadStatistics();
    _loadStreak();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loadingStats = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final summary = await _cloudflareService.getDeckSummary();
        if (mounted) {
          setState(() {
            _totalCards = summary['totalCards'] ?? 0;
            _newCards = summary['newCards'] ?? 0;
            _learningCards = summary['learningCards'] ?? 0;
            _memorizedCards =
                (_totalCards - _newCards - _learningCards).clamp(0, _totalCards);
            _loadingStats = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingStats = false);
      }
    } else {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadStreak() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final streak = await _cloudflareService.getStudyStreak(uid);
        if (mounted) setState(() => _streak = streak);
      } catch (_) {}
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SearchBloc>().add(SearchSuggestionsRequested(query));
    });
    setState(() {});
  }

  void _searchWord(String word) {
    if (word.trim().isNotEmpty) {
      context.read<SearchBloc>().add(const SearchSuggestionsRequested(''));
      context.read<SearchBloc>().add(SearchWordSubmitted(word.trim()));
      _searchController.clear();
      setState(() {});
      Navigator.push(
        context,
        SlidePageRoute(page: VocabDetailScreen(searchWord: word.trim())),
      ).then((_) => _loadDashboardData());
    }
  }

  Future<void> _deleteHistory(String word) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _cloudflareService.deleteHistoryItem(uid, word);
      if (mounted) context.read<SearchBloc>().add(HistoryLoadRequested());
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử tra từ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: TextStyle(color: context.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _cloudflareService.clearAllHistory(uid);
      if (mounted) {
        context.read<SearchBloc>().add(HistoryLoadRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ lịch sử tra từ')),
        );
      }
    }
  }

  String _formatUserName(String rawEmail) {
    if (rawEmail.isEmpty) return 'Học viên';
    final username =
        rawEmail.contains('@') ? rawEmail.split('@')[0] : rawEmail;
    if (RegExp(r'^\d+$').hasMatch(username)) return 'Học viên';
    return username;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String rawEmail = 'Học viên';
    if (authState is AuthAuthenticated) {
      rawEmail = authState.user.email ?? 'Học viên';
    }
    final displayName = _formatUserName(rawEmail);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: _AppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: context.primaryColor),
            tooltip: 'Thống kê học tập',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const AnalyticsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.leaderboard_rounded, color: AppTheme.accentOrange),
            tooltip: 'BXH Nhóm Học Tập',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const GroupLeaderboardScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.sports_esports_rounded, color: context.primaryColor),
            tooltip: 'Thách Đấu',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const WordBattleScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.people_outline_rounded, color: context.textColor),
            tooltip: 'Bạn bè',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const FriendsScreen()),
            ).then((_) => _loadDashboardData()),
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border_rounded, color: context.textColor),
            tooltip: 'Từ đã lưu',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const BookmarksScreen()),
            ).then((_) => _loadDashboardData()),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textColor),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.push(
              context,
              SlidePageRoute(page: const SettingsScreen()),
            ).then((_) => _loadDashboardData()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;
          return RefreshIndicator(
            onRefresh: () async => _loadDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: isWide
                      ? _buildDesktopLayout(context, displayName)
                      : _buildMobileLayout(context, displayName),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── DESKTOP 2-COLUMN LAYOUT ──────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, String displayName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(context, displayName),
              const SizedBox(height: 20),
              _buildSearchInput(context),
              _buildSuggestionsOverlay(context),
              const SizedBox(height: 28),
              const _SectionTitle(label: 'Công cụ học tập'),
              const SizedBox(height: 12),
              _buildBentoGrid(context),
              const SizedBox(height: 28),
              const _SectionTitle(label: 'Mini Games'),
              const SizedBox(height: 12),
              _buildMiniGameRow(context),
              const SizedBox(height: 28),
              _buildHistorySection(context),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakBanner(context),
              const SizedBox(height: 24),
              const _SectionTitle(label: 'Từ vựng mỗi ngày'),
              const SizedBox(height: 10),
              WordOfDayCard(
                wordOfTheDay: _wordOfTheDay,
                onTapWord: _searchWord,
              ),
              const SizedBox(height: 24),
              const _SectionTitle(label: 'Tiến trình ghi nhớ'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, SlidePageRoute(page: const AnalyticsScreen())),
                child: StudyStatsCard(
                  loadingStats: _loadingStats,
                  totalCards: _totalCards,
                  newCards: _newCards,
                  learningCards: _learningCards,
                  memorizedCards: _memorizedCards,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MOBILE SINGLE-COLUMN LAYOUT ──────────────────────────
  Widget _buildMobileLayout(BuildContext context, String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(context, displayName),
        const SizedBox(height: 18),
        _buildSearchInput(context),
        _buildSuggestionsOverlay(context),
        const SizedBox(height: 20),
        _buildStreakBanner(context),
        const SizedBox(height: 24),
        const _SectionTitle(label: 'Từ vựng mỗi ngày'),
        const SizedBox(height: 10),
        WordOfDayCard(
          wordOfTheDay: _wordOfTheDay,
          onTapWord: _searchWord,
        ),
        const SizedBox(height: 24),
        const _SectionTitle(label: 'Tiến trình ghi nhớ'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, SlidePageRoute(page: const AnalyticsScreen())),
          child: StudyStatsCard(
            loadingStats: _loadingStats,
            totalCards: _totalCards,
            newCards: _newCards,
            learningCards: _learningCards,
            memorizedCards: _memorizedCards,
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(label: 'Công cụ học tập'),
        const SizedBox(height: 12),
        _buildBentoGrid(context),
        const SizedBox(height: 28),
        const _SectionTitle(label: 'Mini Games'),
        const SizedBox(height: 12),
        _buildMiniGameRow(context),
        const SizedBox(height: 28),
        _buildHistorySection(context),
      ],
    );
  }

  // ── COMPONENTS ───────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context, String displayName) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.primaryColor, AppTheme.primaryBlue],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, $displayName',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Hôm nay bạn muốn học từ vựng nào?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: context.subTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: _searchWord,
        style: GoogleFonts.outfit(color: context.textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Tra từ vựng Oxford (vd: serendipity, resilient...)',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: context.subTextColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Icon(Icons.search_rounded,
                color: context.primaryColor, size: 22),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: context.subTextColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<SearchBloc>()
                        .add(const SearchSuggestionsRequested(''));
                    setState(() {});
                  },
                ),
              IconButton(
                icon: Icon(Icons.camera_alt_outlined,
                    color: AppTheme.accentOrange, size: 20),
                tooltip: 'OCR Camera',
                onPressed: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const OcrTranslatorScreen()),
                ).then((_) => _loadDashboardData()),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_rounded,
                    color: context.primaryColor, size: 20),
                onPressed: () => _searchWord(_searchController.text),
              ),
              const SizedBox(width: 4),
            ],
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SuggestionsLoadSuccess && state.suggestions.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: state.suggestions.map((s) {
                return ListTile(
                  leading: Icon(Icons.search_rounded,
                      color: context.subTextColor, size: 18),
                  title: Text(
                    s,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, color: context.textColor),
                  ),
                  dense: true,
                  onTap: () => _searchWord(s),
                );
              }).toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStreakBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu học tập',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _streak > 0 ? '$_streak ngày liên tiếp' : 'Bắt đầu ngay',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BlocBuilder<FlashcardBloc, FlashcardState>(
            builder: (context, state) {
              int cardCount = 0;
              if (state is FlashcardsLoadSuccess) {
                cardCount = state.vocabs.length;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardCount > 0
                        ? 'Có $cardCount từ cần ôn tập hôm nay'
                        : 'Tuyệt! Bạn đã hoàn thành hôm nay.',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalCards > 0
                          ? (_memorizedCards / _totalCards)
                          : 0.0,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.style_rounded,
                title: 'Thẻ Ghi Nhớ',
                subtitle: 'SM-2 ôn tập',
                accentColor: context.primaryColor,
                bgColor: context.softBgColor,
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const FlashcardStudyScreen()),
                ).then((_) => _loadDashboardData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.quiz_rounded,
                title: 'Trắc Nghiệm',
                subtitle: 'Kiểm tra trí nhớ',
                accentColor: AppTheme.accentPurple,
                bgColor: context.isDark
                    ? AppTheme.accentPurple.withValues(alpha: 0.15)
                    : AppTheme.accentPurple.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const QuizScreen()),
                ).then((_) => _loadDashboardData()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.camera_alt_rounded,
                title: 'Dịch Camera',
                subtitle: 'OCR từ hình ảnh',
                accentColor: AppTheme.accentOrange,
                bgColor: context.isDark
                    ? AppTheme.accentOrange.withValues(alpha: 0.15)
                    : AppTheme.accentOrange.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const OcrTranslatorScreen()),
                ).then((_) => _loadDashboardData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoTile(
                icon: Icons.bookmarks_rounded,
                title: 'Từ Đã Lưu',
                subtitle: 'Bộ sưu tập cá nhân',
                accentColor: AppTheme.cyanAccent,
                bgColor: context.isDark
                    ? AppTheme.cyanAccent.withValues(alpha: 0.15)
                    : AppTheme.cyanAccent.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(page: const BookmarksScreen()),
                ).then((_) => _loadDashboardData()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniGameRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniGameTile(
            emoji: '🌾',
            title: 'Nông Trại',
            subtitle: 'Trồng cây · Giao đơn',
            gradient: LinearGradient(
              colors: [
                AppTheme.successGreen.withValues(alpha: 0.7),
                AppTheme.successGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: const FarmScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniGameTile(
            emoji: '🏠',
            title: 'Nhà Pet',
            subtitle: 'Nuôi thú · Trang trí',
            gradient: LinearGradient(
              colors: [
                context.primaryColor.withValues(alpha: 0.7),
                context.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: const HomeScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(label: 'Lịch sử tra từ'),
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is HistoryLoadSuccess && state.history.isNotEmpty) {
                  return TextButton(
                    onPressed: _clearAllHistory,
                    child: Text(
                      'Xóa tất cả',
                      style: GoogleFonts.outfit(
                        color: context.errorRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is HistoryLoadSuccess) {
              final history = state.history;
              if (history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Chưa có lịch sử tra cứu nào.',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.subTextColor),
                    ),
                  ),
                );
              }
              final displayCount = history.length > 5 ? 5 : history.length;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayCount,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final word = item['word'] ?? '';
                  final translation = item['translation'] ?? '';
                  return Dismissible(
                    key: Key(word),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: context.errorRed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteHistory(word),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: context.borderColor, width: 1),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.softBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.history_rounded,
                              color: context.primaryColor, size: 20),
                        ),
                        title: Text(
                          word,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        subtitle: Text(
                          translation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: context.subTextColor,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: context.subTextColor),
                        onTap: () => _searchWord(word),
                      ),
                    ),
                  );
                },
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Tra từ vựng để lưu lịch sử tại đây.',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.subTextColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── SHARED COMPONENTS ─────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.primaryColor, context.accentColor],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'LexiFlow',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.textColor,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: context.subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniGameTile extends StatelessWidget {
  const _MiniGameTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
