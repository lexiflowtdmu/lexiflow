import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../services/cloudflare_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final CloudflareService _svc;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _svc = context.read<CloudflareService>();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Admin Panel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: context.textColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.subTextColor,
          indicatorColor: context.primaryColor,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Người dùng'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Nội dung'),
            Tab(icon: Icon(Icons.shield_rounded, size: 18), text: 'Kiểm duyệt'),
            Tab(icon: Icon(Icons.agriculture_rounded, size: 18), text: 'Farm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StatsTab(svc: _svc),
          _UsersTab(svc: _svc),
          _ContentTab(svc: _svc),
          _ModerationTab(svc: _svc),
          _FarmTab(svc: _svc),
        ],
      ),
    );
  }
}

// ─── Tab 1: Tổng quan ─────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  final CloudflareService svc;
  const _StatsTab({required this.svc});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.svc.adminGetStats(),
        widget.svc.adminGetActivity(days: 7),
        widget.svc.adminGetLeaderboard(limit: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _activity = (results[1] as List).cast<Map<String, dynamic>>();
        _leaderboard = (results[2] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat cards grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _StatCard(label: 'Tổng người dùng', value: '${_stats['total_users'] ?? 0}',
                  icon: Icons.people_rounded, color: context.primaryColor),
              _StatCard(label: 'Hoạt động hôm nay', value: '${_stats['active_today'] ?? 0}',
                  icon: Icons.bolt_rounded, color: AppTheme.successGreen),
              _StatCard(label: 'Thẻ ôn tập', value: '${_stats['total_cards'] ?? 0}',
                  icon: Icons.style_rounded, color: AppTheme.accentOrange),
              _StatCard(label: 'Đánh giá hôm nay', value: '${_stats['reviews_today'] ?? 0}',
                  icon: Icons.rate_review_rounded, color: AppTheme.accentPurple),
              _StatCard(label: 'Coin lưu thông', value: '${_stats['total_coins'] ?? 0}',
                  icon: Icons.monetization_on_rounded, color: const Color(0xFFD97706)),
              _StatCard(label: 'Đơn hàng farm', value: '${_stats['fulfilled_orders'] ?? 0}',
                  icon: Icons.agriculture_rounded, color: const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 20),

          // Activity chart (simple bar)
          if (_activity.isNotEmpty) ...[
            _SectionTitle('Hoạt động 7 ngày qua'),
            const SizedBox(height: 10),
            _ActivityBars(data: _activity),
            const SizedBox(height: 20),
          ],

          // Top users
          if (_leaderboard.isNotEmpty) ...[
            _SectionTitle('Top người dùng XP'),
            const SizedBox(height: 8),
            ..._leaderboard.asMap().entries.map((e) =>
              _LeaderboardRow(rank: e.key + 1, user: e.value)),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 2: Người dùng ────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  final CloudflareService svc;
  const _UsersTab({required this.svc});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  int _offset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) { _offset = 0; _hasMore = true; }
    setState(() => _loading = true);
    try {
      final result = await widget.svc.adminGetUsers(
        q: _search.text.trim(),
        limit: 20,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _users = result;
        } else {
          _users.addAll(result);
        }
        _hasMore = result.length == 20;
        _offset += result.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  void _showEditSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserSheet(svc: widget.svc, user: user, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            style: GoogleFonts.outfit(color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Tìm UID, email, tên, #LEXI-XXXX...',
              hintStyle: GoogleFonts.outfit(color: context.subTextColor),
              prefixIcon: Icon(Icons.search_rounded, color: context.subTextColor),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: context.subTextColor),
                      onPressed: () { _search.clear(); _load(); },
                    )
                  : null,
              filled: true,
              fillColor: context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _load(),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(
          child: _loading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _users.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: () => _load(reset: false),
                            child: Text('Tải thêm',
                                style: GoogleFonts.outfit(color: context.primaryColor)),
                          ),
                        ),
                      );
                    }
                    return _UserCard(
                      user: _users[i],
                      onTap: () => _showEditSheet(_users[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Kiểm duyệt ───────────────────────────────────────────────────────

class _ModerationTab extends StatefulWidget {
  final CloudflareService svc;
  const _ModerationTab({required this.svc});

  @override
  State<_ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends State<_ModerationTab> {
  List<Map<String, dynamic>> _flagged = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await widget.svc.adminGetFlaggedSessions();
      if (!mounted) return;
      setState(() { _flagged = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String sessionId, String action) async {
    try {
      await widget.svc.adminResolveSession(sessionId, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve' ? '✓ Đã phê duyệt' : '✗ Đã từ chối'),
        backgroundColor: action == 'approve' ? AppTheme.successGreen : AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _flagged.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 64, color: AppTheme.successGreen.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('Không có phiên đáng ngờ',
                          style: GoogleFonts.outfit(
                              color: context.subTextColor, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _flagged.length,
              itemBuilder: (context, i) {
                final s = _flagged[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppTheme.accentOrange, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Session: ${s['sessionId'] ?? '—'}',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (s['flagReason'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          s['flagReason'].toString(),
                          style: GoogleFonts.outfit(
                              color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'UID: ${(s['uid'] ?? '').toString().substring(0, 12)}…  '
                        'Điểm: ${s['earnedXp'] ?? 0} XP',
                        style: GoogleFonts.outfit(
                            color: context.subTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _resolve(s['sessionId'] ?? '', 'reject'),
                              icon: const Icon(Icons.block_rounded, size: 16),
                              label: const Text('Từ chối'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                                side: BorderSide(
                                    color: AppTheme.errorRed.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolve(s['sessionId'] ?? '', 'approve'),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Phê duyệt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Tab 4: Farm ──────────────────────────────────────────────────────────────

class _FarmTab extends StatefulWidget {
  final CloudflareService svc;
  const _FarmTab({required this.svc});

  @override
  State<_FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<_FarmTab> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await widget.svc.adminGetFarmStats();
      if (!mounted) return;
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final topCoins = (_data['top_coin_users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final inventory = (_data['inventory_totals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final orders = (_data['order_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (orders.isNotEmpty) ...[
            _SectionTitle('Đơn hàng theo trạng thái'),
            const SizedBox(height: 8),
            ...orders.map((o) => _DataRow(
              label: _orderStatusLabel(o['status']?.toString() ?? ''),
              value: '${o['n'] ?? 0} đơn',
              icon: _orderStatusIcon(o['status']?.toString() ?? ''),
            )),
            const SizedBox(height: 20),
          ],
          if (inventory.isNotEmpty) ...[
            _SectionTitle('Tồn kho farm toàn hệ thống'),
            const SizedBox(height: 8),
            ...inventory.map((inv) => _DataRow(
              label: inv['item_type']?.toString() ?? '',
              value: '${inv['total'] ?? 0} đơn vị',
              icon: Icons.inventory_2_rounded,
            )),
            const SizedBox(height: 20),
          ],
          if (topCoins.isNotEmpty) ...[
            _SectionTitle('Top người dùng Coin'),
            const SizedBox(height: 8),
            ...topCoins.asMap().entries.map((e) => _DataRow(
              label: e.value['display_name']?.toString() ?? '—',
              value: '${e.value['coins'] ?? 0} 🪙  (${e.value['pet_name'] ?? 'Mochi'})',
              icon: Icons.monetization_on_rounded,
              rank: e.key + 1,
            )),
          ],
        ],
      ),
    );
  }

  String _orderStatusLabel(String s) {
    switch (s) {
      case 'active': return 'Đang chờ';
      case 'fulfilled': return 'Đã hoàn thành';
      case 'expired': return 'Hết hạn';
      default: return s;
    }
  }

  IconData _orderStatusIcon(String s) {
    switch (s) {
      case 'active': return Icons.hourglass_empty_rounded;
      case 'fulfilled': return Icons.check_circle_rounded;
      case 'expired': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }
}

// ─── Edit User Bottom Sheet ───────────────────────────────────────────────────

class _EditUserSheet extends StatefulWidget {
  final CloudflareService svc;
  final Map<String, dynamic> user;
  final VoidCallback onDone;
  const _EditUserSheet({required this.svc, required this.user, required this.onDone});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _xpController = TextEditingController();
  final _coinsController = TextEditingController();
  final _levelController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _isBanned = false;
  Map<String, dynamic> _fullProfile = {};
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['display_name']?.toString() ?? '';
    _levelController.text = '${widget.user['level'] ?? 1}';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await widget.svc.adminGetUser(widget.user['uid']?.toString() ?? '');
      if (!mounted) return;
      final u = result['user'] as Map<String, dynamic>? ?? {};
      setState(() {
        _fullProfile = result;
        _isBanned = (u['is_banned'] as num?)?.toInt() == 1;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _toggleBan() async {
    final uid = widget.user['uid']?.toString() ?? '';
    final name = widget.user['display_name']?.toString() ?? uid;

    if (_isBanned) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardColor,
          title: Text('Mở khóa tài khoản?',
              style: GoogleFonts.outfit(color: context.textColor, fontWeight: FontWeight.bold)),
          content: Text('Mở khóa "$name"?',
              style: GoogleFonts.outfit(color: context.subTextColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: Text('Hủy', style: GoogleFonts.outfit(color: context.subTextColor))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
              child: Text('Mở khóa', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => _saving = true);
      try {
        await widget.svc.adminUnbanUser(uid);
        setState(() { _isBanned = false; _saving = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã mở khóa tài khoản'),
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        setState(() => _saving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      String reason = '';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            backgroundColor: context.cardColor,
            title: Text('Khóa tài khoản?',
                style: GoogleFonts.outfit(color: context.textColor, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Khóa "$name"? Người dùng sẽ không thể đăng nhập.',
                    style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.outfit(color: context.textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Lý do khóa (tùy chọn)...',
                    hintStyle: GoogleFonts.outfit(color: context.subTextColor),
                    filled: true,
                    fillColor: context.softBgColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => reason = v,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Hủy', style: GoogleFonts.outfit(color: context.subTextColor))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                child: Text('Khóa', style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
      setState(() => _saving = true);
      try {
        await widget.svc.adminBanUser(uid, reason: reason);
        setState(() { _isBanned = true; _saving = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Đã khóa tài khoản'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorRed,
        ));
      } catch (e) {
        setState(() => _saving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final uid = widget.user['uid']?.toString() ?? '';
    final name = widget.user['display_name']?.toString() ?? uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Gửi email reset?',
            style: GoogleFonts.outfit(color: context.textColor, fontWeight: FontWeight.bold)),
        content: Text(
          'Gửi email reset mật khẩu đến "$name"?\nNgười dùng sẽ nhận được link đặt lại qua email đăng ký.',
          style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy', style: GoogleFonts.outfit(color: context.subTextColor))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: Text('Gửi', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      final email = await widget.svc.adminResetPassword(uid);
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã gửi email reset tới $email'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.successGreen,
      ));
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _xpController.dispose();
    _coinsController.dispose();
    _levelController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final xp = int.tryParse(_xpController.text.trim());
      final coins = int.tryParse(_coinsController.text.trim());
      final level = int.tryParse(_levelController.text.trim());
      final name = _nameController.text.trim();

      await widget.svc.adminEditUser(
        widget.user['uid']?.toString() ?? '',
        grantXp: xp,
        setLevel: level,
        displayName: name.isNotEmpty ? name : null,
        grantCoins: coins,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onDone();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã cập nhật người dùng'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _delete() async {
    final uid = widget.user['uid']?.toString() ?? '';
    final name = widget.user['display_name']?.toString() ?? uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Xóa tài khoản?',
            style: GoogleFonts.outfit(color: context.textColor, fontWeight: FontWeight.bold)),
        content: Text(
          'Tất cả dữ liệu của "$name" sẽ bị xóa vĩnh viễn. Không thể hoàn tác.',
          style: GoogleFonts.outfit(color: context.subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Huỷ', style: GoogleFonts.outfit(color: context.subTextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Xóa', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await widget.svc.adminDeleteUser(uid);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDone();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã xóa tài khoản'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final u = _fullProfile['user'] as Map<String, dynamic>? ?? user;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: user['avatar_url'] != null &&
                          user['avatar_url'].toString().isNotEmpty
                      ? NetworkImage(user['avatar_url'].toString())
                      : null,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                  child: user['avatar_url'] == null ||
                          user['avatar_url'].toString().isEmpty
                      ? Icon(Icons.person_rounded, color: context.primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u['display_name']?.toString() ?? '—',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                            fontSize: 16),
                      ),
                      Text(
                        u['email']?.toString() ?? '—',
                        style: GoogleFonts.outfit(
                            color: context.subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    u['user_code']?.toString() ?? '',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Banned banner
            if (_isBanned) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppTheme.errorRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tài khoản đang bị khóa',
                        style: GoogleFonts.outfit(
                            color: AppTheme.errorRed, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Quick stats
            if (!_loadingProfile) ...[
              Row(
                children: [
                  _MiniStat(label: 'XP', value: '${u['xp'] ?? 0}', color: context.primaryColor),
                  _MiniStat(label: 'Level', value: '${u['level'] ?? 1}', color: AppTheme.accentOrange),
                  _MiniStat(
                    label: 'Thẻ',
                    value: '${_fullProfile['total_cards'] ?? 0}',
                    color: AppTheme.accentPurple,
                  ),
                  _MiniStat(
                    label: 'Streak',
                    value: '${_fullProfile['streak']?['current_streak'] ?? 0}🔥',
                    color: AppTheme.errorRed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            Divider(color: context.borderColor),
            const SizedBox(height: 12),

            Text('Chỉnh sửa',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                    fontSize: 15)),
            const SizedBox(height: 12),

            // Fields
            _AdminField(
              controller: _nameController,
              label: 'Tên hiển thị',
              hint: 'Tên mới...',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminField(
                    controller: _xpController,
                    label: 'Cộng/trừ XP',
                    hint: 'VD: 500 hoặc -100',
                    icon: Icons.stars_rounded,
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminField(
                    controller: _coinsController,
                    label: 'Cộng/trừ Coin',
                    hint: 'VD: 200 hoặc -50',
                    icon: Icons.monetization_on_rounded,
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminField(
              controller: _levelController,
              label: 'Đặt Level',
              hint: '1–999',
              icon: Icons.trending_up_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // UID copy row
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: user['uid']?.toString() ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Đã sao chép UID'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.softBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint_rounded,
                        color: context.subTextColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user['uid']?.toString() ?? '',
                        style: GoogleFonts.outfit(
                            color: context.subTextColor,
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.copy_rounded, color: context.subTextColor, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Lưu thay đổi',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            // Ban / Unban
            OutlinedButton.icon(
              onPressed: _saving ? null : _toggleBan,
              icon: Icon(
                _isBanned ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 18,
              ),
              label: Text(
                _isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: _isBanned ? AppTheme.successGreen : AppTheme.accentOrange,
                side: BorderSide(
                    color: (_isBanned ? AppTheme.successGreen : AppTheme.accentOrange)
                        .withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            // Reset password
            OutlinedButton.icon(
              onPressed: _saving ? null : _resetPassword,
              icon: const Icon(Icons.email_rounded, size: 18),
              label: Text('Gửi email reset mật khẩu',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: context.primaryColor,
                side: BorderSide(color: context.primaryColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            // Delete account
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text('Xóa tài khoản này',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: context.subTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ActivityBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxReviews = data.fold<int>(0, (m, d) {
      final n = (d['reviews'] as num?)?.toInt() ?? 0;
      return n > m ? n : m;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final n = (d['reviews'] as num?)?.toInt() ?? 0;
              final frac = maxReviews > 0 ? n / maxReviews : 0.0;
              final dateStr = (d['date'] as String? ?? '').split('-').skip(1).join('/');
              return Expanded(
                child: Column(
                  children: [
                    Text('$n',
                        style: GoogleFonts.outfit(
                            fontSize: 9, color: context.subTextColor)),
                    const SizedBox(height: 2),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 60 * frac + 4,
                      decoration: BoxDecoration(
                        color: context.primaryColor
                            .withValues(alpha: 0.3 + 0.5 * frac),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: GoogleFonts.outfit(
                            fontSize: 9, color: context.subTextColor)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  const _LeaderboardRow({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFD97706),
      const Color(0xFF6B7280),
      const Color(0xFF92400E),
    ];
    final rankColor = rank <= 3 ? colors[rank - 1] : context.subTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                  fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              user['display_name']?.toString() ?? '—',
              style: GoogleFonts.outfit(color: context.textColor, fontSize: 13),
            ),
          ),
          Text(
            '${user['xp'] ?? 0} XP  🔥${user['current_streak'] ?? 0}',
            style: GoogleFonts.outfit(
                color: context.subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.primaryColor.withValues(alpha: 0.12),
              backgroundImage: user['avatar_url'] != null &&
                      user['avatar_url'].toString().isNotEmpty
                  ? NetworkImage(user['avatar_url'].toString())
                  : null,
              child: (user['avatar_url'] == null ||
                      user['avatar_url'].toString().isEmpty)
                  ? Text(
                      (user['display_name']?.toString() ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['display_name']?.toString() ?? '—',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                        fontSize: 13),
                  ),
                  Text(
                    '${user['user_code'] ?? ''} · Lv.${user['level'] ?? 1} · ${user['xp'] ?? 0} XP',
                    style: GoogleFonts.outfit(
                        color: context.subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '🔥 ${user['current_streak'] ?? 0}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: context.subTextColor),
                ),
                Text(
                  '🪙 ${user['coins'] ?? 0}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: context.subTextColor),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: context.subTextColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _AdminField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: context.subTextColor,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(color: context.textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: context.subTextColor),
            prefixIcon: Icon(icon, color: context.subTextColor, size: 18),
            filled: true,
            fillColor: context.softBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
                textAlign: TextAlign.center),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 10, color: context.subTextColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: context.textColor,
        fontSize: 14,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int? rank;
  const _DataRow({required this.label, required this.value, required this.icon, this.rank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (rank != null) ...[
            SizedBox(
              width: 24,
              child: Text('#$rank',
                  style: GoogleFonts.outfit(
                      color: context.subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
          Icon(icon, color: context.subTextColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.outfit(color: context.textColor, fontSize: 13)),
          ),
          Text(value,
              style: GoogleFonts.outfit(
                  color: context.subTextColor, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Tab 3: Nội dung (Content Curation) ──────────────────────────────────────

class _ContentTab extends StatefulWidget {
  final CloudflareService svc;
  const _ContentTab({required this.svc});

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> with SingleTickerProviderStateMixin {
  late final TabController _subTabs;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _candidates = [];
  List<Map<String, dynamic>> _curated = [];
  bool _loadingCandidates = true;
  bool _loadingCurated = true;

  @override
  void initState() {
    super.initState();
    _subTabs = TabController(length: 2, vsync: this);
    _loadCandidates();
    _loadCurated();
  }

  @override
  void dispose() {
    _subTabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates({bool reset = true}) async {
    if (reset) setState(() => _loadingCandidates = true);
    try {
      final result = await widget.svc.adminGetContentCandidates(q: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() { _candidates = result; _loadingCandidates = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCandidates = false);
    }
  }

  Future<void> _loadCurated() async {
    setState(() => _loadingCurated = true);
    try {
      final result = await widget.svc.adminGetCuratedContent();
      if (!mounted) return;
      setState(() { _curated = result; _loadingCurated = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCurated = false);
    }
  }

  Future<void> _curate(Map<String, dynamic> card) async {
    try {
      await widget.svc.adminCurateContent(card['id']?.toString() ?? '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã chọn "${card['word'] ?? ''}" làm dữ liệu gốc'),
        backgroundColor: context.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
      _loadCandidates();
      _loadCurated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _removeCurated(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Xóa khỏi dữ liệu gốc?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
        content: Text('Bỏ "${item['word'] ?? ''}" khỏi danh sách đã chọn lọc.',
            style: GoogleFonts.outfit(color: context.subTextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy', style: GoogleFonts.outfit(color: context.subTextColor))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Xóa', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.svc.adminRemoveCurated(item['id']?.toString() ?? '');
      _loadCurated();
      _loadCandidates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabs,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.subTextColor,
          indicatorColor: context.primaryColor,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(text: 'Đề xuất (${_candidates.length})'),
            Tab(text: 'Đã chọn lọc (${_curated.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabs,
            children: [
              // ── Candidates ──
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.outfit(color: context.textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Tìm từ...',
                              hintStyle: GoogleFonts.outfit(color: context.subTextColor),
                              prefixIcon: Icon(Icons.search_rounded, color: context.subTextColor, size: 18),
                              filled: true,
                              fillColor: context.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _loadCandidates(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadCandidates,
                          icon: Icon(Icons.refresh_rounded, color: context.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Từ vựng chất lượng cao (ôn ≥ 3 lần, EF ≥ 2.0)',
                      style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor),
                    ),
                  ),
                  Expanded(
                    child: _loadingCandidates
                        ? const Center(child: CircularProgressIndicator())
                        : _candidates.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có đề xuất nào',
                                  style: GoogleFonts.outfit(color: context.subTextColor),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: _candidates.length,
                                itemBuilder: (ctx, i) {
                                  final c = _candidates[i];
                                  final alreadyCurated = c['already_curated'] == 1;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: alreadyCurated
                                            ? context.successGreen.withValues(alpha: 0.3)
                                            : context.borderColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    c['word']?.toString() ?? '',
                                                    style: GoogleFonts.outfit(
                                                        fontWeight: FontWeight.bold,
                                                        color: context.textColor,
                                                        fontSize: 14),
                                                  ),
                                                  if (alreadyCurated) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: context.successGreen.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text('✓ Dữ liệu gốc',
                                                          style: GoogleFonts.outfit(
                                                              fontSize: 9,
                                                              color: context.successGreen,
                                                              fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                c['meaning']?.toString() ?? '',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 12, color: context.subTextColor),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${c['user_code'] ?? ''} · Ôn ${c['repetitions'] ?? 0}x · EF ${(c['ease_factor'] as num?)?.toStringAsFixed(1) ?? '?'}',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 10, color: context.subTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!alreadyCurated)
                                          IconButton(
                                            onPressed: () => _curate(c),
                                            icon: Icon(Icons.add_circle_rounded,
                                                color: context.primaryColor, size: 28),
                                            tooltip: 'Chọn làm dữ liệu gốc',
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),

              // ── Curated ──
              _loadingCurated
                  ? const Center(child: CircularProgressIndicator())
                  : _curated.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.library_books_rounded,
                                  size: 48, color: context.subTextColor.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('Đưa từ vựng chất lượng cao vào đây',
                                  style: GoogleFonts.outfit(color: context.subTextColor)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _curated.length,
                          itemBuilder: (ctx, i) {
                            final item = _curated[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: context.successGreen.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.successGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('✓',
                                        style: GoogleFonts.outfit(
                                            color: context.successGreen, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['word']?.toString() ?? '',
                                            style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: context.textColor,
                                                fontSize: 14)),
                                        Text(item['meaning']?.toString() ?? '',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12, color: context.subTextColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        Text(
                                          '${item['category'] ?? 'general'} · Bởi ${item['promoted_by_name'] ?? 'Admin'}',
                                          style: GoogleFonts.outfit(
                                              fontSize: 10, color: context.subTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeCurated(item),
                                    icon: Icon(Icons.remove_circle_outline_rounded,
                                        color: AppTheme.errorRed.withValues(alpha: 0.7), size: 22),
                                    tooltip: 'Xóa khỏi dữ liệu gốc',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.errorRed.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message.contains('403') || message.contains('Forbidden')
                  ? 'Bạn không có quyền admin'
                  : message,
              style: GoogleFonts.outfit(color: context.subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
