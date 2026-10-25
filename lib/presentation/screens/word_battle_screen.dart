import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../data/models/vocab_model.dart';
import '../../services/cloudflare_service.dart';

class BattleQuestion {
  final int index;
  final String word;
  final String phonetic;
  final String correctAnswer;
  final List<String> options;

  BattleQuestion({
    required this.index,
    required this.word,
    required this.phonetic,
    required this.correctAnswer,
    required this.options,
  });
}

class BattlePlayer {
  final String uid;
  final String name;
  final String avatarUrl;
  int score;
  bool isReady;

  BattlePlayer({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    this.score = 0,
    this.isReady = true,
  });
}

class WordBattleScreen extends StatefulWidget {
  final String mode; // '1v1' | 'kahoot'
  final String? roomCode;

  const WordBattleScreen({
    super.key,
    this.mode = '1v1',
    this.roomCode,
  });

  @override
  State<WordBattleScreen> createState() => _WordBattleScreenState();
}

class _WordBattleScreenState extends State<WordBattleScreen> {
  late String _mode;
  late String _roomCode;
  String _gameState = 'lobby'; // 'lobby' | 'playing' | 'ended'

  int _currentQuestionIndex = 0;
  int _secondsRemaining = 15;
  Timer? _timer;

  String? _selectedOption;
  bool _answered = false;
  int _myScore = 0;
  int _opponentScore = 0;

  final List<BattlePlayer> _players = [
    BattlePlayer(
      uid: 'self-1',
      name: 'Bạn (LexiPro)',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
      score: 0,
    ),
    BattlePlayer(
      uid: 'opp-1',
      name: 'Trần Trung Đức',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=250',
      score: 0,
    ),
  ];

  bool _isLoading = true;
  final List<BattleQuestion> _questions = [];

  static final List<BattleQuestion> _fallbackQuestions = [
    BattleQuestion(
      index: 0,
      word: 'meticulous',
      phonetic: '/məˈtɪkjələs/',
      correctAnswer: 'Tỉ mỉ, cẩn thận',
      options: ['Tỉ mỉ, cẩn thận', 'Hào hứng', 'Do dự, ngập ngừng', 'Dễ vỡ'],
    ),
    BattleQuestion(
      index: 1,
      word: 'serendipity',
      phonetic: '/ˌ serənˈdɪpəti/',
      correctAnswer: 'Sự tình cờ may mắn',
      options: ['Rủi ro đột ngột', 'Sự tình cờ may mắn', 'Kế hoạch chi tiết', 'Nỗi buồn thầm lặng'],
    ),
    BattleQuestion(
      index: 2,
      word: 'resilient',
      phonetic: '/rɪˈzɪliənt/',
      correctAnswer: 'Kiên cường, phục hồi nhanh',
      options: ['Cứng nhắc', 'Kiên cường, phục hồi nhanh', 'Yếu đuối', 'Chậm chạp'],
    ),
    BattleQuestion(
      index: 3,
      word: 'ephemeral',
      phonetic: '/ɪˈfemərəl/',
      correctAnswer: 'Phù du, ngắn ngủi',
      options: ['Vĩnh cửu', 'Phù du, ngắn ngủi', 'Rõ ràng', 'Bí ẩn'],
    ),
    BattleQuestion(
      index: 4,
      word: 'eloquent',
      phonetic: '/ˈeləkwənt/',
      correctAnswer: 'Hùng hồn, lưu loát',
      options: ['Hùng hồn, lưu loát', 'Im lặng', 'Do dự', 'Khó hiểu'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _roomCode = widget.roomCode ?? (_mode == '1v1' ? 'BTL-8492' : 'ROOM-9102');
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    List<Vocab> vocabs = [];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final service = context.read<CloudflareService>();
        vocabs = await service.getSpacedRepetitionVocabs(uid);
      } catch (_) {}
    }

    if (vocabs.length >= 4) {
      vocabs.shuffle();
      final pool = vocabs.take(10).toList();
      final random = Random();
      _questions.clear();
      for (int i = 0; i < pool.length; i++) {
        final target = pool[i];
        final distractors = pool
            .where((v) => v.meaning != target.meaning)
            .map((v) => v.meaning)
            .toList()
          ..shuffle(random);
        final opts = [target.meaning, ...distractors.take(3)];
        opts.shuffle(random);
        _questions.add(BattleQuestion(
          index: i,
          word: target.word,
          phonetic: '',
          correctAnswer: target.meaning,
          options: opts,
        ));
      }
    } else {
      _questions.addAll(_fallbackQuestions);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = 'playing';
      _currentQuestionIndex = 0;
      _myScore = 0;
      _opponentScore = 0;
    });
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 15;
      _selectedOption = null;
      _answered = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    if (!_answered) {
      _handleSelectOption('');
    }
  }

  void _handleSelectOption(String option) {
    if (_answered) return;
    _timer?.cancel();
    HapticFeedback.lightImpact();

    final currentQ = _questions[_currentQuestionIndex];
    final isCorrect = option == currentQ.correctAnswer;

    int points = 0;
    if (isCorrect) {
      final speedBonus = (_secondsRemaining * 3);
      points = 100 + speedBonus;
    }

    // Simulate opponent response (70% accuracy)
    final oppCorrect = _currentQuestionIndex % 2 == 0;
    final oppPoints = oppCorrect ? (100 + ((_secondsRemaining - 1).clamp(1, 15) * 2)) : 0;

    setState(() {
      _selectedOption = option;
      _answered = true;
      _myScore += points;
      _opponentScore += oppPoints;
      _players[0].score = _myScore;
      _players[1].score = _opponentScore;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startQuestionTimer();
      } else {
        setState(() {
          _gameState = 'ended';
        });
      }
    });
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã phòng: $_roomCode'),
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
          _mode == '1v1' ? '⚔️ Thách Đấu 1v1' : '🎉 Phòng Đấu Nhóm Kahoot',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Sao chép mã phòng',
            onPressed: _copyRoomCode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_gameState),
                  child: _gameState == 'lobby'
                      ? _buildLobbyView()
                      : _gameState == 'playing'
                          ? _buildPlayingView()
                          : _buildEndedView(),
                ),
              ),
            ),
    );
  }

  Widget _buildLobbyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.primaryColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _mode == '1v1' ? 'PHÒNG THÁCH ĐẤU 1v1' : 'PHÒNG ĐẤU NHÓM KAHOOT',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: context.primaryColor, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _copyRoomCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.softBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roomCode,
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: context.primaryColor, letterSpacing: 2.0),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.copy_rounded, color: context.primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mời đối thủ hoặc chia sẻ mã này để tham gia trận đấu',
                style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Joined Players List
        Text(
          'Danh Sách Người Chơi (${_players.length})',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final p = _players[index];
            return Card(
              color: context.cardColor,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(p.avatarUrl)),
                title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
                subtitle: Text(p.isReady ? 'Sẵn sàng 🟢' : 'Đang đợi...', style: GoogleFonts.outfit(color: context.successGreen, fontSize: 12)),
                trailing: Icon(Icons.check_circle_rounded, color: context.primaryColor),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Start Game Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text('Bắt Đầu Trận Đấu!', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _startGame,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayingView() {
    final q = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Live Battle Score Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Player 1 (Self)
              Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(_players[0].avatarUrl)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bạn', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.textColor)),
                      Text('+$_myScore điểm', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor)),
                    ],
                  ),
                ],
              ),

              // Realtime Timer Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondsRemaining <= 5 ? Colors.red.shade50 : AppTheme.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _secondsRemaining <= 5 ? Colors.red : AppTheme.accentOrange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: _secondsRemaining <= 5 ? Colors.red : AppTheme.accentOrange),
                    const SizedBox(width: 4),
                    Text(
                      '${_secondsRemaining}s',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _secondsRemaining <= 5 ? Colors.red : AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),

              // Player 2 (Opponent)
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Đối thủ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.textColor)),
                      Text('+$_opponentScore điểm', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade600)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(_players[1].avatarUrl)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Question Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Câu hỏi ${_currentQuestionIndex + 1} / ${_questions.length}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.primaryColor)),
            Text('Tốc độ + Độ chính xác', style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: context.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 20),

        // Question Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              Text(
                q.word,
                style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: context.primaryColor),
              ),
              const SizedBox(height: 4),
              if (q.phonetic.isNotEmpty)
                Text(
                  q.phonetic,
                  style: GoogleFonts.outfit(fontSize: 16, color: context.subTextColor, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4 Options Grid
        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = q.options[index];
              final isSelected = _selectedOption == option;
              final isCorrect = option == q.correctAnswer;

              Color bg = context.cardColor;
              Color borderC = context.borderColor;
              Color textC = context.textColor;

              if (_answered) {
                if (isCorrect) {
                  bg = Colors.green.shade50;
                  borderC = Colors.green;
                  textC = Colors.green.shade900;
                } else if (isSelected && !isCorrect) {
                  bg = Colors.red.shade50;
                  borderC = Colors.red;
                  textC = Colors.red.shade900;
                }
              }

              return InkWell(
                onTap: _answered ? null : () => _handleSelectOption(option),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderC, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textC),
                      ),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                      if (_answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEndedView() {
    final won = _myScore >= _opponentScore;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: context.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🏆 CHIẾN THẮNG RỰC RỠ!' : '🤝 TRẬN ĐẤU KẾT THÚC',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: won ? Colors.amber.shade600 : context.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Score Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.softBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: NetworkImage(_players[0].avatarUrl)),
                      const SizedBox(height: 6),
                      Text('Bạn', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.textColor)),
                      Text('$_myScore điểm', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: context.primaryColor)),
                    ],
                  ),
                  Text('VS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: context.subTextColor)),
                  Column(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: NetworkImage(_players[1].avatarUrl)),
                      const SizedBox(height: 6),
                      Text('Đối thủ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.textColor)),
                      Text('$_opponentScore điểm', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.purple.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Đấu Trận Khác'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () {
                setState(() {
                  _gameState = 'lobby';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
