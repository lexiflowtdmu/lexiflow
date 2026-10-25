import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../data/models/vocab_model.dart';
import '../../services/cloudflare_service.dart';

class QuizQuestion {
  final Vocab targetVocab;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.targetVocab,
    required this.options,
    required this.correctIndex,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = true;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  final List<QuizQuestion> _wrongAnswers = [];
  late AudioPlayer _audioPlayer;

  final List<Vocab> _fallbackVocabs = [
    Vocab(id: '1', word: 'serendipity', meaning: 'sự tình cờ may mắn', example: 'Finding this was pure serendipity.'),
    Vocab(id: '2', word: 'resilience', meaning: 'sự kiên cường, khả năng phục hồi', example: 'She showed great resilience.'),
    Vocab(id: '3', word: 'eloquent', meaning: 'hùng hồn, lưu loát', example: 'He delivered an eloquent speech.'),
    Vocab(id: '4', word: 'ephemeral', meaning: 'phù du, ngắn ngủi', example: 'Fame is ephemeral.'),
    Vocab(id: '5', word: 'meticulous', meaning: 'tỉ mỉ, cẩn thận', example: 'He is meticulous in his research.'),
    Vocab(id: '6', word: 'pragmatic', meaning: 'thực tế, thực dụng', example: 'We need a pragmatic solution.'),
    Vocab(id: '7', word: 'ubiquitous', meaning: 'có mặt ở khắp nơi', example: 'Smartphones are ubiquitous today.'),
    Vocab(id: '8', word: 'benevolent', meaning: 'nhân từ, rộng lượng', example: 'A benevolent smile.'),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _generateQuiz();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playWord(String word) async {
    try {
      await _audioPlayer.play(
        UrlSource('https://dict.youdao.com/dictvoice?type=2&audio=$word'),
      );
    } catch (_) {}
  }

  Future<void> _generateQuiz() async {
    setState(() {
      _loading = true;
      _questions = [];
      _currentIndex = 0;
      _score = 0;
      _selectedOptionIndex = null;
      _answered = false;
      _wrongAnswers.clear();
    });

    List<Vocab> vocabs = [];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final cloudflareService = context.read<CloudflareService>();
        vocabs = await cloudflareService.getSpacedRepetitionVocabs(uid);
      } catch (_) {}
    }

    if (vocabs.length < 4) {
      vocabs = List.from(_fallbackVocabs);
    } else {
      vocabs.shuffle();
    }

    final random = Random();
    final List<QuizQuestion> generatedQuestions = [];
    final int count = min(10, vocabs.length);

    for (int i = 0; i < count; i++) {
      final target = vocabs[i];
      final List<String> distractors = [];
      
      // Get random distractors from other vocabs
      final availableDistractors = vocabs.where((v) => v.meaning != target.meaning).map((v) => v.meaning).toList();
      availableDistractors.shuffle(random);

      while (distractors.length < 3 && availableDistractors.isNotEmpty) {
        distractors.add(availableDistractors.removeLast());
      }
      // If still short, pad from the built-in fallback vocab meanings
      if (distractors.length < 3) {
        final fallbackMeanings = _fallbackVocabs
            .map((v) => v.meaning)
            .where((m) => m != target.meaning && !distractors.contains(m))
            .toList()
          ..shuffle(random);
        for (final m in fallbackMeanings) {
          if (distractors.length >= 3) break;
          distractors.add(m);
        }
      }

      final List<String> options = [target.meaning, ...distractors];
      options.shuffle(random);
      final int correctIdx = options.indexOf(target.meaning);

      generatedQuestions.add(QuizQuestion(
        targetVocab: target,
        options: options,
        correctIndex: correctIdx,
      ));
    }

    if (mounted) {
      setState(() {
        _questions = generatedQuestions;
        _loading = false;
      });
    }
  }

  void _selectOption(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    final correct = index == _questions[_currentIndex].correctIndex;
    if (!correct) _wrongAnswers.add(_questions[_currentIndex]);
    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
      if (correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _answered = false;
      });
    } else {
      setState(() {
        _currentIndex++; // Triggers finished state
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Trắc Nghiệm Từ Vựng',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(child: Text('Không đủ từ vựng để tạo bài thi.', style: GoogleFonts.outfit(color: context.textColor)))
              : _currentIndex >= _questions.length
                  ? _buildResultScreen()
                  : _buildQuizContent(),
    );
  }

  Widget _buildQuizContent() {
    final currentQ = _questions[_currentIndex];


    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${_currentIndex + 1} / ${_questions.length}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.subTextColor),
              ),
              Text(
                'Điểm: $_score',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.primaryColor, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 28),

          // Question Card (Theme Aware)
          Container(
            padding: const EdgeInsets.all(28),
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
              children: [
                Text(
                  'Từ này có nghĩa là gì?',
                  style: GoogleFonts.outfit(fontSize: 14, color: context.subTextColor),
                ),
                const SizedBox(height: 12),
                Text(
                  currentQ.targetVocab.word,
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _playWord(currentQ.targetVocab.word),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.softBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 16, color: context.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Nghe phát âm',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: context.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Options List
          Expanded(
            child: ListView.separated(
              itemCount: currentQ.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final optionText = currentQ.options[index];
                Color optionBg = context.cardColor;
                Color optionTextColor = context.textColor;
                Color optionBorder = context.borderColor;
                IconData? icon;

                if (_answered) {
                  if (index == currentQ.correctIndex) {
                    optionBg = context.successGreen.withValues(alpha: context.isDark ? 0.25 : 0.12);
                    optionTextColor = context.successGreen;
                    optionBorder = context.successGreen;
                    icon = Icons.check_circle_rounded;
                  } else if (index == _selectedOptionIndex) {
                    optionBg = context.errorRed.withValues(alpha: context.isDark ? 0.25 : 0.12);
                    optionTextColor = context.errorRed;
                    optionBorder = context.errorRed;
                    icon = Icons.cancel_rounded;
                  }
                }

                return InkWell(
                  onTap: () => _selectOption(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: optionBorder,
                        width: _answered && (index == currentQ.correctIndex || index == _selectedOptionIndex) ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            optionText,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: optionTextColor,
                            ),
                          ),
                        ),
                        if (icon != null) Icon(icon, color: optionTextColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_answered)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1 ? 'Câu tiếp theo' : 'Xem kết quả',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final double percentage = (_score / _questions.length) * 100;
    String feedback = 'Cố gắng hơn nữa nhé!';
    if (percentage >= 80) {
      feedback = 'Xuất sắc! Bạn đã nhớ rất tốt.';
    } else if (percentage >= 50) {
      feedback = 'Khá tốt! Hãy ôn lại các từ chưa thuộc.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.primaryColor.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Icon(
              percentage >= 80 ? Icons.emoji_events_rounded : Icons.stars_rounded,
              size: 72,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hoàn Thành Bài Kiểm Tra!',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: GoogleFonts.outfit(fontSize: 14, color: context.subTextColor),
          ),
          const SizedBox(height: 24),
          Text(
            '$_score / ${_questions.length}',
            style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: context.primaryColor),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percentage.round()}% Chính xác',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: context.primaryColor),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _generateQuiz,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Thi lại'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Về Trang Chủ'),
                ),
              ),
            ],
          ),
          if (_wrongAnswers.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  width: 3, height: 18,
                  decoration: BoxDecoration(
                    color: context.errorRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ôn lại ${_wrongAnswers.length} từ chưa thuộc',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_wrongAnswers.map((q) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded, color: context.errorRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.targetVocab.word,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          q.options[q.correctIndex],
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: context.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

