import React from 'react';
import {
  Home,
  BookOpen,
  Layers,
  Scan,
  HelpCircle,
  BarChart2,
  User,
  Settings,
  BookMarked,
  Sparkles,
  Flame,
  Calendar,
  Users,
  Trophy,
  Sprout,
  Swords
} from 'lucide-react';
import { mainNavItems, secondaryNavItems } from '../data';
import { Badge } from './ui/Badge';

interface SidebarProps {
  activeTab: string;
  onTabChange: (id: string) => void;
}

const iconMap: Record<string, React.ReactNode> = {
  Home: <Home className="w-[18px] h-[18px]" />,
  BookOpen: <BookOpen className="w-[18px] h-[18px]" />,
  Layers: <Layers className="w-[18px] h-[18px]" />,
  Scan: <Scan className="w-[18px] h-[18px]" />,
  HelpCircle: <HelpCircle className="w-[18px] h-[18px]" />,
  BarChart2: <BarChart2 className="w-[18px] h-[18px]" />,
  Users: <Users className="w-[18px] h-[18px]" />,
  Trophy: <Trophy className="w-[18px] h-[18px]" />,
  Calendar: <Calendar className="w-[18px] h-[18px]" />,
  User: <User className="w-[18px] h-[18px]" />,
  Settings: <Settings className="w-[18px] h-[18px]" />,
  Sprout: <Sprout className="w-[18px] h-[18px]" />,
  Swords: <Swords className="w-[18px] h-[18px]" />,
};

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange }) => {
  return (
    <aside
      aria-label="Thanh điều hướng chính"
      className="w-[240px] shrink-0 bg-[#F0F4FC] dark:bg-[#0B0F19] h-screen sticky top-0 flex flex-col justify-between p-4 border-r border-[#E2E8F5] dark:border-[#1E293B] select-none z-20 font-sans transition-colors duration-200"
    >
      {/* Top Brand Section */}
      <div className="flex flex-col gap-6">
        <div className="flex items-center gap-3 px-2 pt-2 cursor-pointer" onClick={() => onTabChange('home')}>
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-[#4F46E5] to-[#7C3AED] flex items-center justify-center text-white shadow-md shadow-[#4F46E5]/25 shrink-0 ring-2 ring-white/40 dark:ring-white/10">
            <BookMarked className="w-5 h-5 stroke-[2.2]" />
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5">
              <span className="font-extrabold text-[20px] text-[#0F172A] dark:text-[#F8FAFC] leading-tight tracking-tight">
                LexiFlow
              </span>
              <Badge variant="indigo" size="sm" pill>v2.0</Badge>
            </div>
            <span className="text-[11px] font-medium text-[#64748B] dark:text-[#94A3B8] tracking-tight">
              Oxford Authority Studio
            </span>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="flex flex-col gap-1" role="navigation" aria-label="Danh mục ứng dụng">
          <div className="px-3 pb-1.5 text-[10px] font-mono font-bold uppercase tracking-widest text-[#94A3B8]">
            Học & Tra Cứu
          </div>
          {mainNavItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onTabChange(item.id)}
                aria-current={isActive ? 'page' : undefined}
                className={`flex items-center gap-3 h-[42px] px-3.5 rounded-xl text-[13.5px] font-semibold transition-all duration-200 text-left group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] focus-visible:ring-offset-2 ${
                  isActive
                    ? 'bg-white dark:bg-[#1E293B] text-[#4F46E5] dark:text-[#818CF8] shadow-sm ring-1 ring-[#E2E8F5] dark:ring-[#334155]'
                    : 'text-[#334155] dark:text-[#CBD5E1] hover:bg-white/60 dark:hover:bg-[#1E293B]/60 hover:text-[#4F46E5] dark:hover:text-[#818CF8]'
                }`}
              >
                <span
                  className={`transition-colors duration-200 ${
                    isActive
                      ? 'text-[#4F46E5] dark:text-[#818CF8]'
                      : 'text-[#64748B] dark:text-[#94A3B8] group-hover:text-[#4F46E5] dark:group-hover:text-[#818CF8]'
                  }`}
                >
                  {iconMap[item.iconName]}
                </span>
                <span className="flex-1 tracking-tight">{item.label}</span>
                {isActive && (
                  <span className="w-1.5 h-1.5 rounded-full bg-[#4F46E5] dark:bg-[#818CF8] shadow-xs animate-pulse-glow" />
                )}
              </button>
            );
          })}

          <div className="my-2.5 border-t border-[#E2E8F5] dark:border-[#1E293B]" />

          <div className="px-3 pb-1.5 text-[10px] font-mono font-bold uppercase tracking-widest text-[#94A3B8]">
            Thống Kê & Cá Nhân
          </div>
          {secondaryNavItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onTabChange(item.id)}
                aria-current={isActive ? 'page' : undefined}
                className={`flex items-center gap-3 h-[42px] px-3.5 rounded-xl text-[13.5px] font-semibold transition-all duration-200 text-left group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] focus-visible:ring-offset-2 ${
                  isActive
                    ? 'bg-white dark:bg-[#1E293B] text-[#4F46E5] dark:text-[#818CF8] shadow-sm ring-1 ring-[#E2E8F5] dark:ring-[#334155]'
                    : 'text-[#334155] dark:text-[#CBD5E1] hover:bg-white/60 dark:hover:bg-[#1E293B]/60 hover:text-[#4F46E5] dark:hover:text-[#818CF8]'
                }`}
              >
                <span
                  className={`transition-colors duration-200 ${
                    isActive
                      ? 'text-[#4F46E5] dark:text-[#818CF8]'
                      : 'text-[#64748B] dark:text-[#94A3B8] group-hover:text-[#4F46E5] dark:group-hover:text-[#818CF8]'
                  }`}
                >
                  {iconMap[item.iconName]}
                </span>
                <span className="flex-1 tracking-tight">{item.label}</span>
                {isActive && (
                  <span className="w-1.5 h-1.5 rounded-full bg-[#4F46E5] dark:bg-[#818CF8] shadow-xs animate-pulse-glow" />
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Bottom Streak Card */}
      <div className="flex flex-col items-center gap-3 pt-3 pb-1 px-1 border-t border-[#E2E8F5] dark:border-[#1E293B] mt-auto">
        <div className="w-full bg-white dark:bg-[#131B2E] rounded-2xl p-3.5 border border-[#E2E8F5] dark:border-[#1E293B] flex flex-col gap-2.5 shadow-sm relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-bl from-[#4F46E5]/10 via-transparent to-transparent rounded-bl-full pointer-events-none" />
          
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5 px-2 py-1 rounded-lg bg-amber-50 dark:bg-amber-500/20 text-amber-700 dark:text-amber-400 text-[11px] font-semibold ring-1 ring-amber-200/60 dark:ring-amber-500/30">
              <Flame className="w-3.5 h-3.5 text-amber-500 fill-amber-500 animate-bounce" />
              <span>Chuỗi 12 ngày</span>
            </div>
            <Sparkles className="w-4 h-4 text-[#4F46E5] dark:text-[#818CF8]" />
          </div>

          <p className="font-serif-craft italic text-[13px] text-[#0F172A] dark:text-[#E2E8F0] leading-snug">
            "Every new word learned is a door unlocked into a bigger universe."
          </p>
          <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] font-medium">
            Học tập kiên trì cùng SM-2 Algorithm.
          </span>
        </div>

        <span className="text-[10.5px] font-mono text-[#94A3B8] dark:text-[#64748B] tracking-tight text-center">
          LexiFlow Engine · Design System v2.0
        </span>
      </div>
    </aside>
  );
};
