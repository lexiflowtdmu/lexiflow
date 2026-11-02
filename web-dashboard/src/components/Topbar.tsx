import React, { useEffect, useRef, useState } from 'react';
import { Search, Bell, Sparkles, Flame } from 'lucide-react';
import type { UserProfile } from '../data';
import { Badge } from './ui/Badge';
import { getStreak } from '../lib/api';

interface TopbarProps {
  user: UserProfile;
  onOpenSearch: () => void;
  onOpenNotifications: () => void;
  hasUnread: boolean;
  onProfileClick: () => void;
}

export const Topbar: React.FC<TopbarProps> = ({
  user,
  onOpenSearch,
  onOpenNotifications,
  hasUnread,
  onProfileClick
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const [streakDays, setStreakDays] = useState(0);

  useEffect(() => {
    getStreak()
      .then((r) => setStreakDays(r.streakDays || 0))
      .catch(() => {});
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        onOpenSearch();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onOpenSearch]);

  return (
    <header className="h-[72px] px-6 md:px-8 bg-[#F8FAFC]/90 dark:bg-[#0B0F19]/90 sticky top-0 z-20 flex items-center justify-between gap-6 border-b border-[#E2E8F0] dark:border-[#1E293B] backdrop-blur-md font-sans transition-colors duration-200">
      {/* Search Input Bar */}
      <div 
        onClick={onOpenSearch}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => e.key === 'Enter' && onOpenSearch()}
        aria-label="Tìm kiếm từ vựng (Nhấn Ctrl + K)"
        className="relative flex-1 max-w-[580px] cursor-pointer group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] focus-visible:ring-offset-2 rounded-full"
      >
        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B] dark:text-[#94A3B8] group-hover:text-[#4F46E5] dark:group-hover:text-[#818CF8] transition-colors">
          <Search className="w-4 h-4 stroke-[2.2]" />
        </div>
        <input
          ref={inputRef}
          type="text"
          readOnly
          tabIndex={-1}
          placeholder="Tra cứu từ vựng, phiên âm IPA, ví dụ Oxford (Ctrl + K)..."
          className="w-full h-11 pl-10 pr-24 bg-white dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] rounded-full text-[13.5px] text-[#0F172A] dark:text-[#F8FAFC] placeholder-[#94A3B8] cursor-pointer focus:outline-none group-hover:border-[#4F46E5]/50 shadow-sm transition-all"
        />
        <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
          <kbd className="inline-flex items-center gap-1 px-2.5 py-0.5 text-[11px] font-mono font-semibold text-[#4F46E5] dark:text-[#818CF8] bg-[#EEF2FF] dark:bg-[#4F46E5]/20 border border-[#C7D2FE] dark:border-[#4F46E5]/30 rounded-lg shadow-xs">
            ⌘ K
          </kbd>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3.5">
        {/* Streak Pill */}
        <div className="hidden sm:flex items-center gap-1.5">
          <Badge variant="amber" pill size="md">
            <Flame className="w-4 h-4 text-amber-500 fill-amber-500 animate-bounce" />
            <span>{streakDays} Ngày liên tục</span>
          </Badge>
        </div>

        {/* Notification Bell */}
        <button
          onClick={onOpenNotifications}
          aria-label="Xem thông báo"
          className="relative p-2.5 rounded-full bg-white dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] text-[#64748B] dark:text-[#CBD5E1] hover:bg-[#F1F5F9] dark:hover:bg-[#334155] hover:text-[#4F46E5] dark:hover:text-[#818CF8] transition-all shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
        >
          <Bell className="w-4.5 h-4.5 stroke-[2]" />
          {hasUnread && (
            <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-[#EF4444] rounded-full ring-2 ring-white dark:ring-[#1E293B] animate-pulse" />
          )}
        </button>

        {/* User Profile Pill */}
        <button
          onClick={onProfileClick}
          aria-label="Trang cá nhân của học viên"
          className="flex items-center gap-3 bg-white dark:bg-[#1E293B] pl-2 pr-3.5 py-1.5 rounded-full border border-[#E2E8F0] dark:border-[#334155] shadow-sm hover:border-[#818CF8] transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] shrink-0"
        >
          <img
            src={user.avatar}
            alt={user.name}
            className="w-8 h-8 rounded-full object-cover ring-2 ring-[#4F46E5]/40 shrink-0"
          />
          <div className="flex flex-col text-left whitespace-nowrap">
            <div className="flex items-center gap-1">
              <span className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC] leading-tight">
                {user.name}
              </span>
              <Sparkles className="w-3 h-3 text-[#4F46E5] dark:text-[#818CF8] shrink-0" />
            </div>
            <span className="text-[11px] font-mono text-[#059669] dark:text-[#34D399] font-medium flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-[#059669] dark:bg-[#34D399] animate-pulse shrink-0" />
              Lv.8 · 1,420 XP
            </span>
          </div>
        </button>
      </div>
    </header>
  );
};
