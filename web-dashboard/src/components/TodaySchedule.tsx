import React, { useEffect, useState } from 'react';
import { ArrowRight, CheckCircle2, Circle, Layers, HelpCircle, BookOpen, Clock } from 'lucide-react';
import { getDueFlashcards } from '../lib/api';
import { Card } from './ui/Card';
import { Badge } from './ui/Badge';

interface ScheduleItem {
  id: string;
  time: string;
  title: string;
  subtitle: string;
  type: 'flashcard' | 'quiz' | 'study';
  completed: boolean;
}

const STATIC_ITEMS: ScheduleItem[] = [
  { id: 's2', time: '14:00', title: 'Luyện Quiz tốc độ', subtitle: '10 câu hỏi trắc nghiệm ngẫu nhiên', type: 'quiz', completed: false },
  { id: 's3', time: '20:00', title: 'Đọc từ vựng chủ đề', subtitle: 'Nhóm từ Business & IELTS Academic', type: 'study', completed: false },
];

export const TodaySchedule: React.FC = () => {
  const [dueCount, setDueCount] = useState(0);
  const [schedule, setSchedule] = useState<ScheduleItem[]>(STATIC_ITEMS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDueFlashcards()
      .then((r) => {
        const count = Array.isArray(r.flashcards) ? r.flashcards.length : 0;
        setDueCount(count);
        const flashcardItem: ScheduleItem = {
          id: 's1',
          time: '09:00',
          title: `Ôn tập SM-2 hôm nay (${count} thẻ)`,
          subtitle: `${count} thẻ cần ôn theo lịch Ebbinghaus`,
          type: 'flashcard',
          completed: false,
        };
        setSchedule([flashcardItem, ...STATIC_ITEMS]);
      })
      .catch(() => {
        const flashcardItem: ScheduleItem = {
          id: 's1',
          time: '09:00',
          title: 'Ôn tập SM-2 hôm nay',
          subtitle: 'Thẻ cần ôn theo lịch Ebbinghaus',
          type: 'flashcard',
          completed: false,
        };
        setSchedule([flashcardItem, ...STATIC_ITEMS]);
      })
      .finally(() => setLoading(false));
  }, []);

  const toggleCheck = (id: string) => {
    setSchedule(prev =>
      prev.map(item => item.id === id ? { ...item, completed: !item.completed } : item)
    );
  };

  const getIcon = (type: ScheduleItem['type']) => {
    switch (type) {
      case 'flashcard': return <Layers className="w-4 h-4 text-[#4F46E5] dark:text-[#818CF8]" />;
      case 'quiz': return <HelpCircle className="w-4 h-4 text-[#7C3AED] dark:text-[#A78BFA]" />;
      case 'study': return <BookOpen className="w-4 h-4 text-amber-600 dark:text-amber-400" />;
    }
  };

  return (
    <Card className="p-5 font-sans">
      <div className="flex items-center justify-between mb-4 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
        <div className="flex items-center gap-2">
          <Clock className="w-4.5 h-4.5 text-[#4F46E5] dark:text-[#818CF8]" />
          <h3 className="text-base font-bold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
            Lịch Học Lặp Lại Hôm Nay
          </h3>
          {!loading && dueCount > 0 && (
            <span className="text-[11px] font-mono font-bold text-[#4F46E5] dark:text-[#818CF8] bg-[#EEF2FF] dark:bg-[#4F46E5]/20 px-2 py-0.5 rounded-full">
              {dueCount} thẻ đến hạn
            </span>
          )}
        </div>
        <button className="text-[12.5px] font-bold text-[#4F46E5] dark:text-[#818CF8] hover:underline flex items-center gap-1 transition-colors">
          <span>Xem chi tiết</span>
          <ArrowRight className="w-3.5 h-3.5 stroke-[2.3]" />
        </button>
      </div>

      <div className="flex flex-col gap-2.5">
        {(loading ? STATIC_ITEMS : schedule).map((item) => (
          <div
            key={item.id}
            onClick={() => toggleCheck(item.id)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => e.key === 'Enter' && toggleCheck(item.id)}
            className={`p-3 rounded-xl border transition-all cursor-pointer flex items-center justify-between gap-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
              item.completed
                ? 'bg-emerald-50/50 dark:bg-emerald-500/10 border-emerald-200/80 dark:border-emerald-500/30 opacity-80'
                : 'bg-white dark:bg-[#1E293B] border-[#E2E8F0] dark:border-[#334155] hover:border-[#818CF8] shadow-xs'
            }`}
          >
            <div className="flex items-center gap-3 min-w-0">
              <Badge variant="indigo" size="sm">{item.time}</Badge>
              <div className="w-8 h-8 rounded-lg bg-[#F8FAFC] dark:bg-[#0B0F19] border border-[#E2E8F0] dark:border-[#334155] flex items-center justify-center shrink-0">
                {getIcon(item.type)}
              </div>
              <div className="flex flex-col min-w-0">
                <span className={`text-[13px] font-bold truncate ${item.completed ? 'line-through text-[#94A3B8]' : 'text-[#0F172A] dark:text-[#F8FAFC]'}`}>
                  {item.title}
                </span>
                <span className="text-[11px] text-[#64748B] dark:text-[#94A3B8] truncate">
                  {item.subtitle}
                </span>
              </div>
            </div>
            <button
              onClick={(e) => { e.stopPropagation(); toggleCheck(item.id); }}
              aria-label={`Đánh dấu hoàn thành ${item.title}`}
              className="shrink-0 p-1 text-[#4F46E5] hover:scale-110 transition-transform"
            >
              {item.completed ? (
                <CheckCircle2 className="w-5 h-5 text-[#059669] dark:text-[#34D399] fill-[#059669]/15" />
              ) : (
                <Circle className="w-5 h-5 text-[#CBD5E1] dark:text-[#475569]" />
              )}
            </button>
          </div>
        ))}
      </div>
    </Card>
  );
};
