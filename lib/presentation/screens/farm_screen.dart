import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import '../bloc/farm_bloc.dart';
import '../../services/cloudflare_service.dart';
import '../widgets/sky_garden_art.dart';

// ── Crop Display Catalog ──────────────────────────────────────
const Map<String, String> _cropNameVi = {
  'corn': 'Ngô Vàng',
  'tomato': 'Cà Chua',
  'flower': 'Hoa Bách Hợp',
  'apple': 'Táo Thần',
  'herbs': 'Thảo Mộc',
  'blueberry': 'Việt Quất',
};

const _wood = Color(0xFFA85C1C);
const _woodDark = Color(0xFF7C3F12);
const _parchment = Color(0xFFFFF4D9);
const _ink = Color(0xFF3B2410);

const _sheetDecoration = BoxDecoration(
  color: _parchment,
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  border: Border(
    top: BorderSide(color: _wood, width: 4),
    left: BorderSide(color: _wood, width: 4),
    right: BorderSide(color: _wood, width: 4),
  ),
);

// ── FarmScreen Entry Point ────────────────────────────────────
class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmBloc(service: context.read<CloudflareService>())
        ..add(FarmLoadRequested()),
      child: const _SkyFarmView(),
    );
  }
}

// ── Main Sky Farm View ────────────────────────────────────────
class _SkyFarmView extends StatefulWidget {
  const _SkyFarmView();

  @override
  State<_SkyFarmView> createState() => _SkyFarmViewState();
}

class _SkyFarmViewState extends State<_SkyFarmView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  FarmLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _animCtrl.stop();
    } else if (!_animCtrl.isAnimating) {
      _animCtrl.repeat();
    }
  }

  /// Next-action hint, in the priority order of design/ux/sky-garden.md.
  (String, VoidCallback?) _nextHint(BuildContext context, FarmLoaded farm) {
    final ready = farm.plots.where((p) => p.stage == 2).length;
    final growing = farm.plots.where((p) => p.stage == 1).toList();
    final hasEmpty = farm.plots.length < 8 || farm.plots.any((p) => p.stage == 0);
    final fulfillable = farm.orders
        .where((o) => o.items.every((it) => (farm.inventory[it.type] ?? 0) >= it.qty))
        .length;

    if (ready > 0) return ('$ready cây đã chín, chạm để thu hoạch', null);
    if (fulfillable > 0) {
      return (
        'Có $fulfillable đơn giao được',
        () => _showOrdersModal(context, farm.orders, farm.inventory, farm.cropCatalog),
      );
    }
    if (hasEmpty && growing.isEmpty) return ('Chạm một chậu để gieo hạt', null);
    if (growing.isNotEmpty) {
      final nearest = growing
          .map((p) => math.max(p.wordsNeeded - p.wordsProgress, 0))
          .reduce(math.min);
      return ('Học thêm $nearest từ để cây chín', () => Navigator.pop(context));
    }
    return ('Gieo thêm cây để nhận đơn mới', null);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showOrdersModal(
    BuildContext context,
    List<FarmOrder> orders,
    Map<String, int> inventory,
    Map<String, dynamic> catalog,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FarmBloc>(),
        child: _OrdersSheet(orders: orders, inventory: inventory, catalog: catalog),
      ),
    );
  }

  void _showInventoryModal(
    BuildContext context,
    Map<String, int> inventory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventorySheet(inventory: inventory),
    );
  }

  void _showVocabQuizDialog(BuildContext context, FarmPlot plot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const FarmImage('drop', width: 26, height: 26),
            const SizedBox(width: 8),
            Text(
              'Tưới Nước Từ Vựng',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ lớn: ${plot.wordsProgress}/${plot.wordsNeeded} từ vựng',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: plot.wordsNeeded > 0 ? (plot.wordsProgress / plot.wordsNeeded) : 0,
                minHeight: 8,
                backgroundColor: Colors.blue.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B0FF)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mẹo nhà nông LexiFlow:',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hãy học Flashcards hoặc giải Quiz ở trang chủ. Mỗi từ vựng ôn tập đúng sẽ tự động tạo 1 giọt nước tưới cho chậu cây này!',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF166534), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng', style: GoogleFonts.outfit(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Trở về dashboard để học bài
            },
            child: Text('Đến phần Ôn Tập', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlantSheet(BuildContext context, int slotIndex, Map<String, dynamic> catalog) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<FarmBloc>(),
        child: _PlantSheet(slotIndex: slotIndex, catalog: catalog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (ctx, state) {
          if (state is FarmActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                                        Text(state.message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ],
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state is FarmError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Thao tác thất bại, vui lòng thử lại', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is FarmLoading) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          // A failed action keeps the garden on screen; only a first load shows the error view.
          FarmLoaded? loaded = _lastLoaded;
          if (state is FarmLoaded) loaded = state;
          if (state is FarmActionSuccess) loaded = state.refreshed;
          _lastLoaded = loaded;

          if (loaded == null) {
            return _ErrorView(
              onRetry: () => ctx.read<FarmBloc>().add(FarmLoadRequested()),
            );
          }

          final sortedPlots = List<FarmPlot?>.filled(8, null);
          for (final p in loaded.plots) {
            if (p.slotIndex < 8) sortedPlots[p.slotIndex] = p;
          }

          // Phân chia 8 plots thành 2 Tầng Mây:
          // Tầng 2 (Thần thoại - trên cao): plots [4, 5, 6, 7]
          // Tầng 1 (Bồng bềnh - phía dưới): plots [0, 1, 2, 3]
          final floor2Plots = sortedPlots.sublist(4, 8);
          final floor1Plots = sortedPlots.sublist(0, 4);
          final (hintText, hintAction) = _nextHint(context, loaded);
          final dropsNeeded = loaded.plots
              .where((p) => p.stage == 1)
              .fold<int>(0, (sum, p) => sum + math.max(p.wordsNeeded - p.wordsProgress, 0));

          return Stack(
            children: [
              // 1. BACKGROUND BẦU TRỜI XANH VÀ MÂY
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0284C7), // Xanh thẳm trên cao
                        Color(0xFF38BDF8), // Xanh mây bồng bềnh
                        Color(0xFF7DD3FC),
                        Color(0xFFE0F2FE), // Chân trời trắng mây
                      ],
                    ),
                  ),
                ),
              ),

              // 2. DÂY LEO ĐẬU THẦN (Jack's Beanstalk) BÊN TRÁI
              Positioned.fill(
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: FarmImage('beanstalk', width: 52, height: double.infinity, fit: BoxFit.fill),
                ),
              ),

              // 3. DANH SÁCH TẦNG MÂY CUỘN DỌC (Scrollable Cloud Shelves)
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async => ctx.read<FarmBloc>().add(FarmLoadRequested()),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(top: 80, bottom: 100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(44, 0, 12, 12),
                        child: Material(
                          color: _parchment,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: _woodDark, width: 2),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: hintAction,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Text(
                                  hintAction == null ? hintText : '$hintText →',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Center(child: FarmImage('island-home', width: 210)),
                      const SizedBox(height: 6),

                      // TẦNG MÂY 2 (Thượng Tầng)
                      _CloudFloorSection(
                        floorNumber: 2,
                        floorTitle: 'TẦNG THẦN THOẠI',
                        pet: 'pet-corgi',
                        plots: floor2Plots,
                        catalog: loaded.cropCatalog,
                        animCtrl: _animCtrl,
                        onPotTap: (plot, slotIdx) {
                          if (plot == null || plot.stage == 0) {
                            HapticFeedback.selectionClick();
                            _showPlantSheet(context, slotIdx, loaded!.cropCatalog);
                          } else if (plot.stage == 2) {
                            HapticFeedback.mediumImpact();
                            ctx.read<FarmBloc>().add(FarmHarvestPlot(plot.id));
                          } else {
                            _showVocabQuizDialog(context, plot);
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      // TẦNG MÂY 1 (Hạ Tầng)
                      _CloudFloorSection(
                        floorNumber: 1,
                        floorTitle: 'TẦNG BỒNG BỀNH',
                        pet: 'pet-cat',
                        plots: floor1Plots,
                        catalog: loaded.cropCatalog,
                        animCtrl: _animCtrl,
                        onPotTap: (plot, slotIdx) {
                          if (plot == null || plot.stage == 0) {
                            HapticFeedback.selectionClick();
                            _showPlantSheet(context, slotIdx, loaded!.cropCatalog);
                          } else if (plot.stage == 2) {
                            HapticFeedback.mediumImpact();
                            ctx.read<FarmBloc>().add(FarmHarvestPlot(plot.id));
                          } else {
                            _showVocabQuizDialog(context, plot);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 4. TOP HUD: chỉ hiển thị dữ liệu thật từ server
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _GameTopHud(
                  coins: loaded.coins,
                  dropsNeeded: dropsNeeded,
                  onBack: () => Navigator.pop(context),
                ),
              ),

              // 5. MENU: Đơn hàng, Kho nông sản
              Positioned(
                right: 14,
                bottom: 24,
                child: Column(
                  children: [
                    _SideCircleButton(
                      asset: 'icon-orders',
                      color: const Color(0xFF10B981),
                      badgeText: () {
                        final count = loaded!.orders
                            .where((o) => o.items.every((it) => (loaded!.inventory[it.type] ?? 0) >= it.qty))
                            .length;
                        return count > 0 ? '$count' : null;
                      }(),
                      onTap: () => _showOrdersModal(context, loaded!.orders, loaded.inventory, loaded.cropCatalog),
                    ),
                    const SizedBox(height: 10),
                    _SideCircleButton(
                      asset: 'icon-inventory',
                      color: const Color(0xFF0284C7),
                      onTap: () => _showInventoryModal(context, loaded!.inventory),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// WIDGET: MỘT TẦNG MÂY KHU VƯỜN (Cloud Floor Section)
// ============================================================================
class _CloudFloorSection extends StatelessWidget {
  final int floorNumber;
  final String floorTitle;
  final String pet;
  final List<FarmPlot?> plots;
  final Map<String, dynamic> catalog;
  final AnimationController animCtrl;
  final Function(FarmPlot?, int slotIdx) onPotTap;

  const _CloudFloorSection({
    required this.floorNumber,
    required this.floorTitle,
    required this.pet,
    required this.plots,
    required this.catalog,
    required this.animCtrl,
    required this.onPotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.only(left: 34, right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 34),
                child: AspectRatio(
                  aspectRatio: 1.55,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // Pots shrink with the cloud so four of them always fit on a small phone.
                      final scale = (box.maxWidth / 340).clamp(0.72, 1.3);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: FarmImage('cloud-fence', fit: BoxFit.fill)),
                          Positioned(
                            left: box.maxWidth * 0.03,
                            right: box.maxWidth * 0.14,
                            bottom: box.maxHeight * 0.1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(4, (i) {
                                final plot = plots[i];
                                final slotIdx = (floorNumber == 2) ? (4 + i) : i;
                                return _SkyPotWidget(
                                  plot: plot,
                                  slotIndex: slotIdx,
                                  animCtrl: animCtrl,
                                  scale: scale,
                                  onTap: () => onPotTap(plot, slotIdx),
                                );
                              }),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: box.maxHeight * 0.06,
                            child: FarmImage(pet, width: box.maxWidth * 0.15),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _wood,
                  borderRadius: BorderRadius.circular(9),
                  border: const Border(bottom: BorderSide(color: _woodDark, width: 3)),
                ),
                child: Text(
                  floorTitle,
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFFFF8E7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: CHẬU CÂY THẦN TIÊN + CÂY TRỒNG + GIỎ THU HOẠCH
// ============================================================================
class _SkyPotWidget extends StatelessWidget {
  final FarmPlot? plot;
  final int slotIndex;
  final AnimationController animCtrl;
  final double scale;
  final VoidCallback onTap;

  const _SkyPotWidget({
    required this.plot,
    required this.slotIndex,
    required this.animCtrl,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stage = plot?.stage ?? 0;
    final cropType = plot?.cropType ?? '';
    final level = growthLevel(plot?.wordsProgress ?? 0, plot?.wordsNeeded ?? 0, ripe: stage == 2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // KHU VỰC CÂY TRỒNG & GIỎ THU HOẠCH
          SizedBox(
            height: 68 * scale,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (stage == 0) ...[
                  // Chậu rỗng: Nút + phát sáng mời gieo hạt
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                ] else if (stage == 1) ...[
                  // Cây đang lớn với hoạt ảnh lắc lư nhẹ
                  AnimatedBuilder(
                    animation: animCtrl,
                    builder: (context, child) {
                      final sway = math.sin(animCtrl.value * 2 * math.pi + slotIndex) * 0.08;
                      return Transform.rotate(
                        angle: sway,
                        child: child,
                      );
                    },
                    child: CropArt(crop: cropType, level: level, size: 60 * scale),
                  ),
                ] else ...[
                  // Cây chín sẵn sàng thu hoạch (Stage 2)
                  AnimatedBuilder(
                    animation: animCtrl,
                    builder: (context, child) {
                      final bounce = math.sin(animCtrl.value * 4 * math.pi + slotIndex) * 3;
                      return Transform.translate(
                        offset: Offset(0, bounce),
                        child: child,
                      );
                    },
                    child: CropArt(crop: cropType, level: level, size: 64 * scale),
                  ),

                  // Giỏ vàng thu hoạch lắc lư rung rinh trên đầu cây chín
                  Positioned(
                    top: 0,
                    right: -2,
                    child: AnimatedBuilder(
                      animation: animCtrl,
                      builder: (ctx, child) {
                        final rot = math.sin(animCtrl.value * 5 * math.pi) * 0.15;
                        return Transform.rotate(
                          angle: rot,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const FarmImage('basket', width: 18, height: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 2),

          // CHẬU CÂY
          FarmImage('pot-${slotIndex % 4}', width: 58 * scale, height: 46 * scale),

          // Trạng thái bằng chữ, không chỉ dựa vào màu
          if (stage != 0)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: stage == 2 ? const Color(0xFFFDE047) : const Color(0xFF0C2D48),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stage == 2 ? 'Chín' : '${plot?.wordsProgress}/${plot?.wordsNeeded}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: stage == 2 ? const Color(0xFF0C2D48) : Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: TOP GAME HUD BAR (Level, Coins, Gems, Energy)
// ============================================================================
class _GameTopHud extends StatelessWidget {
  final int coins;
  final int dropsNeeded;
  final VoidCallback onBack;

  const _GameTopHud({
    required this.coins,
    required this.dropsNeeded,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 42, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // NÚT BACK & VÒNG LEVEL
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),

          // CHỈ SỐ TIỀN TỆ: VÀNG, KIM CƯƠNG, NĂNG LƯỢNG
          Row(
            children: [
              _HudPill(iconAsset: 'coin', value: '$coins', color: const Color(0xFFF59E0B)),
              const SizedBox(width: 5),
              _HudPill(iconAsset: 'drop', value: 'còn $dropsNeeded từ', color: const Color(0xFF0EA5E9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  final String iconAsset;
  final String value;
  final Color color;

  const _HudPill({required this.iconAsset, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _woodDark, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmImage(iconAsset, width: 18, height: 18),
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.outfit(color: _ink, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: SIDE BUTTON TRÒN MENU GAME
// ============================================================================
class _SideCircleButton extends StatelessWidget {
  final String asset;
  final Color color;
  final String? badgeText;
  final VoidCallback onTap;

  const _SideCircleButton({
    required this.asset,
    required this.color,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Padding(padding: const EdgeInsets.all(6), child: FarmImage(asset)),
          ),
          if (badgeText != null)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text(
                  badgeText!,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET: ĐƠN HÀNG NÔNG SẢN (Farm Orders)
// ============================================================================
class _OrdersSheet extends StatelessWidget {
  final List<FarmOrder> orders;
  final Map<String, int> inventory;
  final Map<String, dynamic> catalog;

  const _OrdersSheet({
    required this.orders,
    required this.inventory,
    required this.catalog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      decoration: _sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const FarmImage('icon-orders', width: 26, height: 26),
              const SizedBox(width: 6),
              Text(
                'Đơn Hàng Phù Thủy',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${orders.length} đơn',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Không có đơn hàng nào chờ xử lý',
                  style: GoogleFonts.outfit(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...orders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OrderCardItem(order: o, inventory: inventory, catalog: catalog),
                )),
        ],
      ),
    );
  }
}

class _OrderCardItem extends StatelessWidget {
  final FarmOrder order;
  final Map<String, int> inventory;
  final Map<String, dynamic> catalog;

  const _OrderCardItem({
    required this.order,
    required this.inventory,
    required this.catalog,
  });

  bool _canFulfill() {
    for (final it in order.items) {
      if ((inventory[it.type] ?? 0) < it.qty) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final canFulfill = _canFulfill();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canFulfill ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canFulfill ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              children: order.items.map((it) {
                final have = inventory[it.type] ?? 0;
                final enough = have >= it.qty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: enough ? const Color(0xFFDCFCE7) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: enough ? const Color(0xFF4ADE80) : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CropArt(crop: it.type, level: 2, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        '$have/${it.qty}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: enough ? const Color(0xFF16A34A) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${order.rewardCoins} xu · +${order.rewardXp} XP',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: canFulfill
                    ? () {
                        HapticFeedback.lightImpact();
                        context.read<FarmBloc>().add(FarmFulfillOrder(order.id));
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  canFulfill ? 'Giao' : 'Thiếu',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET: KHO NÔNG SẢN (Inventory Sheet)
// ============================================================================
class _InventorySheet extends StatelessWidget {
  final Map<String, int> inventory;
  const _InventorySheet({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final nonZeroItems = inventory.entries.where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      decoration: _sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const FarmImage('icon-inventory', width: 26, height: 26),
              const SizedBox(width: 6),
              Text('Kho Nông Sản Của Bạn', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          if (nonZeroItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Kho đang trống. Hãy thu hoạch cây trồng!', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: nonZeroItems.length,
              itemBuilder: (ctx, i) {
                final item = nonZeroItems[i];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CropArt(crop: item.key, level: 2, size: 44),
                      const SizedBox(height: 4),
                      Text(
                        _cropNameVi[item.key] ?? item.key,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text('Số lượng: ${item.value}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET: CHỌN HẠT GIỐNG GIEO VÀO CHẬU
// ============================================================================
class _PlantSheet extends StatelessWidget {
  final int slotIndex;
  final Map<String, dynamic> catalog;

  const _PlantSheet({required this.slotIndex, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final crops = catalog.entries.toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      decoration: _sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const FarmImage('crop-herbs-0', width: 26, height: 26),
              const SizedBox(width: 6),
              Text('Gieo Hạt Vào Chậu', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mỗi câu hỏi từ vựng ôn tập đúng sẽ tưới nước giúp cây mau lớn',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
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
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CropArt(crop: key, level: 2, size: 46),
                      const SizedBox(height: 4),
                      Text(
                        _cropNameVi[key] ?? key,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Cần $wordsNeeded từ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR VIEW
// ============================================================================
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FarmImage('pet-cat', width: 96, height: 96),
          const SizedBox(height: 12),
          Text('Không thể tải nông trại trên mây', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
