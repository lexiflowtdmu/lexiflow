import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../core/utils/page_transitions.dart';
import 'word_battle_screen.dart';

class FriendUser {
  final String uid;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String userCode; // e.g. #LEXI-8492
  final int isPublicProfile;
  final int level;
  final int xp;
  final int streakDays;
  final int wordsLearnedToday;
  final List<String> badges;
  final String relationshipStatus; // 'none', 'pending_sent', 'pending_received', 'accepted'

  FriendUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.userCode,
    this.isPublicProfile = 1,
    this.level = 1,
    this.xp = 0,
    this.streakDays = 0,
    this.wordsLearnedToday = 0,
    this.badges = const [],
    this.relationshipStatus = 'none',
  });
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final String _selfUserCode = '#LEXI-9821';

  final List<FriendUser> _friends = [
    FriendUser(
      uid: 'user-friend-1',
      email: 'hoangnam@gmail.com',
      displayName: 'Hoàng Nam',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=250',
      userCode: '#LEXI-8492',
      isPublicProfile: 1,
      level: 7,
      xp: 2850,
      streakDays: 15,
      wordsLearnedToday: 24,
      badges: ['Bậc Thầy C2 Oxford', 'Thần Tốc Từ Vựng'],
      relationshipStatus: 'accepted',
    ),
    FriendUser(
      uid: 'user-friend-2',
      email: 'minhhoa@gmail.com',
      displayName: 'Lê Minh Hoa',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=250',
      userCode: '#LEXI-3910',
      isPublicProfile: 0,
      level: 5,
      xp: 1420,
      streakDays: 8,
      wordsLearnedToday: 12,
      badges: ['Chiến Binh SM-2'],
      relationshipStatus: 'accepted',
    ),
  ];

  final List<FriendUser> _pendingRequests = [
    FriendUser(
      uid: 'user-req-1',
      email: 'phuonganh@gmail.com',
      displayName: 'Vũ Phương Anh',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
      userCode: '#LEXI-1092',
      isPublicProfile: 1,
      level: 4,
      xp: 980,
      streakDays: 5,
      wordsLearnedToday: 15,
      badges: ['Người Mới Năng Nổ'],
      relationshipStatus: 'pending_received',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copyUserCode() {
    Clipboard.setData(ClipboardData(text: _selfUserCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép Mã ID công khai: $_selfUserCode'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.successGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showUserProfileDialog(FriendUser user) {
    final bool isFriend = user.relationshipStatus == 'accepted';
    final bool canView = user.isPublicProfile == 1 || isFriend;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${user.userCode} · Lv.${user.level}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            if (!canView)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.softBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppTheme.accentOrange),
                    const SizedBox(height: 6),
                    Text(
                      'Hồ sơ riêng tư',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
                    ),
                    Text(
                      'Người dùng này thiết lập chỉ bạn bè mới xem được thông tin tiến trình.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, color: context.subTextColor),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent),
                          Text('${user.streakDays} Ngày', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
                          Text('Streak', style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor)),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.stars_rounded, color: context.primaryColor),
                          Text('+${user.xp} XP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.primaryColor)),
                          Text('Kinh nghiệm', style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (user.badges.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.badges
                          .map((b) => Chip(
                                label: Text(b, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                                backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.12),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Đóng'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bạn Bè & Kết Nối',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.subTextColor,
          indicatorColor: context.primaryColor,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Bạn bè (${_friends.length})'),
            Tab(text: 'Lời mời (${_pendingRequests.length})'),
            const Tab(text: 'Tìm bạn'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Self ID Banner Box
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã ID công khai của bạn', style: GoogleFonts.outfit(fontSize: 11, color: context.subTextColor)),
                    Text(_selfUserCode, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryColor)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _copyUserCode,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao chép'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: FRIENDS LIST
                _friends.isEmpty
                    ? Center(child: Text('Chưa có bạn bè nào', style: GoogleFonts.outfit(color: context.subTextColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final f = _friends[index];
                          return Card(
                            color: context.cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(backgroundImage: NetworkImage(f.avatarUrl)),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: context.successGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: context.cardColor, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(f.displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
                              subtitle: Text('${f.userCode} · 🔥 ${f.streakDays}d streak · 🟢 Online', style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sports_esports_rounded, color: Colors.amber),
                                    tooltip: 'Thách đấu 1v1',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        SlidePageRoute(page: const WordBattleScreen(mode: '1v1')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.visibility_outlined, color: context.primaryColor),
                                    onPressed: () => _showUserProfileDialog(f),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // TAB 2: PENDING REQUESTS
                _pendingRequests.isEmpty
                    ? Center(child: Text('Không có lời mời nào đang chờ', style: GoogleFonts.outfit(color: context.subTextColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pendingRequests.length,
                        itemBuilder: (context, index) {
                          final req = _pendingRequests[index];
                          return Card(
                            color: context.cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(backgroundImage: NetworkImage(req.avatarUrl)),
                              title: Text(req.displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
                              subtitle: Text(req.userCode, style: GoogleFonts.outfit(color: context.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check_circle_rounded, color: context.successGreen),
                                    onPressed: () {
                                      setState(() {
                                        _pendingRequests.removeAt(index);
                                        _friends.add(req);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã kết bạn với ${req.displayName}')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_rounded, color: context.errorRed),
                                    onPressed: () {
                                      setState(() {
                                        _pendingRequests.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // TAB 3: SEARCH USER
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.outfit(color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Nhập #LEXI-XXXX hoặc tên...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã gửi lời mời kết bạn thành công!')),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: context.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250')),
                          title: Text('Nguyễn Thanh Thảo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
                          subtitle: Text('#LEXI-4491 · Lv.6', style: GoogleFonts.outfit(color: context.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
                              );
                            },
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: const Text('Kết bạn'),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
