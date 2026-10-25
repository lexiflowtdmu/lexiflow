import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../bloc/search_bloc.dart';
import '../bloc/flashcard_bloc.dart';

class VocabDetailScreen extends StatefulWidget {
  final String searchWord;
  const VocabDetailScreen({super.key, required this.searchWord});

  @override
  State<VocabDetailScreen> createState() => _VocabDetailScreenState();
}

class _VocabDetailScreenState extends State<VocabDetailScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // Dispatch query event
    context.read<SearchBloc>().add(SearchWordSubmitted(widget.searchWord));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPronunciation(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy file âm thanh cho từ này.')),
      );
      return;
    }
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể phát âm thanh: $e')),
      );
    }
  }

  void _saveToFlashcards(String word, String translation, String example) {
    context.read<FlashcardBloc>().add(
      FlashcardAdded(
        word: word,
        meaning: translation,
        example: example,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu "$word" vào bộ nhớ Flashcard!'),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.searchWord.toLowerCase(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        actions: [
          BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchSuccess) {
                final isBookmarked = state.isBookmarked;
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? context.primaryColor : context.subTextColor,
                  ),
                  onPressed: () {
                    context.read<SearchBloc>().add(
                          BookmarkToggleRequested(
                            state.word.word, 
                            !isBookmarked,
                            translation: state.word.vietnameseTranslation,
                          ),
                        );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SearchFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sentiment_dissatisfied_rounded, size: 50, color: context.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rất tiếc!',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message.contains('not found') 
                          ? 'Không tìm thấy từ vựng "${widget.searchWord}" trong từ điển. Vui lòng kiểm tra lại chính tả.' 
                          : state.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: context.subTextColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại Dashboard'),
                    )
                  ],
                ),
              ),
            );
          }

          if (state is SearchSuccess) {
            final word = state.word;
            final primaryExample = word.definitions.firstWhere((d) => d.example.isNotEmpty, orElse: () => word.definitions.first).example;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word & IPA Pronunciation Card (Theme Aware)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.borderColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                word.word,
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (word.phonetic.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  word.phonetic,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: context.subTextColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () => _playPronunciation(word.audioUrl),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: context.softBgColor,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: context.borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.volume_up_rounded, color: context.primaryColor, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Phát âm Anh/Mỹ',
                                            style: GoogleFonts.outfit(
                                              color: context.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vietnamese Translation (TFLAT Style)
                        Text(
                          'Dịch nghĩa Tiếng Việt 🇻🇳',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.softBgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            word.vietnameseTranslation.isNotEmpty
                                ? word.vietnameseTranslation
                                : 'Đang dịch nghĩa...',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Oxford Style English Definitions
                        Text(
                          'Oxford Definitions 📘',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: word.definitions.length > 5 ? 5 : word.definitions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final def = word.definitions[index];
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.borderColor, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Part of Speech Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      def.partOfSpeech.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: context.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Definition English
                                  Text(
                                    def.definition,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: context.textColor,
                                    ),
                                  ),
                                  // Definition Vietnamese
                                  if (def.vietnameseTranslation.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '👉 ${def.vietnameseTranslation}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: context.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  // Example
                                  if (def.example.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.softBgColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Ví dụ: "${def.example}"',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: context.subTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Buttons at bottom
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    border: Border(top: BorderSide(color: context.borderColor, width: 1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                            label: const Text('Thêm Vào Flashcard Ôn Tập'),
                            onPressed: () => _saveToFlashcards(
                              word.word,
                              word.vietnameseTranslation,
                              primaryExample,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          }

          return const Center(child: Text('Đang chuẩn bị từ điển...'));
        },
      ),
    );
  }
}

