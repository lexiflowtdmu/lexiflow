import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../bloc/farm_bloc.dart';
import '../../services/cloudflare_service.dart';

// Crop display data — mirrors backend CROP_CATALOG emojis
const Map<String, String> _cropEmoji = {
  'corn': '\u{1F33D}',
  'tomato': '\u{1F345}',
  'flower': '\u{1F338}',
  'apple': '\u{1F34E}',
  'herbs': '\u{1F33F}',
  'blueberry': '\u{1FAD0}',
};

const Map<String, String> _cropNameVi = {
  'corn': 'Ngô',
  'tomato': 'Cà Chua',
  'flower': 'Hoa',
  'apple': 'Táo',
  'herbs': 'Thảo Mộc',
  'blueberry': 'Việt Quất',
};

// Returns a growth-stage emoji for stage 1, or the crop emoji for stage 2
String _growEmoji(FarmPlot plot) {
  if (plot.stage != 1) return _cropEmoji[plot.cropType] ?? '\u{1F33F}';
  final pct = plot.wordsNeeded > 0 ? plot.wordsProgress / plot.wordsNeeded : 0.0;
  if (pct < 0.34) return '\u{1F331}'; // seedling
  if (pct < 0.67) return '\u{1F33F}'; // sprout
  return _cropEmoji[plot.cropType] ?? '\u{1F33F}'; // crop at 67%+
}

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmBloc(service: context.read<CloudflareService>())
        ..add(FarmLoadRequested()),
      child: const _FarmView(),
    );
  }
}

class _FarmView extends StatelessWidget {
  const _FarmView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const Text('\u{1F33E}', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Nông Trại',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.textColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<FarmBloc, FarmState>(
            builder: (ctx, state) {
              final coins = state is FarmLoaded
                  ? state.coins
                  : state is FarmActionSuccess
                      ? state.refreshed.coins
                      : 0;
              return _CoinChip(coins: coins);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (ctx, state) {
          if (state is FarmActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state is FarmError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is FarmLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          FarmLoaded? loaded;
          if (state is FarmLoaded) loaded = state;
          if (state is FarmActionSuccess) loaded = state.refreshed;

          if (loaded == null) {
            return _ErrorWidget(
              onRetry: () => ctx.read<FarmBloc>().add(FarmLoadRequested()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ctx.read<FarmBloc>().add(FarmLoadRequested()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    label: 'Mảnh đất',
                    hint: '${loaded.plots.where((p) => p.stage == 2).length} sẵn thu hoạch',
                  ),
                  const SizedBox(height: 12),
                  _PlotsGrid(plots: loaded.plots, catalog: loaded.cropCatalog),
                  const SizedBox(height: 8),
                  _WaterHint(plots: loaded.plots),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    label: 'Đơn hàng',
                    hint: 'Hoàn thành để nhận xu',
                  ),
                  const SizedBox(height: 12),
                  ...loaded.orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(
                          order: order,
                          inventory: loaded!.inventory,
                          catalog: loaded.cropCatalog,
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Plot Grid ─────────────────────────────────────────────────

class _PlotsGrid extends StatelessWidget {
  final List<FarmPlot> plots;
  final Map<String, dynamic> catalog;
  const _PlotsGrid({required this.plots, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final sorted = List<FarmPlot?>.filled(8, null);
    for (final p in plots) {
      if (p.slotIndex < 8) sorted[p.slotIndex] = p;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemCount: 8,
      itemBuilder: (ctx, i) {
        final plot = sorted[i];
        if (plot == null) return const SizedBox.shrink();
        return _PlotTile(plot: plot, catalog: catalog);
      },
    );
  }
}

class _PlotTile extends StatelessWidget {
  final FarmPlot plot;
  final Map<String, dynamic> catalog;
  const _PlotTile({required this.plot, required this.catalog});

  void _handleTap(BuildContext context) {
    if (plot.stage == 0) {
      HapticFeedback.selectionClick();
      _showPlantSheet(context);
    } else if (plot.stage == 2) {
      HapticFeedback.mediumImpact();
      context.read<FarmBloc>().add(FarmHarvestPlot(plot.id));
    }
  }

  void _showPlantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<FarmBloc>(),
        child: _PlantSheet(slotIndex: plot.slotIndex, catalog: catalog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    List<BoxShadow> shadows = [];

    if (plot.stage == 0) {
      bgColor = context.isDark
          ? const Color(0xFF2A1F10)
          : const Color(0xFFF5ECD7);
      borderColor = context.isDark
          ? const Color(0xFF4A3520)
          : const Color(0xFFD4B896);
    } else if (plot.stage == 1) {
      bgColor = AppTheme.successGreen.withValues(alpha: 0.08);
      borderColor = AppTheme.successGreen.withValues(alpha: 0.4);
    } else {
      bgColor = AppTheme.accentOrange.withValues(alpha: 0.12);
      borderColor = AppTheme.accentOrange;
      shadows = [
        BoxShadow(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        )
      ];
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: shadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (plot.stage == 0) ...[
                Icon(Icons.add_rounded,
                    color: context.subTextColor, size: 22),
                const SizedBox(height: 2),
                Text(
                  'Trồng',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: context.subTextColor,
                  ),
                ),
              ] else ...[
                Text(
                  _growEmoji(plot),
                  style: TextStyle(fontSize: plot.stage == 2 ? 28 : 22),
                ),
                const SizedBox(height: 4),
                if (plot.stage == 1) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: plot.wordsNeeded > 0
                          ? plot.wordsProgress / plot.wordsNeeded
                          : 0,
                      minHeight: 4,
                      backgroundColor:
                          AppTheme.successGreen.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.successGreen),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plot.wordsProgress}/${plot.wordsNeeded}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Thu hoạch!',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plant Bottom Sheet ────────────────────────────────────────

class _PlantSheet extends StatelessWidget {
  final int slotIndex;
  final Map<String, dynamic> catalog;
  const _PlantSheet({required this.slotIndex, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final crops = catalog.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn cây trồng',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Học từ vựng để tưới nước cho cây',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: context.subTextColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: crops.length,
            itemBuilder: (ctx, i) {
              final key = crops[i].key;
              final def = crops[i].value as Map<String, dynamic>;
              final wordsNeeded = (def['words_needed'] as num).toInt();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  ctx.read<FarmBloc>().add(FarmPlantCrop(slotIndex, key));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.softBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _cropEmoji[key] ?? '\u{1F33F}',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cropNameVi[key] ?? key,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      Text(
                        '$wordsNeeded từ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: context.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Water hint ────────────────────────────────────────────────

class _WaterHint extends StatelessWidget {
  final List<FarmPlot> plots;
  const _WaterHint({required this.plots});

  @override
  Widget build(BuildContext context) {
    final growingCount = plots.where((p) => p.stage == 1).length;
    if (growingCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('\u{1F4A7}', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ôn tập từ vựng để tưới $growingCount cây đang lớn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final FarmOrder order;
  final Map<String, int> inventory;
  final Map<String, dynamic> catalog;
  const _OrderCard({
    required this.order,
    required this.inventory,
    required this.catalog,
  });

  bool _canFulfill() {
    for (final item in order.items) {
      if ((inventory[item.type] ?? 0) < item.qty) return false;
    }
    return true;
  }

  String _timeLeft() {
    final expires = DateTime.tryParse(order.expiresAt);
    if (expires == null) return '';
    final diff = expires.difference(DateTime.now());
    if (diff.isNegative) return 'Hết hạn';
    if (diff.inHours > 0) return '${diff.inHours}g ${diff.inMinutes % 60}p';
    return '${diff.inMinutes}p';
  }

  @override
  Widget build(BuildContext context) {
    final canFulfill = _canFulfill();
    final timeLeft = _timeLeft();
    final isUrgent = () {
      final expires = DateTime.tryParse(order.expiresAt);
      if (expires == null) return false;
      return expires.difference(DateTime.now()).inMinutes < 30 &&
          !expires.difference(DateTime.now()).isNegative;
    }();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canFulfill
              ? AppTheme.successGreen.withValues(alpha: 0.5)
              : context.borderColor,
          width: canFulfill ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: order.items.map((item) {
                    final have = inventory[item.type] ?? 0;
                    final enough = have >= item.qty;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: enough
                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                            : context.softBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: enough
                              ? AppTheme.successGreen.withValues(alpha: 0.4)
                              : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_cropEmoji[item.type] ?? '\u{1F33F}',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '×${item.qty}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: enough
                                  ? AppTheme.successGreen
                                  : context.textColor,
                            ),
                          ),
                          if (!enough) ...[
                            const SizedBox(width: 3),
                            Text(
                              '($have)',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: context.subTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('\u{1FA99}', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 3),
                      Text(
                        '${order.rewardCoins}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '+${order.rewardXp} XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '⏰ $timeLeft',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isUrgent ? AppTheme.errorRed : context.subTextColor,
                  fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<FarmBloc>().add(FarmSkipOrder(order.id)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Bỏ qua',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: context.subTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: canFulfill
                    ? () {
                        HapticFeedback.lightImpact();
                        context
                            .read<FarmBloc>()
                            .add(FarmFulfillOrder(order.id));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  disabledBackgroundColor: context.borderColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  canFulfill ? 'Giao hàng' : 'Thiếu hàng',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: canFulfill ? Colors.white : context.subTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────

class _CoinChip extends StatelessWidget {
  final int coins;
  const _CoinChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.accentOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1FA99}', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String hint;
  const _SectionHeader({required this.label, required this.hint});

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
        const Spacer(),
        Text(
          hint,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: context.subTextColor,
          ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F62D}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Không thể tải nông trại',
            style: GoogleFonts.outfit(
                color: context.textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Thử lại', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }
}
