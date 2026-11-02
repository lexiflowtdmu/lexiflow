import React, { useState, useEffect } from 'react';
import { BarChart2, TrendingUp, Flame, BookOpen } from 'lucide-react';
import { getFlashcards, getStreak, getHistory, type Flashcard, type HistoryItem } from '../../lib/api';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';

export const StatsView: React.FC = () => {
  const [timePeriod, setTimePeriod] = useState<'day' | 'week' | 'month' | 'year'>('week');
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [streakDays, setStreakDays] = useState(0);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      getFlashcards().then((r) => setCards(Array.isArray(r.flashcards) ? r.flashcards : [])).catch(() => {}),
      getStreak().then((r) => setStreakDays(r.streakDays || 0)).catch(() => {}),
      getHistory().then((r) => setHistory(Array.isArray(r.history) ? r.history : [])).catch(() => {}),
    ]).finally(() => setLoading(false));
  }, []);

  const mastered = cards.filter((c) => c.interval >= 21).length;
  const learning = cards.filter((c) => c.repetitions > 0 && c.interval < 21).length;
  const unlearned = cards.filter((c) => c.repetitions === 0).length;
  const total = cards.length;
  const masteryRate = total > 0 ? Math.round((mastered / total) * 100) : 0;

  // Group history by day of week for bar chart
  const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - now.getDay() + 1);

  const barCounts = dayLabels.map((_, idx) => {
    const day = new Date(weekStart);
    day.setDate(weekStart.getDate() + idx);
    return history.filter((h) => {
      const d = new Date(h.searchedAt);
      return d.toDateString() === day.toDateString();
    }).length;
  });
  const maxBar = Math.max(...barCounts, 1);
  const avgPerDay = barCounts.reduce((a, b) => a + b, 0) / 7;

  return (
    <div className="max-w-[1040px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
      <Card className="p-5 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3.5">
          <div className="w-11 h-11 rounded-2xl bg-[#4F46E5] text-white flex items-center justify-center shadow-md shadow-[#4F46E5]/25">
            <BarChart2 className="w-6 h-6 stroke-[2.2]" />
          </div>
          <div>
            <h2 className="text-xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">Thống Kê Học Tập & Trí Nhớ SM-2</h2>
            <p className="text-[13px] text-[#64748B] dark:text-[#94A3B8] font-medium">Theo dõi tiến độ, hiệu suất và đường cong lãng quên của bạn.</p>
          </div>
        </div>
        <div className="flex items-center gap-1 bg-[#F8FAFC] dark:bg-[#1E293B] p-1 rounded-xl border border-[#E2E8F0] dark:border-[#334155]">
          {(['day', 'week', 'month', 'year'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTimePeriod(t)}
              className={`px-4 py-1.5 rounded-lg text-[12.5px] font-bold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
                timePeriod === t ? 'bg-white dark:bg-[#0B0F19] text-[#4F46E5] dark:text-[#818CF8] shadow-xs' : 'text-[#64748B] dark:text-[#94A3B8] hover:text-[#0F172A]'
              }`}
            >
              {t === 'day' ? 'Ngày' : t === 'week' ? 'Tuần' : t === 'month' ? 'Tháng' : 'Năm'}
            </button>
          ))}
        </div>
      </Card>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <Card className="p-6 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[13px] font-bold text-[#64748B] dark:text-[#94A3B8]">Tổng số từ đã nạp</span>
            <div className="flex items-baseline gap-2">
              {loading ? (
                <div className="w-16 h-10 rounded bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
              ) : (
                <>
                  <span className="text-4xl font-extrabold font-mono text-[#0F172A] dark:text-[#F8FAFC] leading-none">{total}</span>
                  <span className="text-[12px] font-mono font-bold text-[#059669] dark:text-[#34D399] flex items-center gap-0.5">
                    <TrendingUp className="w-3.5 h-3.5" /> +{history.filter((h) => {
                      const d = new Date(h.searchedAt);
                      const diff = (Date.now() - d.getTime()) / 86400000;
                      return diff <= 7;
                    }).length} tuần
                  </span>
                </>
              )}
            </div>
            <span className="text-[11.5px] font-mono text-[#94A3B8] dark:text-[#64748B] mt-1">{mastered} từ đã thuộc dài hạn</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-[#EEF2FF] dark:bg-[#4F46E5]/20 text-[#4F46E5] dark:text-[#818CF8] flex items-center justify-center shadow-xs">
            <BookOpen className="w-6 h-6 stroke-[2.2]" />
          </div>
        </Card>

        <Card className="p-6 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[13px] font-bold text-[#64748B] dark:text-[#94A3B8]">Chuỗi học tập</span>
            <div className="flex items-baseline gap-2">
              {loading ? (
                <div className="w-24 h-10 rounded bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
              ) : (
                <span className="text-4xl font-extrabold font-mono text-amber-900 dark:text-amber-400 leading-none">{streakDays} ngày</span>
              )}
            </div>
            <span className="text-[11.5px] font-mono text-[#94A3B8] dark:text-[#64748B] mt-1">Duy trì chuỗi học mỗi ngày</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-amber-50 dark:bg-amber-500/20 text-amber-500 flex items-center justify-center shadow-xs">
            <Flame className="w-6 h-6 fill-current animate-bounce" />
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        <Card className="lg:col-span-5 p-6 flex flex-col justify-between">
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] mb-4 pb-2 border-b border-[#E2E8F0] dark:border-[#334155] tracking-tight">Tỷ Lệ Nhớ Tốt SM-2</h3>
          <div className="flex items-center justify-center my-4">
            <div className="relative w-40 h-40 flex items-center justify-center">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                <circle cx="50" cy="50" r="40" stroke="#EEF2FF" className="dark:stroke-[#334155]" strokeWidth="12" fill="transparent" />
                <circle
                  cx="50" cy="50" r="40"
                  stroke="#4F46E5" strokeWidth="12" fill="transparent"
                  strokeDasharray={2 * Math.PI * 40}
                  strokeDashoffset={2 * Math.PI * 40 * (1 - masteryRate / 100)}
                  strokeLinecap="round"
                  className="transition-all duration-700"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                {loading ? (
                  <div className="w-12 h-8 rounded bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
                ) : (
                  <>
                    <span className="text-3xl font-extrabold font-mono text-[#0F172A] dark:text-[#F8FAFC] leading-none">{masteryRate}%</span>
                    <span className="text-[10px] font-mono text-[#64748B] dark:text-[#94A3B8] mt-1 font-bold">Chỉ số thuộc lòng</span>
                  </>
                )}
              </div>
            </div>
          </div>
          <div className="flex flex-col gap-2 pt-4 border-t border-[#E2E8F0] dark:border-[#334155]">
            <div className="flex items-center justify-between text-[12.5px] font-mono">
              <span className="text-[#94A3B8] font-bold">Chưa học</span>
              <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC]">{unlearned} từ</span>
            </div>
            <div className="flex items-center justify-between text-[12.5px] font-mono">
              <span className="text-amber-700 dark:text-amber-400 font-bold">Đang củng cố</span>
              <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC]">{learning} từ</span>
            </div>
            <div className="flex items-center justify-between text-[12.5px] font-mono">
              <span className="text-[#059669] dark:text-[#34D399] font-bold">Đã thuộc dài hạn</span>
              <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC]">{mastered} từ</span>
            </div>
          </div>
        </Card>

        <Card className="lg:col-span-7 p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between mb-4 pb-2 border-b border-[#E2E8F0] dark:border-[#334155]">
            <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">Vốn Từ Nạp Theo Ngày</h3>
            <Badge variant="indigo" size="sm">Tuần này</Badge>
          </div>
          <div className="h-[220px] flex items-end justify-between gap-3 pt-8 pb-4 px-2 border-b border-[#E2E8F0] dark:border-[#334155]">
            {dayLabels.map((label, i) => (
              <div key={label} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                <span className="text-[11px] font-mono font-bold text-[#4F46E5] dark:text-[#818CF8] opacity-0 group-hover:opacity-100 transition-opacity">
                  {barCounts[i]}
                </span>
                <div
                  className="w-full bg-gradient-to-t from-[#4F46E5] to-[#818CF8] rounded-t-xl group-hover:from-[#4338CA] transition-all duration-500 shadow-xs min-h-[4px]"
                  style={{ height: `${Math.round((barCounts[i] / maxBar) * 100)}%` }}
                />
                <span className="text-[12px] font-mono font-bold text-[#64748B] dark:text-[#94A3B8]">{label}</span>
              </div>
            ))}
          </div>
          <div className="flex items-center justify-between text-[12px] font-mono text-[#64748B] dark:text-[#94A3B8] pt-3">
            <span>Trung bình: {avgPerDay.toFixed(0)} từ/ngày</span>
            <span className="font-bold text-[#059669] dark:text-[#34D399]">
              {history.filter((h) => new Date(h.searchedAt).toDateString() === new Date().toDateString()).length} từ hôm nay
            </span>
          </div>
        </Card>
      </div>
    </div>
  );
};
