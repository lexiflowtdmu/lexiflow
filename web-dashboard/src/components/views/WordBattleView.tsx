import React, { useState, useEffect, useCallback } from 'react';
import { Swords, Clock, CheckCircle2, XCircle, Trophy, Zap, Heart, RefreshCw, Loader2, ArrowRight } from 'lucide-react';
import { getFlashcards, type Flashcard } from '../../lib/api';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';

interface BattleQuestion {
  word: string;
  definition: string;
  phonetic?: string;
  options: string[];
  correctAnswer: string;
}

function buildBattle(cards: Flashcard[]): BattleQuestion[] {
  if (cards.length < 4) return [];
  const shuffled = [...cards].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(8, shuffled.length)).map((card) => {
    const others = shuffled.filter((c) => c.id !== card.id).slice(0, 6);
    const distractors = others.sort(() => Math.random() - 0.5).slice(0, 3).map((c) => c.definition);
    const options = [card.definition, ...distractors].sort(() => Math.random() - 0.5);
    return {
      word: card.word,
      definition: card.definition,
      phonetic: card.phonetic,
      options,
      correctAnswer: card.definition,
    };
  });
}

type BattlePhase = 'waiting' | 'playing' | 'result';

const ROUND_TIME = 10; // seconds per question in battle mode

export const WordBattleView: React.FC = () => {
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [loading, setLoading] = useState(true);
  const [phase, setPhase] = useState<BattlePhase>('waiting');
  const [questions, setQuestions] = useState<BattleQuestion[]>([]);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [selected, setSelected] = useState<string | null>(null);
  const [answered, setAnswered] = useState(false);
  const [timeLeft, setTimeLeft] = useState(ROUND_TIME);
  const [hp, setHp] = useState(3);
  const [score, setScore] = useState(0);
  const [combo, setCombo] = useState(0);
  const [maxCombo, setMaxCombo] = useState(0);
  const [correctCount, setCorrectCount] = useState(0);

  useEffect(() => {
    getFlashcards()
      .then((r) => setCards(Array.isArray(r.flashcards) ? r.flashcards : []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const startBattle = useCallback(() => {
    const q = buildBattle(cards);
    setQuestions(q);
    setCurrentIdx(0);
    setSelected(null);
    setAnswered(false);
    setTimeLeft(ROUND_TIME);
    setHp(3);
    setScore(0);
    setCombo(0);
    setMaxCombo(0);
    setCorrectCount(0);
    setPhase('playing');
  }, [cards]);

  useEffect(() => {
    if (phase !== 'playing' || answered) return;
    if (timeLeft <= 0) {
      // Time's up = wrong
      setAnswered(true);
      setHp((h) => h - 1);
      setCombo(0);
      return;
    }
    const t = setInterval(() => setTimeLeft((p) => p - 1), 1000);
    return () => clearInterval(t);
  }, [phase, timeLeft, answered]);

  useEffect(() => {
    if (hp <= 0) { setPhase('result'); }
  }, [hp]);

  const handleAnswer = (option: string) => {
    if (answered) return;
    setSelected(option);
    setAnswered(true);
    const q = questions[currentIdx];
    if (option === q.correctAnswer) {
      const newCombo = combo + 1;
      setCombo(newCombo);
      setMaxCombo((m) => Math.max(m, newCombo));
      setScore((s) => s + 10 + newCombo * 2 + Math.max(0, timeLeft));
      setCorrectCount((c) => c + 1);
    } else {
      setCombo(0);
      setHp((h) => h - 1);
    }
  };

  const handleNext = () => {
    if (currentIdx + 1 >= questions.length) {
      setPhase('result');
    } else {
      setCurrentIdx((i) => i + 1);
      setSelected(null);
      setAnswered(false);
      setTimeLeft(ROUND_TIME);
    }
  };

  if (loading) {
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans">
        <Card className="p-16 flex items-center justify-center">
          <Loader2 className="w-8 h-8 text-[#4F46E5] animate-spin" />
        </Card>
      </div>
    );
  }

  if (cards.length < 4) {
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 flex flex-col items-center gap-4 text-center">
          <Swords className="w-12 h-12 text-[#94A3B8] opacity-40" />
          <h3 className="font-bold text-lg text-[#0F172A] dark:text-[#F8FAFC]">Chưa đủ từ để chiến đấu</h3>
          <p className="text-[13px] text-[#64748B] dark:text-[#94A3B8]">Thêm ít nhất 4 từ vào flashcard của bạn để mở khóa Word Battle.</p>
        </Card>
      </div>
    );
  }

  if (phase === 'waiting') {
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 md:p-12 flex flex-col items-center gap-6 text-center relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-[#4F46E5]/10 via-transparent to-[#EF4444]/10 pointer-events-none" />
          <div className="relative z-10 flex flex-col items-center gap-6">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-[#4F46E5] to-[#EF4444] flex items-center justify-center text-4xl shadow-xl">
              ⚔️
            </div>
            <div>
              <div className="flex items-center justify-center gap-2 mb-2">
                <Badge variant="indigo" size="sm" pill>Solo Battle</Badge>
                <Badge variant="amber" size="sm" pill>XP Mode</Badge>
              </div>
              <h1 className="text-3xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">Word Battle</h1>
              <p className="text-[14px] text-[#64748B] dark:text-[#94A3B8] mt-2 max-w-md">
                Trả lời đúng trước khi hết 10 giây. Combo liên tiếp nhân điểm. Mất 3 mạng = thua.
              </p>
            </div>
            <div className="grid grid-cols-3 gap-4 w-full max-w-sm">
              {[
                { icon: '⚡', label: 'Tốc độ', desc: '10 giây/câu' },
                { icon: '❤️', label: '3 mạng', desc: 'Sai = mất mạng' },
                { icon: '🔥', label: 'Combo', desc: 'Điểm nhân đôi' },
              ].map((r) => (
                <div key={r.label} className="bg-[#F8FAFC] dark:bg-[#1E293B] p-3 rounded-2xl border border-[#E2E8F0] dark:border-[#334155] flex flex-col items-center gap-1">
                  <span className="text-xl">{r.icon}</span>
                  <span className="text-[12px] font-extrabold text-[#0F172A] dark:text-[#F8FAFC]">{r.label}</span>
                  <span className="text-[10px] text-[#94A3B8] font-medium">{r.desc}</span>
                </div>
              ))}
            </div>
            <Button variant="gradient" size="lg" onClick={startBattle} leftIcon={<Swords className="w-5 h-5" />}>
              Bắt đầu chiến đấu!
            </Button>
            <p className="text-[12px] text-[#94A3B8]">{cards.length} từ vựng trong kho · {Math.min(8, cards.length)} câu hỏi</p>
          </div>
        </Card>
      </div>
    );
  }

  if (phase === 'result') {
    const accuracy = questions.length > 0 ? Math.round((correctCount / questions.length) * 100) : 0;
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 flex flex-col items-center gap-6 text-center">
          <div className="text-5xl">{accuracy >= 80 ? '🏆' : accuracy >= 50 ? '⚔️' : '💀'}</div>
          <div>
            <h2 className="text-2xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC]">
              {accuracy >= 80 ? 'Chiến thắng!' : accuracy >= 50 ? 'Không tệ!' : 'Thất bại!'}
            </h2>
            <p className="text-[13px] text-[#64748B] dark:text-[#94A3B8] mt-1">
              {hp <= 0 ? 'Hết mạng' : `Hoàn thành ${questions.length} câu hỏi`}
            </p>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 w-full">
            {[
              { label: 'Điểm số', value: score, color: 'text-[#4F46E5] dark:text-[#818CF8]' },
              { label: 'Đúng', value: `${correctCount}/${questions.length}`, color: 'text-[#059669] dark:text-[#34D399]' },
              { label: 'Combo cao nhất', value: `x${maxCombo}`, color: 'text-amber-600 dark:text-amber-400' },
              { label: 'Chính xác', value: `${accuracy}%`, color: 'text-[#0F172A] dark:text-[#F8FAFC]' },
            ].map((s) => (
              <div key={s.label} className="bg-[#F8FAFC] dark:bg-[#1E293B] p-4 rounded-2xl border border-[#E2E8F0] dark:border-[#334155]">
                <div className={`text-2xl font-extrabold font-mono ${s.color}`}>{s.value}</div>
                <div className="text-[11px] text-[#94A3B8] mt-1 font-medium">{s.label}</div>
              </div>
            ))}
          </div>
          <div className="flex items-center gap-3">
            <Button variant="primary" onClick={startBattle} leftIcon={<RefreshCw className="w-4 h-4" />}>
              Chiến lại
            </Button>
          </div>
        </Card>
      </div>
    );
  }

  const q = questions[currentIdx];
  const timerPct = (timeLeft / ROUND_TIME) * 100;

  return (
    <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in select-none">
      {/* Battle HUD */}
      <Card className="p-4 flex flex-col gap-3">
        <div className="flex items-center justify-between gap-4">
          {/* HP */}
          <div className="flex items-center gap-1">
            {[...Array(3)].map((_, i) => (
              <Heart key={i} className={`w-5 h-5 ${i < hp ? 'text-red-500 fill-red-500' : 'text-[#E2E8F0] dark:text-[#334155]'}`} />
            ))}
          </div>
          {/* Combo */}
          <div className="flex items-center gap-1.5">
            {combo > 0 && (
              <Badge variant="amber" size="md" pill>
                <Zap className="w-3.5 h-3.5 text-amber-600 fill-amber-600" />
                <span>Combo x{combo}</span>
              </Badge>
            )}
          </div>
          {/* Score + Timer */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5">
              <Trophy className="w-4 h-4 text-[#4F46E5] dark:text-[#818CF8]" />
              <span className="font-mono font-bold text-[#0F172A] dark:text-[#F8FAFC]">{score}</span>
            </div>
            <Badge variant={timeLeft <= 3 ? 'amber' : 'slate'} size="md">
              <Clock className={`w-3.5 h-3.5 ${timeLeft <= 3 ? 'text-red-500' : ''}`} />
              <span className={timeLeft <= 3 ? 'text-red-500 font-bold' : ''}>{timeLeft}s</span>
            </Badge>
          </div>
        </div>
        {/* Timer bar */}
        <div className="w-full bg-[#EEF2FF] dark:bg-[#1E293B] h-2 rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-1000 ${timerPct > 50 ? 'bg-[#4F46E5]' : timerPct > 20 ? 'bg-amber-500' : 'bg-red-500'}`}
            style={{ width: `${timerPct}%` }}
          />
        </div>
        <div className="flex items-center justify-between text-[11px] font-mono text-[#94A3B8]">
          <span>Câu {currentIdx + 1} / {questions.length}</span>
          <div className="flex items-center gap-2">
            {[...Array(questions.length)].map((_, i) => (
              <span key={i} className={`w-1.5 h-1.5 rounded-full ${i < currentIdx ? 'bg-[#059669]' : i === currentIdx ? 'bg-[#4F46E5]' : 'bg-[#E2E8F0] dark:bg-[#334155]'}`} />
            ))}
          </div>
        </div>
      </Card>

      {/* Question */}
      <Card className="p-6 md:p-8 flex flex-col gap-6">
        <div className="text-center">
          <Badge variant="indigo" size="sm" pill>Nghĩa của từ này là gì?</Badge>
          <h2 className="text-3xl md:text-4xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] mt-3 tracking-tight capitalize font-mono">
            {q.word}
          </h2>
          {q.phonetic && (
            <p className="text-[14px] text-[#64748B] dark:text-[#94A3B8] mt-1 font-mono">/{q.phonetic}/</p>
          )}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {q.options.map((opt, i) => {
            const isSelected = selected === opt;
            const isCorrect = opt === q.correctAnswer;
            let btnStyle = "bg-[#F8FAFC] dark:bg-[#1E293B] border-[#E2E8F0] dark:border-[#334155] text-[#0F172A] dark:text-[#F8FAFC] hover:bg-[#EEF2FF] dark:hover:bg-[#4F46E5]/20 hover:border-[#4F46E5]/50";
            if (answered) {
              if (isCorrect) btnStyle = "bg-emerald-50 dark:bg-emerald-500/20 border-emerald-400 text-emerald-950 dark:text-emerald-200 font-bold ring-2 ring-emerald-400/30";
              else if (isSelected) btnStyle = "bg-rose-50 dark:bg-rose-500/20 border-rose-400 text-rose-950 dark:text-rose-200";
            }
            return (
              <button
                key={opt}
                onClick={() => handleAnswer(opt)}
                className={`w-full p-4 rounded-2xl border-2 text-[14px] font-semibold flex items-center justify-between gap-2 transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${btnStyle}`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <span className="w-7 h-7 rounded-xl shrink-0 flex items-center justify-center font-mono font-bold text-[12px] bg-[#EEF2FF] dark:bg-[#4F46E5]/30 text-[#4F46E5] dark:text-[#818CF8]">
                    {['A', 'B', 'C', 'D'][i]}
                  </span>
                  <span className="text-left leading-snug">{opt}</span>
                </div>
                {answered && isCorrect && <CheckCircle2 className="w-5 h-5 text-[#059669] shrink-0" />}
                {answered && isSelected && !isCorrect && <XCircle className="w-5 h-5 text-rose-600 shrink-0" />}
              </button>
            );
          })}
        </div>

        {answered && (
          <div className="flex items-center justify-end pt-2">
            <Button
              variant="primary" size="md"
              onClick={handleNext}
              rightIcon={<ArrowRight className="w-4 h-4" />}
            >
              {currentIdx + 1 < questions.length ? 'Tiếp theo' : 'Xem kết quả'}
            </Button>
          </div>
        )}
      </Card>
    </div>
  );
};
