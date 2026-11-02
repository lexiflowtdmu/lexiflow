import React, { useEffect, useState } from 'react';
import { ChevronDown, Brain } from 'lucide-react';
import { getFlashcards, type Flashcard } from '../lib/api';
import { Card } from './ui/Card';

interface Stats {
  unlearned: number;
  learning: number;
  mastered: number;
  accuracyRate: number;
}

function computeStats(cards: Flashcard[]): Stats {
  if (!Array.isArray(cards)) return { unlearned: 0, learning: 0, mastered: 0, accuracyRate: 0 };
  let unlearned = 0, learning = 0, mastered = 0;
  for (const c of cards) {
    if (c.repetitions === 0) unlearned++;
    else if (c.interval >= 21) mastered++;
    else learning++;
  }
  const total = cards.length || 1;
  return {
    unlearned,
    learning,
    mastered,
    accuracyRate: Math.round((mastered / total) * 100),
  };
}

export const MemoryStats: React.FC = () => {
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [loading, setLoading] = useState(true);
  const [periodKey, setPeriodKey] = useState<'7days' | '30days'>('7days');

  useEffect(() => {
    getFlashcards()
      .then((r) => setCards(Array.isArray(r.flashcards) ? r.flashcards : []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const stats = computeStats(cards);
  const totalWords = stats.unlearned + stats.learning + stats.mastered;

  const radius = 40;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (stats.accuracyRate / 100) * circumference;

  return (
    <Card className="p-5 font-sans">
      <div className="flex items-center justify-between mb-4 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
        <div className="flex items-center gap-2">
          <Brain className="w-4.5 h-4.5 text-[#4F46E5] dark:text-[#818CF8]" />
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
            Chỉ Số Trí Nhớ SM-2
          </h3>
        </div>
        <div className="relative">
          <select
            value={periodKey}
            onChange={(e) => setPeriodKey(e.target.value as '7days' | '30days')}
            aria-label="Khoảng thời gian"
            className="appearance-none bg-[#F8FAFC] dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] text-[#0F172A] dark:text-[#F8FAFC] text-[12px] font-bold font-mono py-1.5 pl-3 pr-8 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#4F46E5] cursor-pointer"
          >
            <option value="7days">7 Ngày Qua</option>
            <option value="30days">30 Ngày Qua</option>
          </select>
          <ChevronDown className="w-3.5 h-3.5 text-[#64748B] dark:text-[#94A3B8] absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
        </div>
      </div>

      {loading ? (
        <div className="h-32 rounded-xl bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
      ) : (
        <div className="flex items-center justify-between gap-4">
          <div className="relative w-32 h-32 flex items-center justify-center shrink-0">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
              <defs>
                <linearGradient id="donutGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#4F46E5" />
                  <stop offset="100%" stopColor="#059669" />
                </linearGradient>
              </defs>
              <circle cx="50" cy="50" r={radius} stroke="#EEF2FF" className="dark:stroke-[#1E293B]" strokeWidth="12" fill="transparent" />
              <circle
                cx="50" cy="50" r={radius}
                stroke="url(#donutGradient)"
                strokeWidth="12" fill="transparent"
                strokeDasharray={circumference}
                strokeDashoffset={strokeDashoffset}
                strokeLinecap="round"
                className="transition-all duration-700 ease-out"
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
              <span className="font-extrabold text-[22px] font-mono text-[#0F172A] dark:text-[#F8FAFC] leading-none">
                {stats.accuracyRate}%
              </span>
              <span className="text-[9.5px] font-bold text-[#64748B] dark:text-[#94A3B8] mt-1 max-w-[65px] leading-tight">
                Chỉ số ghi nhớ
              </span>
            </div>
          </div>

          <div className="flex flex-col gap-2.5 flex-1 pl-2">
            <div className="flex items-center justify-between text-[12px]">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#94A3B8]" />
                <span className="text-[#64748B] dark:text-[#CBD5E1] font-medium">Chưa thuộc</span>
              </div>
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#F8FAFC]">{stats.unlearned}</span>
            </div>
            <div className="flex items-center justify-between text-[12px]">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
                <span className="text-[#64748B] dark:text-[#CBD5E1] font-medium">Đang củng cố</span>
              </div>
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#F8FAFC]">{stats.learning}</span>
            </div>
            <div className="flex items-center justify-between text-[12px]">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#059669]" />
                <span className="text-[#64748B] dark:text-[#CBD5E1] font-medium">Đã thuộc dài hạn</span>
              </div>
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#F8FAFC]">{stats.mastered}</span>
            </div>
            <div className="border-t border-[#E2E8F0] dark:border-[#334155] pt-1.5 flex items-center justify-between text-[11px] text-[#64748B] dark:text-[#94A3B8] font-mono">
              <span>Tổng vốn từ</span>
              <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC]">{totalWords} từ</span>
            </div>
          </div>
        </div>
      )}
    </Card>
  );
};
