import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Volume2, Layers, Sparkles, Zap, ShieldCheck, Loader2, Filter } from 'lucide-react';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';
import { getDueFlashcards, getFlashcards, reviewFlashcard, waterPlant, type Flashcard as ApiFlashcard } from '../../lib/api';

interface Flashcard {
  id: string;
  word: string;
  phonetic: string;
  partOfSpeech: string;
  tflatMeaning: string;
  oxfordDef: string;
  example: string;
  imageUrl: string;
  category?: string;
}

function apiToLocal(c: ApiFlashcard): Flashcard {
  const parts = c.definition?.split(' | ') || [];
  return {
    id: c.id,
    word: c.word,
    phonetic: c.phonetic || `/${c.word}/`,
    partOfSpeech: 'noun',
    tflatMeaning: parts[0] || c.definition,
    oxfordDef: parts[1] || c.definition,
    example: `Practice using "${c.word}" in a real sentence.`,
    imageUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?auto=format&fit=crop&q=80&w=800',
  };
}

const QUALITY_MAP: Record<string, number> = {
  'Lại từ đầu': 0,
  'Khó': 2,
  'Bình thường': 3,
  'Dễ': 5,
};

export const FlashcardView: React.FC = () => {
  const [studyMode, setStudyMode] = useState<'sm2' | 'custom'>('sm2');
  const [selectedCategory, setSelectedCategory] = useState('Tất cả');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const categories = ['Tất cả', 'Work & Business', 'IELTS Academic', 'Daily Conversation'];
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [loadingCards, setLoadingCards] = useState(true);
  const [sessionDone, setSessionDone] = useState(false);
  const pendingWaterDrops = useRef(0);

  const loadCards = useCallback(async () => {
    pendingWaterDrops.current = 0;
    setLoadingCards(true);
    setCurrentIndex(0); setIsFlipped(false); setSessionDone(false);
    try {
      if (studyMode === 'sm2') {
        const res = await getDueFlashcards();
        setCards((res.flashcards || []).map(apiToLocal));
      } else {
        const res = await getFlashcards();
        setCards((res.flashcards || []).map(apiToLocal));
      }
    } catch {
      setCards([]);
    } finally { setLoadingCards(false); }
  }, [studyMode]);

  useEffect(() => { loadCards(); }, [loadCards]);

  const currentCard = cards[currentIndex];
  const progressPercent = cards.length ? Math.round(((currentIndex) / cards.length) * 100) : 0;

  const playAudio = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(currentCard.word);
      utterance.lang = 'en-US';
      window.speechSynthesis.speak(utterance);
    }
  };

  const handleFlipCard = () => {
    setIsFlipped((prev) => !prev);
  };

  const handleRating = (ratingText: string) => {
    const quality = QUALITY_MAP[ratingText] ?? 3;
    if (currentCard) {
      reviewFlashcard({ flashcardId: currentCard.id, quality }).catch(() => {});
      if (quality > 0) pendingWaterDrops.current += 1;
    }
    setIsFlipped(false);
    setTimeout(() => {
      const next = currentIndex + 1;
      if (next >= cards.length) {
        if (pendingWaterDrops.current > 0) {
          waterPlant(pendingWaterDrops.current).catch(() => {});
          pendingWaterDrops.current = 0;
        }
        setSessionDone(true);
      } else {
        setCurrentIndex(next);
      }
    }, 250);
  };

  const [confirmAgainModal, setConfirmAgainModal] = useState(false);

  // Keyboard shortcut listener for space (flip) and 1-4 (rating)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (
        ['INPUT', 'TEXTAREA', 'SELECT'].includes(target?.tagName) ||
        target?.isContentEditable
      ) {
        return;
      }

      if (e.code === 'Space') {
        e.preventDefault();
        handleFlipCard();
      } else if (['1', '2', '3', '4'].includes(e.key)) {
        e.preventDefault();
        if (e.key === '1' && confirmAgainModal) {
          setConfirmAgainModal(true);
        } else {
          handleRating(e.key);
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentIndex, isFlipped, confirmAgainModal]);

  return (
    <div className="max-w-[860px] mx-auto flex flex-col gap-6 select-none font-sans animate-fade-in">
      {/* Mode Switcher Tabs */}
      <Card className="p-2.5 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Button
            variant={studyMode === 'sm2' ? 'gradient' : 'ghost'}
            size="sm"
            onClick={() => { setStudyMode('sm2'); setCurrentIndex(0); setIsFlipped(false); }}
            leftIcon={<Layers className="w-4 h-4" />}
          >
            Lịch SM-2 Định Kỳ
          </Button>
          <Button
            variant={studyMode === 'custom' ? 'secondary' : 'ghost'}
            size="sm"
            onClick={() => { setStudyMode('custom'); setCurrentIndex(0); setIsFlipped(false); }}
            leftIcon={<Zap className="w-4 h-4 text-amber-500 fill-current" />}
          >
            Ôn Tập Cấp Tốc (Custom)
          </Button>
        </div>

        {studyMode === 'custom' && (
          <Badge variant="amber" size="sm">
            <ShieldCheck className="w-4 h-4 text-amber-600 dark:text-amber-400" />
            <span>Không ảnh hưởng lịch SM-2</span>
          </Badge>
        )}
      </Card>

      {/* Category Filter for Custom Review */}
      {studyMode === 'custom' && (
        <Card className="p-4 flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-[13px] font-bold text-[#64748B] dark:text-[#94A3B8] shrink-0">
            <Filter className="w-4 h-4 text-[#4F46E5] dark:text-[#818CF8]" />
            <span>Lọc Chủ Đề:</span>
          </div>
          <div className="flex items-center gap-2 overflow-x-auto">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => { setSelectedCategory(cat); setCurrentIndex(0); }}
                className={`px-3.5 py-1.5 rounded-xl text-[12.5px] font-bold transition-all shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
                  selectedCategory === cat
                    ? 'bg-[#EEF2FF] dark:bg-[#4F46E5]/20 text-[#4F46E5] dark:text-[#818CF8] border border-[#4F46E5]/40'
                    : 'bg-[#F8FAFC] dark:bg-[#1E293B] text-[#64748B] dark:text-[#94A3B8] hover:bg-[#EEF2FF]'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </Card>
      )}

      {/* Top Header & Progress */}
      <Card className="p-5 flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {studyMode === 'sm2' ? (
              <Layers className="w-5 h-5 text-[#4F46E5] dark:text-[#818CF8]" />
            ) : (
              <Zap className="w-5 h-5 text-amber-500 fill-current" />
            )}
            <span className="font-bold text-base text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
              {studyMode === 'sm2' ? 'Thẻ Ghi Nhớ SM-2 (Spaced Repetition)' : 'Phiên Ôn Tập Cấp Tốc / Luyện Thi'}
            </span>
          </div>
          <Badge variant="indigo" size="md">
            Thẻ {currentIndex + 1} / {cards.length}
          </Badge>
        </div>
        {/* Progress bar */}
        <div className="w-full bg-[#EEF2FF] dark:bg-[#1E293B] h-2 rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-300 ${
              studyMode === 'sm2' ? 'bg-gradient-to-r from-[#4F46E5] to-[#059669]' : 'bg-gradient-to-r from-amber-500 to-[#4F46E5]'
            }`}
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      </Card>

      {/* Loading / Empty / Done states */}
      {loadingCards && (
        <Card className="p-12 flex flex-col items-center gap-4">
          <Loader2 className="w-10 h-10 text-[#6366F1] animate-spin" />
          <p className="text-[#94A3B8] text-sm">Đang tải thẻ ghi nhớ...</p>
        </Card>
      )}
      {!loadingCards && cards.length === 0 && (
        <Card className="p-12 flex flex-col items-center gap-4">
          <ShieldCheck className="w-12 h-12 text-emerald-400" />
          <h3 className="text-lg font-bold text-[#F8FAFC]">Hoàn thành tất cả thẻ hôm nay!</h3>
          <p className="text-[#94A3B8] text-sm text-center">Không có thẻ nào đến hạn ôn tập. Hãy quay lại vào ngày mai.</p>
          <Button variant="primary" size="md" onClick={loadCards}>Kiểm tra lại</Button>
        </Card>
      )}
      {!loadingCards && sessionDone && (
        <Card className="p-12 flex flex-col items-center gap-4">
          <Sparkles className="w-12 h-12 text-amber-400" />
          <h3 className="text-lg font-bold text-[#F8FAFC]">Phiên học hoàn thành! 🎉</h3>
          <p className="text-[#94A3B8] text-sm">Bạn đã ôn tập {cards.length} thẻ.</p>
          <Button variant="primary" size="md" onClick={loadCards}>Học tiếp</Button>
        </Card>
      )}
      {!loadingCards && !sessionDone && cards.length > 0 && currentCard && (
      <>
      {/* 3D Flip Card Container */}
      <div className="relative w-full h-[430px] perspective-1000">
        <div
          onClick={handleFlipCard}
          role="button"
          tabIndex={0}
          aria-label="Bấm hoặc gõ Space để lật thẻ ghi nhớ"
          className="w-full h-full duration-500 rounded-3xl cursor-pointer shadow-xl border border-[#E2E8F0] dark:border-[#334155] relative transition-transform transform-gpu focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
          style={{ transformStyle: 'preserve-3d', transform: isFlipped ? 'rotateY(180deg)' : 'rotateY(0deg)' }}
        >
          {/* FRONT SIDE */}
          <div
            className="absolute inset-0 p-8 flex flex-col justify-between items-center text-center bg-gradient-to-b from-white via-white to-[#F8FAFC] dark:from-[#1E293B] dark:via-[#1E293B] dark:to-[#0B0F19] rounded-3xl"
            style={{ backfaceVisibility: 'hidden' }}
          >
            <div className="w-full flex items-center justify-between">
              <Badge variant="indigo" size="sm">{currentCard.partOfSpeech}</Badge>
              <button
                onClick={playAudio}
                aria-label={`Nghe phát âm từ ${currentCard.word}`}
                className="p-2 hover:bg-[#EEF2FF] dark:hover:bg-[#4F46E5]/20 rounded-xl text-[#4F46E5] dark:text-[#818CF8] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
              >
                <Volume2 className="w-5 h-5 stroke-[2.2]" />
              </button>
            </div>

            <div className="flex flex-col items-center gap-3">
              <h2 className="text-4xl sm:text-5xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight capitalize">
                {currentCard.word}
              </h2>
              <p className="text-lg text-[#64748B] dark:text-[#94A3B8] font-mono font-semibold">
                {currentCard.phonetic}
              </p>
              <button
                onClick={playAudio}
                aria-label={`Phát âm từ ${currentCard.word}`}
                className="mt-3 w-12 h-12 rounded-2xl bg-[#4F46E5] text-white flex items-center justify-center shadow-lg shadow-[#4F46E5]/30 hover:scale-105 transition-transform focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#4F46E5]"
              >
                <Volume2 className="w-6 h-6 stroke-[2.2]" />
              </button>
            </div>

            <div className="text-[12.5px] font-bold text-[#64748B] dark:text-[#94A3B8] flex items-center gap-2 bg-[#F8FAFC] dark:bg-[#0B0F19]/60 px-4 py-2 rounded-full border border-[#E2E8F0] dark:border-[#334155]">
              <Sparkles className="w-4 h-4 text-amber-500" />
              <span>Bấm phím Space hoặc Click để lật thẻ</span>
            </div>
          </div>

          {/* BACK SIDE */}
          <div
            className="absolute inset-0 p-8 flex flex-col justify-between bg-white dark:bg-[#1E293B] rounded-3xl text-left"
            style={{ backfaceVisibility: 'hidden', transform: 'rotateY(180deg)' }}
          >
            <div>
              <div className="flex items-center justify-between mb-4 border-b border-[#E2E8F0] dark:border-[#334155] pb-3">
                <div>
                  <h3 className="text-3xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] capitalize tracking-tight">{currentCard.word}</h3>
                  <span className="text-[13px] text-[#64748B] dark:text-[#94A3B8] font-mono font-semibold">{currentCard.phonetic}</span>
                </div>
                <Badge variant="indigo" size="md">{currentCard.partOfSpeech}</Badge>
              </div>

              {/* Meaning TFLAT */}
              <div className="mb-4 bg-emerald-50/80 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/30 p-3.5 rounded-2xl">
                <span className="text-[11px] font-mono font-bold text-emerald-800 dark:text-emerald-300 block mb-1 uppercase tracking-wider">Dịch Nghĩa (TFLAT):</span>
                <span className="text-xl font-extrabold text-emerald-950 dark:text-emerald-200">{currentCard.tflatMeaning}</span>
              </div>

              {/* Oxford Definition */}
              <div className="mb-4 bg-[#F8FAFC] dark:bg-[#0B0F19]/40 border border-[#E2E8F0] dark:border-[#334155] p-3.5 rounded-2xl">
                <span className="text-[11px] font-mono font-bold text-[#0F172A] dark:text-[#F8FAFC] block mb-1 uppercase tracking-wider">Định Nghĩa (Oxford):</span>
                <p className="text-[13.5px] text-[#334155] dark:text-[#CBD5E1] font-serif-craft italic leading-relaxed">{currentCard.oxfordDef}</p>
              </div>

              {/* Example */}
              <div className="text-[13.5px] text-amber-950 dark:text-amber-200 font-serif-craft italic bg-amber-50/70 dark:bg-amber-500/10 p-3.5 rounded-2xl border border-amber-200/80 dark:border-amber-500/30">
                Ví dụ: "{currentCard.example}"
              </div>
            </div>

            <div className="text-center text-[12px] font-mono text-[#64748B] dark:text-[#94A3B8] pt-2 border-t border-[#E2E8F0] dark:border-[#334155]">
              {studyMode === 'sm2'
                ? 'Đánh giá mức độ thuộc (bấm phím 1 - 4) để thuật toán SM-2 ghi nhận.'
                : 'Chế độ Cấp Tốc: Luyện tập tự do không thay đổi lịch lặp lại SM-2.'}
            </div>
          </div>
        </div>
      </div>

      {/* Rating Buttons */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <button
          onClick={() => handleRating('Lại từ đầu')}
          aria-label="Đánh giá Quên (Phím 1)"
          className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-rose-50 dark:bg-rose-500/10 hover:bg-rose-100/80 border border-rose-200 dark:border-rose-500/30 text-rose-700 dark:text-rose-400 font-bold transition-all shadow-xs active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500"
        >
          <span className="text-[14px]">{studyMode === 'sm2' ? 'Quên [1]' : 'Chưa thuộc [1]'}</span>
          <span className="text-[11px] font-mono opacity-80">{studyMode === 'sm2' ? '< 1 phút' : 'Luyện lại'}</span>
        </button>

        <button
          onClick={() => handleRating('Khó')}
          aria-label="Đánh giá Khó (Phím 2)"
          className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-amber-50 dark:bg-amber-500/10 hover:bg-amber-100/80 border border-amber-200 dark:border-amber-500/30 text-amber-800 dark:text-amber-400 font-bold transition-all shadow-xs active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-500"
        >
          <span className="text-[14px]">Khó [2]</span>
          <span className="text-[11px] font-mono opacity-80">{studyMode === 'sm2' ? '1 ngày' : 'Cần ôn thêm'}</span>
        </button>

        <button
          onClick={() => handleRating('Bình thường')}
          aria-label="Đánh giá Tốt (Phím 3)"
          className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-indigo-50 dark:bg-indigo-500/10 hover:bg-indigo-100/80 border border-indigo-200 dark:border-indigo-500/30 text-[#4F46E5] dark:text-[#818CF8] font-bold transition-all shadow-xs active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
        >
          <span className="text-[14px]">Tốt [3]</span>
          <span className="text-[11px] font-mono opacity-80">{studyMode === 'sm2' ? '3 ngày' : 'Khá chuẩn'}</span>
        </button>

        <button
          onClick={() => handleRating('Dễ')}
          aria-label="Đánh giá Dễ (Phím 4)"
          className="flex flex-col items-center justify-center p-3.5 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 hover:bg-emerald-100/80 border border-emerald-200 dark:border-emerald-500/30 text-[#059669] dark:text-[#34D399] font-bold transition-all shadow-xs active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500"
        >
          <span className="text-[14px]">Dễ [4]</span>
          <span className="text-[11px] font-mono opacity-80">{studyMode === 'sm2' ? '6 ngày' : 'Đã thuộc'}</span>
        </button>
      </div>
      </>
      )}
    </div>
  );
};
