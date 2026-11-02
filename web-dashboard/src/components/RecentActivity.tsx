import React, { useEffect, useState } from 'react';
import { ArrowRight, BookOpen, Activity } from 'lucide-react';
import { getHistory, type HistoryItem } from '../lib/api';
import { Card } from './ui/Card';

export const RecentActivity: React.FC = () => {
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getHistory()
      .then((r) => setHistory((Array.isArray(r.history) ? r.history : []).slice(0, 8)))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}p`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h`;
    return `${Math.floor(hrs / 24)}d`;
  };

  return (
    <Card className="p-5 font-sans">
      <div className="flex items-center justify-between mb-4 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
        <div className="flex items-center gap-2">
          <Activity className="w-4.5 h-4.5 text-[#4F46E5] dark:text-[#818CF8]" />
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
            Nhật Ký Hoạt Động
          </h3>
        </div>
        <button className="text-[12.5px] font-bold text-[#4F46E5] dark:text-[#818CF8] hover:underline flex items-center gap-1 transition-colors">
          <span>Tất cả</span>
          <ArrowRight className="w-3.5 h-3.5 stroke-[2.3]" />
        </button>
      </div>

      {loading ? (
        <div className="flex flex-col gap-2">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="h-10 rounded-xl bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
          ))}
        </div>
      ) : history.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-6 text-[#94A3B8] gap-2">
          <Activity className="w-7 h-7 opacity-40" />
          <span className="text-[13px] font-medium">Chưa có hoạt động nào</span>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {history.map((act, i) => (
            <div
              key={`${act.word}-${i}`}
              className="flex items-center justify-between gap-3 p-2.5 rounded-xl hover:bg-[#F8FAFC] dark:hover:bg-[#1E293B]/60 border border-transparent hover:border-[#E2E8F0] dark:hover:border-[#334155] transition-all"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-500/20 border border-emerald-200/60 dark:border-emerald-500/30 flex items-center justify-center shrink-0">
                  <BookOpen className="w-4 h-4 text-[#059669] dark:text-[#34D399]" />
                </div>
                <span className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC] truncate">
                  Tra cứu: <span className="text-[#4F46E5] dark:text-[#818CF8] capitalize">{act.word}</span>
                </span>
              </div>
              <span className="text-[11px] font-mono text-[#94A3B8] shrink-0">
                {timeAgo(act.searchedAt)}
              </span>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
};
