import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';

import '../../data/models/vocab_model.dart';

class ForgettingCurveScreen extends StatelessWidget {
  final Vocab vocab;
  const ForgettingCurveScreen({super.key, required this.vocab});

  @override
  Widget build(BuildContext context) {
    // If interval == 0, card hasn't been reviewed yet
    final isNewCard = vocab.repetitions == 0 && vocab.interval == 0;
    final interval = math.max(1, vocab.interval).toDouble();

    // Stability S defined so that R(interval) = 90%
    // R(t) = e^(-t/S)  →  S = -interval / ln(0.9)
    final stability = -interval / math.log(0.9);

    // Approximate last review date = nextReview − interval days
    final lastReviewApprox =
        vocab.nextReview.subtract(Duration(hours: (interval * 24).round()));
    final daysSinceReview = isNewCard
        ? 0.0
        : math
            .max(0.0, DateTime.now().difference(lastReviewApprox).inMinutes / 1440.0);
    final currentRetention =
        isNewCard ? 100.0 : 100.0 * math.exp(-daysSinceReview / stability);
    final daysUntilReview =
        vocab.nextReview.difference(DateTime.now()).inMinutes / 1440.0;
    final maxDays = math.max(interval * 2.2, 21.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Đường Cong Ghi Nhớ',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Word header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.word,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vocab.meaning,
                    style: GoogleFonts.outfit(fontSize: 14, color: context.subTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (isNewCard)
              _InfoBanner(
                icon: Icons.info_outline_rounded,
                text:
                    'Từ này chưa được ôn lần nào. Hãy review lần đầu để bắt đầu theo dõi đường cong ghi nhớ.',
                color: Colors.amber.shade700,
                bgColor: Colors.amber.withValues(alpha: 0.1),
              ),

            if (!isNewCard) ...[
              // ── Stats row ─────────────────────────────────────────────
              Row(
                children: [
                  _StatTile(
                    label: 'Độ ghi nhớ hiện tại',
                    value: '${currentRetention.toStringAsFixed(1)}%',
                    color: _retentionColor(currentRetention),
                    flex: 2,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    label: 'Chu kỳ ôn',
                    value: '${interval.toInt()} ngày',
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    label: daysUntilReview >= 0 ? 'Còn lại' : 'Quá hạn',
                    value: '${daysUntilReview.abs().ceil()} ngày',
                    color: daysUntilReview >= 0 ? Colors.green.shade500 : Colors.red.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Chart ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biểu đồ Retention',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          'Tỉ lệ ghi nhớ ước tính (mô hình Ebbinghaus + SM-2)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: context.subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: CustomPaint(
                      painter: _RetentionCurvePainter(
                        stability: stability,
                        daysSinceReview: isNewCard ? -1 : daysSinceReview,
                        nextReviewDay: interval,
                        maxDays: maxDays,
                        curveColor: context.primaryColor,
                        gridColor: context.borderColor,
                        labelColor: context.subTextColor,
                        isDark: context.isDark,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Legend ────────────────────────────────────────────────────
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(color: context.primaryColor, label: 'Đường cong ghi nhớ'),
                _LegendItem(
                    color: Colors.green.shade500, label: 'Ngưỡng 90%', dashed: true),
                if (!isNewCard) ...[
                  _LegendItem(
                      color: Colors.blue.shade400, label: 'Hôm nay', dashed: true),
                  _LegendItem(
                      color: Colors.orange.shade400,
                      label: 'Lịch ôn tiếp theo',
                      dashed: true),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── SM-2 Stats detail ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.softBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông số SM-2',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số lần ôn thành công', '${vocab.repetitions} lần', context),
                  _buildDetailRow('Hệ số dễ (Ease Factor)',
                      vocab.easeFactor.toStringAsFixed(2), context),
                  _buildDetailRow('Chu kỳ hiện tại', '${vocab.interval} ngày', context),
                  _buildDetailRow(
                    'Ôn tập tiếp theo',
                    _formatDate(vocab.nextReview),
                    context,
                    highlight: daysUntilReview < 0,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Đường cong Ebbinghaus: R(t) = e^(-t/S)\n'
                      'Với S = ${stability.toStringAsFixed(1)} ngày — đảm bảo R(${interval.toInt()} ngày) ≈ 90%',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: context.subTextColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _retentionColor(double r) {
    if (r >= 90) return Colors.green.shade500;
    if (r >= 70) return Colors.orange.shade500;
    return Colors.red.shade400;
  }

  String _formatDate(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Quá hạn ${diff.inDays.abs()} ngày';
    if (diff.inDays == 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Ngày mai';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildDetailRow(String label, String value, BuildContext ctx,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(fontSize: 13, color: ctx.subTextColor)),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.red.shade400 : ctx.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _RetentionCurvePainter extends CustomPainter {
  final double stability;
  final double daysSinceReview; // -1 = new card (no marker)
  final double nextReviewDay;
  final double maxDays;
  final Color curveColor;
  final Color gridColor;
  final Color labelColor;
  final bool isDark;

  const _RetentionCurvePainter({
    required this.stability,
    required this.daysSinceReview,
    required this.nextReviewDay,
    required this.maxDays,
    required this.curveColor,
    required this.gridColor,
    required this.labelColor,
    required this.isDark,
  });

  // Chart padding
  static const _pl = 42.0;
  static const _pr = 12.0;
  static const _pt = 10.0;
  static const _pb = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width - _pl - _pr;
    final ch = size.height - _pt - _pb;

    // Coordinate transforms
    double px(double day) => _pl + (day / maxDays) * cw;
    double py(double pct) => _pt + (1.0 - pct / 100.0) * ch;

    // ── Grid + Y labels ────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.7;

    for (final pct in [0.0, 20.0, 40.0, 60.0, 80.0, 100.0]) {
      final y = py(pct);
      canvas.drawLine(Offset(_pl, y), Offset(_pl + cw, y), gridPaint);
      _drawText(canvas, '${pct.toInt()}%', Offset(0, y - 6), labelColor, 9.5,
          align: TextAlign.right, width: _pl - 4);
    }

    // ── X labels ──────────────────────────────────────────────────
    const steps = 5;
    for (var i = 0; i <= steps; i++) {
      final day = maxDays * i / steps;
      final x = px(day);
      _drawText(
        canvas,
        '${day.round()}d',
        Offset(x - 14, size.height - _pb + 6),
        labelColor,
        9.5,
        width: 28,
        align: TextAlign.center,
      );
    }

    // ── 90% threshold (green dashed) ──────────────────────────────
    _dashedH(canvas, _pl, _pl + cw, py(90), Colors.green.shade500.withValues(alpha: 0.75), 1.2);
    _drawText(canvas, '90%', Offset(_pl + 4, py(90) - 13), Colors.green.shade500, 9.5);

    // ── Gradient fill + curve ─────────────────────────────────────
    final fillPath = Path()..moveTo(px(0), py(0));
    final curvePath = Path();
    bool first = true;
    for (double t = 0; t <= maxDays; t += maxDays / 400) {
      final r = 100.0 * math.exp(-t / stability);
      final x = px(t);
      final y = py(r);
      fillPath.lineTo(x, y);
      if (first) {
        curvePath.moveTo(x, y);
        first = false;
      } else {
        curvePath.lineTo(x, y);
      }
    }
    fillPath.lineTo(px(maxDays), py(0));
    fillPath.close();

    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [curveColor.withValues(alpha: 0.22), curveColor.withValues(alpha: 0.03)],
    ).createShader(Rect.fromLTWH(_pl, _pt, cw, ch));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(_pl, _pt, cw, ch));

    canvas.drawPath(fillPath, Paint()..shader = fillShader);
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = curveColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Today vertical marker ──────────────────────────────────────
    if (daysSinceReview >= 0 && daysSinceReview <= maxDays) {
      final tx = px(daysSinceReview);
      final ty = py(100.0 * math.exp(-daysSinceReview / stability));
      _dashedV(canvas, tx, _pt, _pt + ch,
          Colors.blue.shade400.withValues(alpha: 0.8), 1.5);
      _drawDot(canvas, Offset(tx, ty), Colors.blue.shade400, isDark);
    }

    // ── Next review vertical marker ────────────────────────────────
    if (nextReviewDay > 0 && nextReviewDay <= maxDays) {
      final nx = px(nextReviewDay);
      final ny = py(100.0 * math.exp(-nextReviewDay / stability));
      _dashedV(canvas, nx, _pt, _pt + ch,
          Colors.orange.shade400.withValues(alpha: 0.8), 1.5);
      _drawDot(canvas, Offset(nx, ny), Colors.orange.shade400, isDark);
    }

    canvas.restore();
  }

  void _drawDot(Canvas canvas, Offset center, Color color, bool dark) {
    canvas.drawCircle(center, 5.5, Paint()..color = color);
    canvas.drawCircle(
        center, 3.0, Paint()..color = dark ? const Color(0xFF1E2630) : Colors.white);
  }

  void _dashedH(Canvas canvas, double x1, double x2, double y, Color c, double w) {
    final p = Paint()..color = c..strokeWidth = w;
    double x = x1;
    while (x < x2) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, x2), y), p);
      x += 10;
    }
  }

  void _dashedV(Canvas canvas, double x, double y1, double y2, Color c, double w) {
    final p = Paint()..color = c..strokeWidth = w;
    double y = y1;
    while (y < y2) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 6, y2)), p);
      y += 10;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    TextAlign align = TextAlign.left,
    double width = 60,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RetentionCurvePainter old) =>
      old.stability != stability ||
      old.daysSinceReview != daysSinceReview ||
      old.isDark != isDark;
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final int flex;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bgColor;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 13, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                width: 5,
                height: 2,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          )
        else
          Container(
            width: 20,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor),
        ),
      ],
    );
  }
}
