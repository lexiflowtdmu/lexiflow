import React, { useState, useEffect, useCallback } from 'react';
import { HelpCircle, Clock, CheckCircle2, XCircle, ArrowRight, Sparkles, RefreshCw } from 'lucide-react';
import { getFlashcards, waterPlant, type Flashcard } from '../../lib/api';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';

interface QuizQuestion {
  id: string;
  question: string;
  options: { key: string; text: string }[];
  correctAnswer: string;
  explanation: string;
}

function buildQuiz(cards: Flashcard[]): QuizQuestion[] {
  if (cards.length < 4) return [];
  const shuffled = [...cards].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(10, shuffled.length)).map((card) => {
    // Pick 3 wrong answers from other cards
    const others = shuffled.filter((c) => c.id !== card.id).slice(0, 10);
    const distractors = others.sort(() => Math.random() - 0.5).slice(0, 3).map((c) => c.definition);
    const allOptions = [card.definition, ...distractors].sort(() => Math.random() - 0.5);
    const keys = ['A', 'B', 'C', 'D'];
    const correctKey = keys[allOptions.indexOf(card.definition)];
    return {
      id: card.id,
      question: `Từ nào có nghĩa là "${card.definition}"?`,
      options: allOptions.map((text, idx) => ({ key: keys[idx], text: cards.find((c) => c.definition === text)?.word || text })),
      correctAnswer: correctKey,
      explanation: `"${card.word}" — ${card.definition}${card.phonetic ? ` /${card.phonetic}/` : ''}`,
    };
  });
}

export const QuizView: React.FC = () => {
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [quiz, setQuiz] = useState<QuizQuestion[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentQIndex, setCurrentQIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [isAnswered, setIsAnswered] = useState(false);
  const [score, setScore] = useState(0);
  const [timeLeft, setTimeLeft] = useState(45);
  const [finished, setFinished] = useState(false);

  useEffect(() => {
    getFlashcards()
      .then((r) => {
        setCards(r.flashcards);
        setQuiz(buildQuiz(r.flashcards));
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const restartQuiz = useCallback(() => {
    setQuiz(buildQuiz(cards));
    setCurrentQIndex(0);
    setSelectedOption(null);
    setIsAnswered(false);
    setScore(0);
    setTimeLeft(45);
    setFinished(false);
  }, [cards]);

  useEffect(() => {
    if (timeLeft > 0 && !isAnswered && quiz.length > 0 && !finished) {
      const timer = setInterval(() => setTimeLeft((p) => p - 1), 1000);
      return () => clearInterval(timer);
    }
    if (timeLeft === 0 && !isAnswered && quiz.length > 0) {
      setIsAnswered(true);
    }
  }, [timeLeft, isAnswered, quiz.length, finished]);

  const handleSelectOption = (key: string) => {
    if (isAnswered) return;
    setSelectedOption(key);
    setIsAnswered(true);
    if (quiz[currentQIndex] && key === quiz[currentQIndex].correctAnswer) {
      setScore((p) => p + 1);
    }
  };

  const handleNextQuestion = () => {
    if (currentQIndex < quiz.length - 1) {
      setCurrentQIndex((p) => p + 1);
      setSelectedOption(null);
      setIsAnswered(false);
      setTimeLeft(45);
    } else {
      if (score > 0) waterPlant(score).catch(() => {});
      setFinished(true);
    }
  };

  if (loading) {
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 flex items-center justify-center">
          <div className="flex flex-col items-center gap-4 text-[#94A3B8]">
            <div className="w-10 h-10 border-4 border-[#4F46E5] border-t-transparent rounded-full animate-spin" />
            <span className="text-[14px] font-medium">Đang tải câu hỏi từ kho flashcard...</span>
          </div>
        </Card>
      </div>
    );
  }

  if (quiz.length === 0) {
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 flex flex-col items-center gap-4 text-center">
          <HelpCircle className="w-12 h-12 text-[#94A3B8] opacity-40" />
          <h3 className="font-bold text-lg text-[#0F172A] dark:text-[#F8FAFC]">Chưa đủ flashcard để tạo câu hỏi</h3>
          <p className="text-[13px] text-[#64748B] dark:text-[#94A3B8]">Hãy thêm ít nhất 4 từ vào bộ flashcard của bạn trước.</p>
        </Card>
      </div>
    );
  }

  if (finished) {
    const pct = Math.round((score / quiz.length) * 100);
    return (
      <div className="max-w-[820px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
        <Card className="p-8 flex flex-col items-center gap-6 text-center">
          <div className="w-20 h-20 rounded-full bg-[#EEF2FF] dark:bg-[#4F46E5]/20 flex items-center justify-center">
            <Sparkles className="w-10 h-10 text-[#4F46E5]" />
          </div>
          <div>
            <h2 className="text-3xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] font-mono">{score}/{quiz.length}</h2>
            <p className="text-[14px] text-[#64748B] dark:text-[#94A3B8] mt-1">Đúng {pct}% câu hỏi</p>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="primary" onClick={restartQuiz} leftIcon={<RefreshCw className="w-4 h-4" />}>
              Chơi lại
            </Button>
          </div>
        </Card>
      </div>
    );
  }

  const currentQ = quiz[currentQIndex];

  return (
    <div className="max-w-[820px] mx-auto flex flex-col gap-6 select-none font-sans animate-fade-in">
      <Card className="p-5 flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <HelpCircle className="w-5 h-5 text-[#4F46E5] dark:text-[#818CF8]" />
            <span className="font-bold text-base text-[#0F172A] dark:text-[#F8FAFC] tracking-tight">
              Trắc Nghiệm Từ Vựng (Speed Quiz)
            </span>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant="indigo" size="md">Câu {currentQIndex + 1} / {quiz.length}</Badge>
            <Badge variant="amber" size="md">
              <Clock className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
              <span>00:{timeLeft < 10 ? `0${timeLeft}` : timeLeft}</span>
            </Badge>
          </div>
        </div>
        <div className="w-full bg-[#EEF2FF] dark:bg-[#1E293B] h-2 rounded-full overflow-hidden">
          <div
            className="bg-[#4F46E5] dark:bg-[#818CF8] h-full rounded-full transition-all duration-300"
            style={{ width: `${((currentQIndex + 1) / quiz.length) * 100}%` }}
          />
        </div>
      </Card>

      <Card className="p-6 md:p-8 flex flex-col gap-6">
        <div className="text-center">
          <Badge variant="indigo" size="sm" pill>Thử Thách Từ Vựng #{String(currentQIndex + 1).padStart(2, '0')}</Badge>
          <h2 className="text-xl md:text-2xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] mt-3 leading-snug tracking-tight">
            {currentQ.question}
          </h2>
        </div>

        <div className="flex flex-col gap-3">
          {currentQ.options.map((opt) => {
            const isSelected = selectedOption === opt.key;
            const isCorrect = opt.key === currentQ.correctAnswer;
            let btnStyle = "bg-[#F8FAFC] dark:bg-[#1E293B] border-[#E2E8F0] dark:border-[#334155] text-[#0F172A] dark:text-[#F8FAFC] hover:bg-[#EEF2FF] dark:hover:bg-[#4F46E5]/20";
            if (isAnswered) {
              if (isCorrect) btnStyle = "bg-emerald-50 dark:bg-emerald-500/20 border-emerald-400 text-emerald-950 dark:text-emerald-200 font-bold ring-2 ring-emerald-400/30";
              else if (isSelected && !isCorrect) btnStyle = "bg-rose-50 dark:bg-rose-500/20 border-rose-400 text-rose-950 dark:text-rose-200 font-bold";
            }
            return (
              <button
                key={opt.key}
                onClick={() => handleSelectOption(opt.key)}
                className={`w-full p-4 rounded-2xl border text-[15px] font-semibold flex items-center justify-between transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${btnStyle}`}
              >
                <div className="flex items-center gap-3.5">
                  <span className={`w-8 h-8 rounded-xl flex items-center justify-center font-mono font-bold text-[13px] ${
                    isAnswered && isCorrect ? 'bg-[#059669] text-white'
                    : isAnswered && isSelected && !isCorrect ? 'bg-rose-600 text-white'
                    : 'bg-[#EEF2FF] dark:bg-[#4F46E5]/30 text-[#4F46E5] dark:text-[#818CF8]'
                  }`}>{opt.key}</span>
                  <span className="font-mono font-bold text-base capitalize">{opt.text}</span>
                </div>
                {isAnswered && isCorrect && <CheckCircle2 className="w-5 h-5 text-[#059669] dark:text-[#34D399]" />}
                {isAnswered && isSelected && !isCorrect && <XCircle className="w-5 h-5 text-rose-600 dark:text-rose-400" />}
              </button>
            );
          })}
        </div>

        {isAnswered && (
          <div className="bg-[#EEF2FF] dark:bg-[#4F46E5]/15 border border-[#C7D2FE]/60 dark:border-[#4F46E5]/30 p-4 rounded-2xl text-[13.5px] text-[#0F172A] dark:text-[#E2E8F0] leading-relaxed">
            <span className="font-bold text-[#4F46E5] dark:text-[#818CF8] flex items-center gap-1.5 mb-1">
              <Sparkles className="w-4 h-4" /> Giải thích:
            </span>
            {currentQ.explanation}
          </div>
        )}

        <div className="flex items-center justify-between pt-4 border-t border-[#E2E8F0] dark:border-[#334155]">
          <Button variant="ghost" size="md" onClick={handleNextQuestion}>Bỏ qua câu này</Button>
          <Button
            variant="primary" size="md"
            onClick={handleNextQuestion}
            disabled={!isAnswered}
            rightIcon={<ArrowRight className="w-4 h-4 stroke-[2.3]" />}
          >
            {currentQIndex < quiz.length - 1 ? 'Câu tiếp theo' : 'Xem kết quả'}
          </Button>
        </div>
      </Card>
    </div>
  );
};
