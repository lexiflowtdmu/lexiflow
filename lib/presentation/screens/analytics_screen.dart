import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';

import '../../data/models/vocab_model.dart';
import '../../services/cloudflare_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;
  String? _error;

  // Deck summary
  int _totalCards = 0;
  int _newCards = 0;
  int _learningCards = 0;
  int _memorizedCards = 0;
  int _dueToday = 0;
  int _dueThisWeek = 0;

  // SM-2 computed
  double _avgEaseFactor = 2.5;
  double _avgInterval = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = context.read<CloudflareService>();
      final results = await Future.wait([
        service.getDeckSummary(),
        service.getSpacedRepetitionVocabs(''),
        service.getStreakData(),
      ]);

      final summary = results[0] as Map<String, int>;
      final vocabs = results[1] as List<Vocab>;
      final streakData = results[2] as Map<String, int>;

      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      double easeFacSum = 0;
      double intervalSum = 0;
      int dueToday = 0;
      int dueWeek = 0;
      int reviewedCount = 0;

      for (final v in vocabs) {
        if (v.repetitions > 0) {
          easeFacSum += v.easeFactor;
          intervalSum += v.interval;
          reviewedCount++;
        }
        if (v.nextReview.isBefore(now) || _sameDay(v.nextReview, now)) dueToday++;
        if (v.nextReview.isBefore(weekEnd)) dueWeek++;
      }

      final total = summary['totalCards'] ?? 0;
      final newC = summary['newCards'] ?? 0;
      final learningC = summary['learningCards'] ?? 0;
      final memorized = (total - newC - learningC).clamp(0, total);

      if (mounted) {
        setState(() {
          _totalCards = total;
          _newCards = newC;
          _learningCards = learningC;
          _memorizedCards = memorized;
          _dueToday = dueToday;
          _dueThisWeek = dueWeek;
          _avgEaseFactor = reviewedCount > 0 ? easeFacSum / reviewedCount : 2.5;
          _avgInterval = reviewedCount > 0 ? intervalSum / reviewedCount : 0;
          _currentStreak = streakData['current'] ?? 0;
          _longestStreak = streakData['longest'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Thống kê học tập',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.primaryColor),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: context.errorRed, size: 48),
                      const SizedBox(height: 12),
                      Text('Không thể tải dự liệu',
                          style: GoogleFonts.outfit(color: context.textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroRow(context),
                        const SizedBox(height: 24),
                        _buildDonutSection(context),
                        const SizedBox(height: 24),
                        _buildSM2Section(context),
                        const SizedBox(height: 24),
                        _buildDueSection(context),
                        const SizedBox(height: 24),
                        _buildInsightCard(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Hero stats row ────────────────────────────────────────────

  Widget _buildHeroRow(BuildContext context) {
    return Row(
      children: [
        _heroTile(context,
            label: 'Tổng từ',
            value: '$_totalCards',
            icon: Icons.library_books_rounded,
            color: context.primaryColor),
        const SizedBox(width: 12),
        _heroTile(context,
            label: 'Streak',
            value: '$_currentStreak ngày',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.accentOrange),
        const SizedBox(width: 12),
        _heroTile(context,
            label: 'Đã thuộc',
            value: '$_memorizedCards',
            icon: Icons.check_circle_rounded,
            color: context.successGreen),
      ],
    );
  }

  Widget _heroTile(BuildContext context,
      {required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
            Text(label,
                style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor)),
          ],
        ),
      ),
    );
  }

  // ── Donut chart section ────────────────────────────────────────

  Widget _buildDonutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân bố ghi nhớ',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _DonutPainter(
                    newCards: _newCards,
                    learningCards: _learningCards,
                    masterCards: _memorizedCards,
                    newColor: context.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    learningColor: AppTheme.accentOrange,
                    masterColor: context.primaryColor,
                    bgColor: context.borderColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_totalCards',
                            style: GoogleFonts.outfit(
                                fontSize: 26, fontWeight: FontWeight.bold, color: context.textColor)),
                        Text('từ',
                            style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(context, 'Đã thuộc', _memorizedCards, context.primaryColor),
                    const SizedBox(height: 10),
                    _legendItem(context, 'Đang học', _learningCards, AppTheme.accentOrange),
                    const SizedBox(height: 10),
                    _legendItem(context, 'Chưa học', _newCards,
                        context.isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                    if (_totalCards > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        color: context.borderColor,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.trending_up_rounded, size: 14, color: context.successGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Tỷ lệ thuộc: ${(_memorizedCards / _totalCards * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.successGreen),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: GoogleFonts.outfit(fontSize: 13, color: context.subTextColor)),
        ),
        Text('$count',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
      ],
    );
  }

  // ── SM-2 metrics ──────────────────────────────────────────────

  Widget _buildSM2Section(BuildContext context) {
    // Ease factor: 1.3 (min) → 3.5 (max), default 2.5
    // Map to 0-1: (val - 1.3) / (3.5 - 1.3)
    final efNorm = ((_avgEaseFactor - 1.3) / (3.5 - 1.3)).clamp(0.0, 1.0);
    final efPct = (efNorm * 100).round();

    // Interval: show as-is, cap visual at 30 days for bar
    final intNorm = (_avgInterval / 30).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chỉ số SM-2',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
        const SizedBox(height: 4),
        Text('Thuật toán lặp lại có khoảng cách',
            style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                title: 'Hệ số dễ (EF)',
                value: _avgEaseFactor.toStringAsFixed(2),
                subtitle: '$efPct% khả năng ghi nhớ',
                progress: efNorm,
                color: efNorm >= 0.5 ? context.successGreen : AppTheme.accentOrange,
                icon: Icons.psychology_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                context,
                title: 'Khoảng cách ôn',
                value: '${_avgInterval.toStringAsFixed(0)} ngày',
                subtitle: 'Trung bình giữa các lần ôn',
                progress: intNorm,
                color: context.primaryColor,
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Longest streak card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppTheme.accentOrange, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kỷ lục streak',
                      style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor)),
                  Text('$_longestStreak ngày liên tiếp',
                      style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                ],
              ),
              const Spacer(),
              if (_currentStreak >= _longestStreak && _longestStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\u{1F3C6} Kỷ lục mới!',
                    style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.outfit(fontSize: 10, color: context.subTextColor)),
        ],
      ),
    );
  }

  // ── Due cards section ──────────────────────────────────────────

  Widget _buildDueSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lịch ôn tập',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.bold, color: context.textColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dueItem(
                  context,
                  label: 'Cần ôn hôm nay',
                  count: _dueToday,
                  icon: Icons.today_rounded,
                  urgent: _dueToday > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dueItem(
                  context,
                  label: 'Đến hạn tuần này',
                  count: _dueThisWeek,
                  icon: Icons.date_range_rounded,
                  urgent: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dueItem(BuildContext context,
      {required String label, required int count, required IconData icon, required bool urgent}) {
    final color = urgent && count > 0 ? context.errorRed : context.primaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count từ',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style: GoogleFonts.outfit(fontSize: 10, color: context.subTextColor),
                    maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight card ───────────────────────────────────────────────

  Widget _buildInsightCard(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (_totalCards == 0) {
      message = 'Bắt đầu bằng cách lưu từ vựng đầu tiên của bạn!';
      icon = Icons.lightbulb_outline_rounded;
      color = context.primaryColor;
    } else if (_dueToday > 20) {
      message = 'Bạn có $_dueToday từ cần ôn hôm nay. Hãy bắt đầu ngay để giữ streak!';
      icon = Icons.warning_rounded;
      color = context.errorRed;
    } else if (_memorizedCards > 0 && _memorizedCards == _totalCards) {
      message = 'Xuất sắc! Bạn đã thuộc tất cả từ vựng. Hãy thêm từ mới!';
      icon = Icons.celebration_rounded;
      color = context.successGreen;
    } else if (_avgEaseFactor < 2.0) {
      message = 'Hệ số EF thấp — một số từ vựng khá khó. Hãy kiên trì ôn tập!';
      icon = Icons.fitness_center_rounded;
      color = AppTheme.accentOrange;
    } else {
      message = 'Tiếp tục phát huy! SM-2 đang tối ưu hóa lịch ôn tập cho bạn.';
      icon = Icons.auto_awesome_rounded;
      color = context.primaryColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: context.textColor, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Donut chart painter ────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final int newCards;
  final int learningCards;
  final int masterCards;
  final Color newColor;
  final Color learningColor;
  final Color masterColor;
  final Color bgColor;

  _DonutPainter({
    required this.newCards,
    required this.learningCards,
    required this.masterCards,
    required this.newColor,
    required this.learningColor,
    required this.masterColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final strokeWidth = outerRadius * 0.3;
    final arcRadius = outerRadius - strokeWidth / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final total = newCards + learningCards + masterCards;

    if (total == 0) {
      paint.color = bgColor;
      canvas.drawCircle(center, arcRadius, paint);
      return;
    }

    const gap = 0.02; // gap between segments in radians
    double startAngle = -math.pi / 2;

    final segments = [
      (masterCards / total, masterColor),
      (learningCards / total, learningColor),
      (newCards / total, newColor),
    ];

    for (final (fraction, color) in segments) {
      if (fraction <= 0) continue;
      paint.color = color;
      final sweepAngle = fraction * 2 * math.pi - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle + gap / 2,
        sweepAngle.clamp(0.0, 2 * math.pi),
        false,
        paint,
      );
      startAngle += fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.masterCards != masterCards ||
      old.learningCards != learningCards ||
      old.newCards != newCards;
}
