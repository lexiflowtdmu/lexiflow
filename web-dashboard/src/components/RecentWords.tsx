import React, { useEffect, useState } from 'react';
import { ArrowRight, Volume2, Bookmark, BookOpen } from 'lucide-react';
import { Card } from './ui/Card';
import { Badge } from './ui/Badge';
import { getHistory, type HistoryItem } from '../lib/api';

export const RecentWords: React.FC = () => {
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getHistory()
      .then((r) => setHistory((Array.isArray(r.history) ? r.history : []).slice(0, 8)))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const playAudio = (word: string) => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(word);
      utterance.lang = 'en-US';
      window.speechSynthesis.speak(utterance);
    }
  };

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}p trước`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h trước`;
    return `${Math.floor(hrs / 24)}d trước`;
  };

  return (
    <Card className="p-5 flex flex-col justify-between h-full font-sans">
      <div>
        <div className="flex items-center justify-between mb-4 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
          <div className="flex items-center gap-2">
            <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
              Từ Vựng Vừa Tra Cứu
            </h3>
            <Badge variant="slate" size="sm" pill>Lịch sử 24h</Badge>
          </div>
          <button className="text-[12.5px] font-bold text-[#4F46E5] dark:text-[#818CF8] hover:underline flex items-center gap-1 transition-colors">
            <span>Xem tất cả</span>
            <ArrowRight className="w-3.5 h-3.5 stroke-[2.3]" />
          </button>
        </div>

        {loading ? (
          <div className="flex flex-col gap-3">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-14 rounded-xl bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
            ))}
          </div>
        ) : history.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-8 text-[#94A3B8] gap-2">
            <BookOpen className="w-8 h-8 opacity-40" />
            <span className="text-[13px] font-medium">Chưa có từ nào được tra cứu</span>
          </div>
        ) : (
          <div className="divide-y divide-[#F1F5F9] dark:divide-[#1E293B]">
            {history.map((item, i) => (
              <div
                key={`${item.word}-${i}`}
                className="py-3 flex items-center justify-between gap-3 hover:bg-[#F8FAFC] dark:hover:bg-[#1E293B]/60 px-2.5 rounded-xl transition-all group"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="w-11 h-11 rounded-xl bg-[#EEF2FF] dark:bg-[#4F46E5]/20 flex items-center justify-center shrink-0 border border-[#C7D2FE]/40">
                    <BookOpen className="w-5 h-5 text-[#4F46E5] dark:text-[#818CF8]" />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-extrabold text-[15px] text-[#0F172A] dark:text-[#F8FAFC] capitalize truncate tracking-tight">
                        {item.word}
                      </span>
                      <Badge variant="indigo" size="sm">Oxford</Badge>
                    </div>
                    <span className="text-[12px] text-[#64748B] dark:text-[#CBD5E1] truncate mt-0.5 font-medium font-mono">
                      {timeAgo(item.searchedAt)}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    onClick={() => playAudio(item.word)}
                    aria-label={`Nghe phát âm từ ${item.word}`}
                    className="p-2 text-[#4F46E5] dark:text-[#818CF8] hover:bg-[#EEF2FF] dark:hover:bg-[#4F46E5]/20 rounded-lg transition-colors"
                    title="Nghe phát âm"
                  >
                    <Volume2 className="w-4 h-4 stroke-[2]" />
                  </button>
                  <button
                    aria-label={`Lưu từ ${item.word}`}
                    className="p-2 text-[#94A3B8] hover:text-[#4F46E5] dark:hover:text-[#818CF8] hover:bg-[#EEF2FF] dark:hover:bg-[#4F46E5]/20 rounded-lg transition-colors"
                    title="Lưu từ này"
                  >
                    <Bookmark className="w-4 h-4 stroke-[2]" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Card>
  );
};
