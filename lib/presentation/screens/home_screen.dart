import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../services/cloudflare_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;

  // Pet
  String _petName = 'Mochi';
  String _petType = 'cat';
  int _hunger = 100;
  int _happiness = 100;
  int _xpBonusPct = 0;
  int _coins = 0;

  // Room
  List<Map<String, dynamic>> _furniture = [];
  List<String> _ownedItemIds = [];

  // Shop catalog (from server)
  List<Map<String, dynamic>> _shop = [];

  CloudflareService get _service => context.read<CloudflareService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getHomeState();
      final pet = data['pet'] as Map<String, dynamic>? ?? {};
      final furniture = (data['furniture'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [];
      final owned = (data['owned_item_ids'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      final shop = (data['shop'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [];

      if (!mounted) return;
      setState(() {
        _petName = (pet['name'] ?? 'Mochi').toString();
        _petType = (pet['type'] ?? 'cat').toString();
        _hunger = (pet['hunger'] as num?)?.toInt() ?? 100;
        _happiness = (pet['happiness'] as num?)?.toInt() ?? 100;
        _xpBonusPct = (pet['xp_bonus_pct'] as num?)?.toInt() ?? 0;
        _coins = (data['coins'] as num?)?.toInt() ?? 0;
        _furniture = furniture;
        _ownedItemIds = owned;
        _shop = shop;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showFeedSheet() {
    final foodItems = _shop.where((i) => i['category'] == 'pet_food').toList();
    _showItemSheet(
      title: 'Cho Mochi ăn',
      items: foodItems,
      onBuy: (itemId) async {
        await _service.petFeed(itemId);
        await _load();
      },
    );
  }

  void _showPlaySheet() {
    final toys = _shop.where((i) => i['category'] == 'pet_toy').toList();
    _showItemSheet(
      title: 'Chơi với Mochi',
      items: toys,
      onBuy: (itemId) async {
        await _service.petPlay(itemId);
        await _load();
      },
    );
  }

  void _showFurnitureShopForSlot(int slot) {
    final furniture = _shop.where((i) => i['category'] == 'furniture').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FurnitureShopSheet(
        items: furniture,
        ownedItemIds: _ownedItemIds,
        coins: _coins,
        targetSlot: slot,
        onBuy: (itemId) async {
          await _service.shopBuyFurniture(itemId, slot);
          await _load();
        },
      ),
    );
  }

  void _showItemSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required Future<void> Function(String itemId) onBuy,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemSheet(
        title: title,
        items: items,
        coins: _coins,
        onBuy: (itemId) async {
          Navigator.pop(context);
          try {
            await onBuy(itemId);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.toString(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          }
        },
      ),
    );
  }

  Future<void> _removeFurniture(String id) async {
    try {
      await _service.removeFurniture(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const Text('🏠', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Nhà Của $_petName',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.textColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          _CoinChip(coins: _coins),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PetCard(
                          name: _petName,
                          petType: _petType,
                          hunger: _hunger,
                          happiness: _happiness,
                          xpBonus: _xpBonusPct,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                emoji: '🍽️',
                                label: 'Cho ăn',
                                color: AppTheme.accentOrange,
                                onTap: _showFeedSheet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                emoji: '🎮',
                                label: 'Chơi cùng',
                                color: context.primaryColor,
                                onTap: _showPlaySheet,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(label: 'Phòng của bạn'),
                        const SizedBox(height: 12),
                        _RoomGrid(
                          furniture: _furniture,
                          shopCatalog: _shop,
                          onTapEmpty: _showFurnitureShopForSlot,
                          onRemove: _removeFurniture,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Nhấn ô trống để mua đồ nội thất',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: context.subTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ── Pet Card ──────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  final String name;
  final String petType;
  final int hunger;
  final int happiness;
  final int xpBonus;

  const _PetCard({
    required this.name,
    required this.petType,
    required this.hunger,
    required this.happiness,
    required this.xpBonus,
  });

  String get _petEmoji {
    switch (petType) {
      case 'dog': return '🐶';
      case 'bunny': return '🐰';
      default: return '🐱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_petEmoji, style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (xpBonus > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+$xpBonus% XP',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _StatBar(label: '🍖 Đói', value: hunger, color: AppTheme.accentOrange),
                const SizedBox(height: 6),
                _StatBar(label: '💛 Vui', value: happiness, color: AppTheme.successGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room Grid ─────────────────────────────────────────────────

class _RoomGrid extends StatelessWidget {
  final List<Map<String, dynamic>> furniture;
  final List<Map<String, dynamic>> shopCatalog;
  final void Function(int slot) onTapEmpty;
  final void Function(String id) onRemove;
  const _RoomGrid({
    required this.furniture,
    required this.shopCatalog,
    required this.onTapEmpty,
    required this.onRemove,
  });

  String _emojiFor(String itemId) {
    for (final s in shopCatalog) {
      if (s['id'] == itemId) return (s['emoji'] as String?) ?? '📦';
    }
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    // Map slot → furniture
    final Map<int, Map<String, dynamic>> slotMap = {};
    for (final f in furniture) {
      final slot = (f['room_slot'] as num?)?.toInt();
      if (slot != null) slotMap[slot] = f;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: 16,
      itemBuilder: (ctx, i) {
        final item = slotMap[i];
        if (item != null) {
          return GestureDetector(
            onLongPress: () => _confirmRemove(context, item),
            child: Container(
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  _emojiFor((item['item_id'] ?? '') as String),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: () => onTapEmpty(i),
          child: Container(
            decoration: BoxDecoration(
              color: context.softBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.borderColor,
                  style: BorderStyle.solid),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: context.subTextColor,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, Map<String, dynamic> item) {
    final id = item['id'] as String?;
    if (id == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dọn đồ?',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: context.textColor)),
        content: Text(
          'Xóa đồ nội thất này? (Không hoàn tiền)',
          style: GoogleFonts.plusJakartaSans(color: context.subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.outfit(color: context.subTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Dọn',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Shop Sheets ───────────────────────────────────────────────

class _ItemSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int coins;
  final void Function(String itemId) onBuy;

  const _ItemSheet({
    required this.title,
    required this.items,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor)),
              _CoinChip(coins: coins),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final price = (item['price'] as num?)?.toInt() ?? 0;
            final canAfford = coins >= price;
            final restoreHunger = (item['hunger_restore'] as num?)?.toInt();
            final restoreHappy = (item['happiness_restore'] as num?)?.toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: canAfford ? () => onBuy(item['id'] as String) : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? context.softBgColor
                        : context.softBgColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canAfford
                          ? context.borderColor
                          : context.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(item['emoji'] ?? '?',
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: canAfford
                                    ? context.textColor
                                    : context.subTextColor,
                              ),
                            ),
                            Text(
                              restoreHunger != null
                                  ? '+$restoreHunger no đói'
                                  : restoreHappy != null
                                      ? '+$restoreHappy vui'
                                      : item['description'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: context.subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 3),
                          Text(
                            '$price',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: canAfford
                                  ? AppTheme.accentOrange
                                  : context.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FurnitureShopSheet extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> ownedItemIds;
  final int coins;
  final int targetSlot;
  final void Function(String itemId) onBuy;

  const _FurnitureShopSheet({
    required this.items,
    required this.ownedItemIds,
    required this.coins,
    required this.targetSlot,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mua Nội Thất',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor)),
              _CoinChip(coins: coins),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Đặt vào ô ${targetSlot + 1}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: context.subTextColor),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final price = (item['price'] as num?)?.toInt() ?? 0;
              final id = item['id'] as String;
              final owned = ownedItemIds.contains(id);
              final canAfford = coins >= price && !owned;

              return GestureDetector(
                onTap: canAfford
                    ? () {
                        Navigator.pop(context);
                        onBuy(id);
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: owned
                        ? context.primaryColor.withValues(alpha: 0.06)
                        : canAfford
                            ? context.softBgColor
                            : context.softBgColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: owned
                          ? context.primaryColor.withValues(alpha: 0.3)
                          : context.borderColor,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['emoji'] ?? '📦',
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        item['name'] ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      if (owned)
                        Text('Đã có',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9, color: context.primaryColor))
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪙',
                                style: TextStyle(fontSize: 10)),
                            Text(
                              '$price',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: canAfford
                                    ? AppTheme.accentOrange
                                    : context.subTextColor,
                              ),
                            ),
                          ],
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

// ── Shared ────────────────────────────────────────────────────

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
        border:
            Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
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
  const _SectionHeader({required this.label});

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
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏠', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Không thể tải dữ liệu',
              style: GoogleFonts.outfit(
                  color: context.textColor, fontWeight: FontWeight.w600)),
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
