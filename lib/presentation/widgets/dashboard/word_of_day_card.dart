import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';

class WordOfDayCard extends StatefulWidget {
  final Map<String, String> wordOfTheDay;
  final ValueChanged<String> onTapWord;

  const WordOfDayCard({
    super.key,
    required this.wordOfTheDay,
    required this.onTapWord,
  });

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard> {
  late final AudioPlayer _audioPlayer;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playWord(String word) async {
    if (word.isEmpty) return;
    try {
      await _audioPlayer.play(
        UrlSource('https://dict.youdao.com/dictvoice?type=2&audio=$word'),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.wordOfTheDay['word'] ?? '';
    final meaning = widget.wordOfTheDay['meaning'] ?? '';
    final example = widget.wordOfTheDay['example'] ?? '';


    return InkWell(
      onTap: () => widget.onTapWord(word),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: context.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Từ vựng hôm nay',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _playWord(word),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _playing ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                          key: ValueKey(_playing),
                          size: 20,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.subTextColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              word,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meaning,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.softBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ví dụ: "$example"',
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
      ),
    );
  }
}

