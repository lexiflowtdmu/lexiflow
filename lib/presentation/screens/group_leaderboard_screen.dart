import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';

class GroupMemberItem {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final String userCode;
  final int xp;
  final int streakDays;
  final String role; // 'owner' | 'member'
  final bool hasLearnedToday;

  GroupMemberItem({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.userCode,
    required this.xp,
    required this.streakDays,
    this.role = 'member',
    this.hasLearnedToday = true,
  });
}

class GroupItem {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final List<GroupMemberItem> members;

  GroupItem({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.members,
  });
}

class GroupLeaderboardScreen extends StatefulWidget {
  const GroupLeaderboardScreen({super.key});

  @override
  State<GroupLeaderboardScreen> createState() => _GroupLeaderboardScreenState();
}

class _GroupLeaderboardScreenState extends State<GroupLeaderboardScreen> {
  final List<GroupItem> _groups = [
    GroupItem(
      id: 'grp-1',
      name: 'Nhóm Luyện Thi IELTS 7.5+ 🎯',
      description: 'Nhóm 10 bạn cùng lớp quyết tâm chinh phục 8.0 IELTS Reading & Vocabulary.',
      inviteCode: 'GRP-8492',
      members: [
        GroupMemberItem(
          uid: 'm-1',
          displayName: 'Trần Trung Đức',
          avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=250',
          userCode: '#LEXI-7721',
          xp: 5400,
          streakDays: 32,
          role: 'owner',
          hasLearnedToday: true,
        ),
        GroupMemberItem(
          uid: 'm-2',
          displayName: 'Hoàng Nam',
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=250',
          userCode: '#LEXI-8492',
          xp: 2850,
          streakDays: 15,
          role: 'member',
          hasLearnedToday: true,
        ),
        GroupMemberItem(
          uid: 'm-3',
          displayName: 'Lê Minh Hoa',
          avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=250',
          userCode: '#LEXI-3910',
          xp: 1420,
          streakDays: 8,
          role: 'member',
          hasLearnedToday: false,
        ),
      ],
    ),
  ];

  int _selectedGroupIdx = 0;
  bool _isWeekly = true;

  void _selectGroup(int index) {
    setState(() {
      _selectedGroupIdx = index;
    });
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã mời nhóm: $code'),
        backgroundColor: context.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendCheer(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💖 Bạn vừa thả tim chúc mừng $name!'),
        backgroundColor: AppTheme.accentPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendNudge(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 Đã gửi thông báo nhắc học đến $name!'),
        backgroundColor: AppTheme.accentOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gia nhập nhóm học tập', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Nhập mã GRP-XXXX',
            labelText: 'Mã mời nhóm',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã gia nhập nhóm thành công với mã $code!')),
                );
              }
            },
            child: const Text('Gia nhập'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final currentGroup = _groups[_selectedGroupIdx];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'BXH Nhóm Học Tập',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Gia nhập nhóm',
            onPressed: _showJoinGroupDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Group Selector Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _groups.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final g = _groups[idx];
                  final isSel = idx == _selectedGroupIdx;
                  return ChoiceChip(
                    label: Text(g.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isSel ? Colors.white : context.textColor)),
                    selected: isSel,
                    selectedColor: context.primaryColor,
                    backgroundColor: context.cardColor,
                    onSelected: (_) => _selectGroup(idx),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Group Title & Invite Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentGroup.name,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor),
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyInviteCode(currentGroup.inviteCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                currentGroup.inviteCode,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryColor),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.copy_rounded, size: 14, color: context.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentGroup.description,
                    style: GoogleFonts.outfit(fontSize: 13, color: context.subTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Members Leaderboard List & Weekly Toggle Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bảng Xếp Hạng 🏆',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor),
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Tuần này', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _isWeekly,
                      selectedColor: context.primaryColor,
                      labelStyle: TextStyle(color: _isWeekly ? Colors.white : context.textColor),
                      backgroundColor: context.cardColor,
                      onSelected: (_) => setState(() => _isWeekly = true),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text('Tổng XP', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: !_isWeekly,
                      selectedColor: context.primaryColor,
                      labelStyle: TextStyle(color: !_isWeekly ? Colors.white : context.textColor),
                      backgroundColor: context.cardColor,
                      onSelected: (_) => setState(() => _isWeekly = false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentGroup.members.length,
              itemBuilder: (context, index) {
                final member = currentGroup.members[index];
                String rankBadge = '#${index + 1}';
                if (index == 0) rankBadge = '🥇';
                if (index == 1) rankBadge = '🥈';
                if (index == 2) rankBadge = '🥉';

                final isOnline = index % 2 == 0;

                return Card(
                  color: context.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Text(rankBadge, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Stack(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(member.avatarUrl)),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isOnline ? context.successGreen : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.cardColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.displayName,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOnline ? '• Online' : '• 10m',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOnline ? context.successGreen : context.subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _isWeekly ? '🔥 ${member.streakDays}d · +${member.xp} XP tuần này' : '🔥 ${member.streakDays}d · +${member.xp} XP tổng',
                                style: GoogleFonts.outfit(fontSize: 12, color: context.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
                          tooltip: 'Khen',
                          onPressed: () => _sendCheer(member.displayName),
                        ),
                        if (!member.hasLearnedToday)
                          IconButton(
                            icon: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 20),
                            tooltip: 'Nhắc học',
                            onPressed: () => _sendNudge(member.displayName),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
