import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lexiflow/core/theme/app_theme.dart';
import 'package:lexiflow/core/theme/theme_extension.dart';
import '../../core/utils/page_transitions.dart';
import '../../services/cloudflare_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/daily_words.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/search_bloc.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'bookmarks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CloudflareService get _cloudflareService => context.read<CloudflareService>();
  bool _loadingStreak = true;
  int _streak = 0;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _reminderEnabled = true;

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        final dailyWord = DailyWords.getWordOfTheDay();
        await NotificationService().scheduleDailyNotification(
          dailyWord['word']!,
          dailyWord['meaning']!,
          hour: picked.hour,
          minute: picked.minute,
          force: true,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật giờ nhắc nhở thành ${picked.format(context)} hàng ngày!'),
              backgroundColor: context.primaryColor,
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStreakInfo();
  }

  Future<void> _loadStreakInfo() async {
    setState(() => _loadingStreak = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        // Fetch streak details from Cloudflare D1
        final streak = await _cloudflareService.getStudyStreak(uid);
        if (mounted) {
          setState(() {
            _streak = streak;
            _loadingStreak = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingStreak = false);
      }
    } else {
      if (mounted) setState(() => _loadingStreak = false);
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử tra từ'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử tra từ không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: TextStyle(color: context.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _cloudflareService.clearAllHistory(uid);
      if (mounted) {
        context.read<SearchBloc>().add(HistoryLoadRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ lịch sử tra từ')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Đăng xuất', style: TextStyle(color: context.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<AuthBloc>().add(AuthLogoutRequested());
    Navigator.pushAndRemoveUntil(
      context,
      SlidePageRoute(page: const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Cài đặt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // ── Section: Giao diện ──
            _buildSectionHeader('Giao diện', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, settingsState) {
                  return SwitchListTile(
                    secondary: Icon(
                      context.read<SettingsCubit>().themeIcon,
                      color: context.primaryColor,
                    ),
                    title: Text(
                      'Chế độ giao diện',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      context.read<SettingsCubit>().themeLabel,
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                    value: settingsState.themeMode != AppThemeMode.light,
                    onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: Học tập ──
            _buildSectionHeader('Học tập', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  // Auto-play Audio Switch
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, settingsState) {
                      return SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.softBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.volume_up_rounded, color: context.primaryColor, size: 24),
                        ),
                        title: Text(
                          'Tự động phát âm khi lật thẻ',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                        ),
                        subtitle: Text(
                          'Tự động phát âm thanh khi lật mặt sau thẻ từ vựng',
                          style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                        ),
                        value: settingsState.autoPlayAudio,
                        onChanged: (_) => context.read<SettingsCubit>().toggleAutoPlayAudio(),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 72, color: context.borderColor),
                  // Streak Info
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_fire_department_rounded, color: AppTheme.accentOrange, size: 24),
                    ),
                    title: Text(
                      'Chuỗi học tập',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: _loadingStreak
                        ? Text('Đang tải...', style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13))
                        : Text(
                            _streak > 0 ? '$_streak ngày liên tiếp' : 'Bắt đầu học ngay!',
                            style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                          ),
                    trailing: _streak > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_streak 🔥',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: Dữ liệu ──
            _buildSectionHeader('Dữ liệu', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  // Bookmarks
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bookmark_rounded, color: context.primaryColor, size: 24),
                    ),
                    title: Text(
                      'Từ vựng đã lưu',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      'Xem danh sách từ vựng đã bookmark',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(page: const BookmarksScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 72, color: context.borderColor),
                  // Clear History
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_sweep_rounded, color: context.errorRed, size: 24),
                    ),
                    title: Text(
                      'Xóa lịch sử tra từ',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      'Xóa tất cả lịch sử tra cứu từ điển',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                    onTap: _clearAllHistory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: Thông báo ──
            _buildSectionHeader('Thông báo nhắc nhở', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_active_rounded, color: context.primaryColor, size: 24),
                    ),
                    title: Text(
                      'Bật thông báo mỗi ngày',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      _reminderEnabled ? 'Đang bật nhắc học từ vựng' : 'Đã tắt nhắc nhở',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                    value: _reminderEnabled,
                    onChanged: (val) async {
                      setState(() => _reminderEnabled = val);
                      if (val) {
                        final dailyWord = DailyWords.getWordOfTheDay();
                        await NotificationService().scheduleDailyNotification(
                          dailyWord['word']!,
                          dailyWord['meaning']!,
                          hour: _reminderTime.hour,
                          minute: _reminderTime.minute,
                          force: true,
                        );
                      } else {
                        await NotificationService().cancelDailyNotification();
                      }
                    },
                  ),
                  if (_reminderEnabled) ...[
                    Divider(height: 1, indent: 72, color: context.borderColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.softBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.access_time_rounded, color: context.primaryColor, size: 24),
                      ),
                      title: Text(
                        'Thời gian nhắc nhở',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                      ),
                      subtitle: Text(
                        'Nhắc lúc ${_reminderTime.format(context)}',
                        style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Thay đổi'),
                        onPressed: _pickReminderTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: Tài khoản ──
            _buildSectionHeader('Tài khoản', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  // Admin Panel — only shown to admin users (checked client-side for UX;
                  // server enforces 403 for non-admins regardless)
                  if (FirebaseAuth.instance.currentUser != null) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.admin_panel_settings_rounded,
                            color: context.primaryColor, size: 24),
                      ),
                      title: Text(
                        'Admin Panel',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600, color: context.textColor),
                      ),
                      subtitle: Text(
                        'Quản lý hệ thống, người dùng và kiểm duyệt',
                        style: GoogleFonts.outfit(
                            color: context.subTextColor, fontSize: 13),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: context.subTextColor),
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: const AdminScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 72, color: context.borderColor),
                  ],
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.logout_rounded, color: context.errorRed, size: 24),
                    ),
                    title: Text(
                      'Đăng xuất',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      'Đăng xuất khỏi tài khoản hiện tại',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: Về ứng dụng ──
            _buildSectionHeader('Về ứng dụng', context.subTextColor),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: context.primaryColor, size: 24),
                    ),
                    title: Text(
                      'LexiFlow',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textColor, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Phiên bản 1.0.0+1',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 13),
                    ),
                  ),
                  Divider(height: 1, indent: 72, color: context.borderColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.softBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.info_outline_rounded, color: context.primaryColor, size: 24),
                    ),
                    title: Text(
                      'Công nghệ',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      'Flutter • Firebase • SM-2 Algorithm • Google ML Kit • Oxford Dictionary API',
                      style: GoogleFonts.outfit(color: context.subTextColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

