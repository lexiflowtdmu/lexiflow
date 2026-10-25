import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flip_card/flip_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../data/models/vocab_model.dart';
import '../bloc/flashcard_bloc.dart';
import '../bloc/settings_cubit.dart';

class CustomReviewScreen extends StatefulWidget {
  const CustomReviewScreen({super.key});

  @override
  State<CustomReviewScreen> createState() => _CustomReviewScreenState();
}

class _CustomReviewScreenState extends State<CustomReviewScreen> {
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  late AudioPlayer _audioPlayer;

  String _selectedCategory = 'Tất cả';
  int _currentIndex = 0;
  int _rememberedCount = 0;
  int _reviewCount = 0;
  bool _isCardRevealed = false;

  final List<String> _categories = [
    'Tất cả',
    'Work & Business',
    'IELTS Academic',
    'Daily Conversation',
    'Công Nghệ / Tech',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    context.read<FlashcardBloc>().add(FlashcardLoadRequested());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String word) async {
    try {
      final url = 'https://dict.youdao.com/dictvoice?type=2&audio=$word';
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {}
  }

  List<Vocab> _getFilteredVocabs(List<Vocab> allVocabs) {
    if (_selectedCategory == 'Tất cả') return allVocabs;
    return allVocabs.where((v) {
      final w = v.word.toLowerCase();
      if (_selectedCategory == 'Work & Business') {
        return w.contains('biz') || w.contains('work') || w.contains('manage') || w.contains('innovat') || w.length > 7;
      } else if (_selectedCategory == 'IELTS Academic') {
        return w.length > 8 || w.contains('tion') || w.contains('ment');
      } else if (_selectedCategory == 'Công Nghệ / Tech') {
        return w.contains('tech') || w.contains('data') || w.contains('cyber') || w.contains('code');
      } else {
        return true;
      }
    }).toList();
  }

  void _onNextCard(bool remembered, List<Vocab> list) {
    if (_cardKey.currentState != null && !_cardKey.currentState!.isFront) {
      _cardKey.currentState!.toggleCard();
    }

    setState(() {
      _isCardRevealed = false;
      _reviewCount++;
      if (remembered) _rememberedCount++;
      if (_currentIndex < list.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = list.length; // Finished state
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAutoPlay = context.watch<SettingsCubit>().state.autoPlayAudio;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber.shade600, size: 24),
            const SizedBox(width: 6),
            Text(
              'Ôn Tập Cấp Tốc',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
            ),
          ],
        ),
      ),
      body: BlocBuilder<FlashcardBloc, FlashcardState>(
        builder: (context, state) {
          if (state is FlashcardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FlashcardFailure) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }

          List<Vocab> allVocabs = [];
          if (state is FlashcardsLoadSuccess) {
            allVocabs = state.vocabs;
          }

          if (allVocabs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style_outlined, size: 64, color: context.subTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có từ vựng nào',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy tra từ hoặc import từ bộ thẻ chia sẻ để bắt đầu ôn tập cấp tốc.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: context.subTextColor),
                    ),
                  ],
                ),
              ),
            );
          }

          final vocabs = _getFilteredVocabs(allVocabs);

          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Notice - SM-2 Safety
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chế độ Ôn Cấp Tốc: Luyện tập không ghi đè / không ảnh hưởng lịch lặp lại SM-2 gốc.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Category Chips Selector
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        selected: isSelected,
                        selectedColor: context.primaryColor,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : context.textColor),
                        backgroundColor: context.cardColor,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _currentIndex = 0;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến trình cấp tốc',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.subTextColor),
                    ),
                    Text(
                      '${vocabs.isEmpty ? 0 : (_currentIndex >= vocabs.length ? vocabs.length : _currentIndex + 1)} / ${vocabs.length}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: vocabs.isEmpty ? 0 : (_currentIndex / vocabs.length).clamp(0.0, 1.0),
                    backgroundColor: context.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),

                // Main Content or Finished Summary
                Expanded(
                  child: _currentIndex >= vocabs.length || vocabs.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, size: 64, color: Colors.amber.shade500),
                                const SizedBox(height: 16),
                                Text(
                                  'Hoàn thành phiên ôn tập!',
                                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.textColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bạn đã luyện tập $_reviewCount lượt. Số câu nhớ tốt: $_rememberedCount / $_reviewCount',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 14),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.replay_rounded),
                                  label: const Text('Ôn lại lần nữa'),
                                  onPressed: () {
                                    setState(() {
                                      _currentIndex = 0;
                                      _reviewCount = 0;
                                      _rememberedCount = 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : FlipCard(
                          key: _cardKey,
                          direction: FlipDirection.HORIZONTAL,
                          onFlipDone: (isFront) {
                            setState(() {
                              _isCardRevealed = !isFront;
                            });
                            if (!isFront && isAutoPlay) {
                              _playAudio(vocabs[_currentIndex].word);
                            }
                          },
                          front: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vocabs[_currentIndex].word,
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  icon: Icon(Icons.volume_up_rounded, color: context.primaryColor, size: 28),
                                  onPressed: () => _playAudio(vocabs[_currentIndex].word),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.softBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, color: context.subTextColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Chạm để lật xem đáp án',
                                        style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          back: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.softBgColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.primaryColor.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vocabs[_currentIndex].word,
                                  style: GoogleFonts.outfit(fontSize: 20, color: context.subTextColor, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  vocabs[_currentIndex].meaning,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryColor,
                                  ),
                                ),
                                if (vocabs[_currentIndex].example.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: context.cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: context.borderColor),
                                    ),
                                    child: Text(
                                      '"${vocabs[_currentIndex].example}"',
                                      style: GoogleFonts.outfit(fontSize: 13.5, fontStyle: FontStyle.italic, color: context.textColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Practice Navigation Controls
                if (vocabs.isNotEmpty && _currentIndex < vocabs.length) ...[
                  if (!_isCardRevealed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flip_rounded),
                        label: Text('Xem Đáp Án / Lật Thẻ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _cardKey.currentState?.toggleCard(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.close_rounded, color: Colors.red.shade700),
                            label: Text('Chưa Thuộc', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            onPressed: () => _onNextCard(false, vocabs),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text('Đã Thuộc', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _onNextCard(true, vocabs),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
