import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';

class StudyStatsCard extends StatelessWidget {
  final bool loadingStats;
  final int totalCards;
  final int newCards;
  final int learningCards;
  final int memorizedCards;

  const StudyStatsCard({
    super.key,
    required this.loadingStats,
    required this.totalCards,
    required this.newCards,
    required this.learningCards,
    required this.memorizedCards,
  });

  Widget _buildStatLabel(BuildContext context, String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$title: $count',
          style: GoogleFonts.outfit(fontSize: 13, color: context.textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }


    return Container(
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng: $totalCards từ vựng',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor, fontSize: 16),
              ),
              Icon(Icons.pie_chart_outline_rounded, color: context.primaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          totalCards == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Chưa có thống kê. Hãy lưu thêm từ vựng để bắt đầu ôn tập.',
                    style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                  ),
                )
              : Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 14,
                        width: double.infinity,
                        child: Row(
                          children: [
                            if (newCards > 0)
                              Expanded(
                                flex: newCards,
                                child: Container(color: context.isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              ),
                            if (learningCards > 0)
                              Expanded(
                                flex: learningCards,
                                child: Container(color: AppTheme.accentOrange),
                              ),
                            if (memorizedCards > 0)
                              Expanded(
                                flex: memorizedCards,
                                child: Container(color: context.primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatLabel(context, 'Chưa học', newCards, context.isDark ? Colors.grey.shade400 : Colors.grey.shade400),
                        _buildStatLabel(context, 'Đang học', learningCards, AppTheme.accentOrange),
                        _buildStatLabel(context, 'Đã thuộc', memorizedCards, context.primaryColor),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

