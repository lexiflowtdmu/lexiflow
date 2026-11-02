import React, { useEffect, useState } from 'react';
import { Flame, Target, Sparkles, Award } from 'lucide-react';
import { Card } from './ui/Card';
import { Badge } from './ui/Badge';
import { useAuth } from '../contexts/AuthContext';
import { getStreak } from '../lib/api';

export const LearningJourney: React.FC = () => {
  const { user } = useAuth();
  const [streakDays, setStreakDays] = useState(0);
  const [dailyGoal] = useState({ current: 0, target: 20 });

  const displayName = user?.displayName || user?.email?.split('@')[0] || 'Người dùng';
  const email = user?.email || '';
  const avatar = user?.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName)}&background=6366f1&color=fff&size=128`;

  useEffect(() => {
    getStreak()
      .then((r) => setStreakDays(r.streakDays || 0))
      .catch(() => {});
  }, []);

  const goalPercent = dailyGoal.target > 0
    ? Math.round((dailyGoal.current / dailyGoal.target) * 100)
    : 0;

  return (
    <Card className="p-5 font-sans">
      {/* Header */}
      <div className="flex items-center justify-between mb-4 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
        <div className="flex items-center gap-2">
          <Award className="w-4.5 h-4.5 text-[#4F46E5] dark:text-[#818CF8]" />
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
            Hồ Sơ & Tiến Độ SM-2
          </h3>
        </div>
        <Badge variant="indigo" size="sm" pill>Level 8</Badge>
      </div>

      {/* User Info Row */}
      <div className="flex items-center gap-3.5 mb-4 p-3 bg-[#F8FAFC] dark:bg-[#1E293B]/60 rounded-xl border border-[#E2E8F0] dark:border-[#334155]">
        <img
          src={avatar}
          alt={displayName}
          className="w-11 h-11 rounded-full object-cover ring-2 ring-[#4F46E5]/40 shrink-0"
        />
        <div className="flex flex-col min-w-0">
          <div className="flex items-center gap-1.5">
            <span className="font-extrabold text-[15px] text-[#0F172A] dark:text-[#F8FAFC] truncate tracking-tight">
              {displayName}
            </span>
            <Sparkles className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
          </div>
          <span className="text-[12px] text-[#64748B] dark:text-[#94A3B8] font-mono truncate">
            {email}
          </span>
        </div>
      </div>

      {/* 2 Metric Stats Boxes */}
      <div className="grid grid-cols-2 gap-3 mb-4">
        {/* Streak */}
        <div className="bg-amber-50/70 dark:bg-amber-500/10 border border-amber-200/80 dark:border-amber-500/20 p-3 rounded-xl flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-amber-500 text-white flex items-center justify-center shrink-0 shadow-xs">
            <Flame className="w-5 h-5 fill-current animate-bounce" />
          </div>
          <div className="flex flex-col">
            <span className="font-extrabold text-[18px] text-amber-900 dark:text-amber-300 leading-none font-mono">
              {streakDays}
            </span>
            <span className="text-[11px] font-bold text-amber-700 dark:text-amber-400 mt-0.5">
              ngày liên tiếp
            </span>
          </div>
        </div>

        {/* Daily Goal */}
        <div className="bg-emerald-50/70 dark:bg-emerald-500/10 border border-emerald-200/80 dark:border-emerald-500/20 p-3 rounded-xl flex flex-col justify-between">
          <div className="flex items-center justify-between mb-1">
            <span className="text-[11px] font-bold text-emerald-800 dark:text-emerald-300">
              Mục tiêu hôm nay
            </span>
            <Target className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div className="flex items-baseline justify-between mb-1.5">
            <span className="font-extrabold text-[15px] text-emerald-950 dark:text-emerald-200 font-mono leading-none">
              {dailyGoal.current}/{dailyGoal.target}
            </span>
            <span className="text-[11px] font-mono font-bold text-emerald-700 dark:text-emerald-400">{goalPercent}%</span>
          </div>
          <div className="w-full bg-emerald-200/60 dark:bg-emerald-500/30 h-1.5 rounded-full overflow-hidden">
            <div
              className="bg-[#059669] dark:bg-[#34D399] h-full rounded-full transition-all duration-500"
              style={{ width: `${goalPercent}%` }}
            />
          </div>
        </div>
      </div>

      {/* Quote */}
      <div className="bg-[#EEF2FF] dark:bg-[#4F46E5]/15 border border-[#C7D2FE]/60 dark:border-[#4F46E5]/30 p-3.5 rounded-xl">
        <p className="font-serif-craft italic text-[13.5px] text-[#4F46E5] dark:text-[#818CF8] leading-snug">
          "Kiên trì hôm nay, phiên bản tốt hơn ngày mai."
        </p>
        <span className="text-[10.5px] font-mono text-[#64748B] dark:text-[#94A3B8] mt-1 font-medium block">
          Kỷ luật 1% mỗi ngày tạo nên sức mạnh.
        </span>
      </div>
    </Card>
  );
};
