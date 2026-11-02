import React, { useState, useEffect, useCallback } from 'react';
import { Search, Volume2, Star, Bookmark, ArrowRight, Copy, Sparkles, Check, Loader2 } from 'lucide-react';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';
import { addHistory, getHistory, saveFlashcard, toggleBookmark, type HistoryItem } from '../../lib/api';

interface DictWord {
  word: string;
  phonetic: string;
  partOfSpeech: string;
  level: string;
  oxfordDef: string;
  tflatDef: string;
  example: string;
  synonyms: string[];
  image: string;
}

const comprehensiveDictionary: Record<string, DictWord> = {
  work: {
    word: "work",
    phonetic: "/wɜːk/",
    partOfSpeech: "noun / verb",
    level: "A1",
    oxfordDef: "activity involving mental or physical effort done in order to achieve a purpose or result.",
    tflatDef: "công việc, làm việc, lao động, tác phẩm",
    example: "She works diligently every day to accomplish her ambitious goals.",
    synonyms: ["job", "employment", "occupation", "task", "labor"],
    image: "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&q=80&w=800"
  },
  travel: {
    word: "travel",
    phonetic: "/ˈtrævl/",
    partOfSpeech: "verb / noun",
    level: "A2",
    oxfordDef: "make a journey, typically of some length or abroad.",
    tflatDef: "du lịch, đi lại, hành trình, sự di chuyển",
    example: "I love to travel to foreign countries and discover different cultures.",
    synonyms: ["journey", "trip", "voyage", "tour", "expedition"],
    image: "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&q=80&w=800"
  },
  education: {
    word: "education",
    phonetic: "/ˌedʒuˈkeɪʃn/",
    partOfSpeech: "noun",
    level: "B1",
    oxfordDef: "the process of receiving or giving systematic instruction, especially at a school or university.",
    tflatDef: "giáo dục, sự đào tạo, trình độ học vấn",
    example: "Education is the most powerful tool you can use to change the world.",
    synonyms: ["schooling", "learning", "instruction", "tuition", "scholarship"],
    image: "https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&q=80&w=800"
  },
  life: {
    word: "life",
    phonetic: "/laɪf/",
    partOfSpeech: "noun",
    level: "A1",
    oxfordDef: "the condition that distinguishes animals and plants from inorganic matter; existence.",
    tflatDef: "cuộc sống, đời sống, cuộc đời, sinh mạng",
    example: "Strive to live a meaningful life filled with learning and joy.",
    synonyms: ["existence", "living", "being", "vitality", "biography"],
    image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&q=80&w=800"
  },
  ielts: {
    word: "ielts",
    phonetic: "/ˈaɪ.el.ts/",
    partOfSpeech: "noun",
    level: "B2",
    oxfordDef: "International English Language Testing System used worldwide for study and migration.",
    tflatDef: "kỳ thi chứng chỉ tiếng Anh quốc tế IELTS",
    example: "Consistent vocabulary practice is essential to achieve an IELTS score of 7.5+.",
    synonyms: ["examination", "test", "certification", "proficiency"],
    image: "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&q=80&w=800"
  },
  hello: {
    word: "hello",
    phonetic: "/həˈləʊ/",
    partOfSpeech: "interjection / noun",
    level: "A1",
    oxfordDef: "used as a greeting or to begin a phone conversation.",
    tflatDef: "xin chào, lời chào hỏi thân thiện",
    example: "Hello! How are you doing today?",
    synonyms: ["hi", "greetings", "welcome", "hey"],
    image: "https://images.unsplash.com/photo-1577563908411-5077b6dc7624?auto=format&fit=crop&q=80&w=800"
  },
  serendipity: {
    word: "serendipity",
    phonetic: "/ˌserənˈdɪpəti/",
    partOfSpeech: "noun",
    level: "B2",
    oxfordDef: "the occurrence and development of events by chance in a happy or beneficial way.",
    tflatDef: "sự tình cờ may mắn",
    example: "Her meeting with the investor was a serendipity that changed her life.",
    synonyms: ["chance", "fortune", "luck", "coincidence"],
    image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&q=80&w=800"
  },
  innovation: {
    word: "innovation",
    phonetic: "/ˌɪnəˈveɪʃn/",
    partOfSpeech: "noun",
    level: "B2",
    oxfordDef: "the introduction of something new; a new idea, method, or device.",
    tflatDef: "sự đổi mới; cải tiến công nghệ",
    example: "Technological innovation is driving global economic growth.",
    synonyms: ["modernization", "novelty", "invention", "revolution"],
    image: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=80&w=800"
  },
  persistent: {
    word: "persistent",
    phonetic: "/pəˈsɪstənt/",
    partOfSpeech: "adjective",
    level: "C1",
    oxfordDef: "continuing firmly or obstinately in a course of action in spite of difficulty or opposition.",
    tflatDef: "kiên trì, bền bỉ, dai dẳng",
    example: "His persistent efforts eventually paid off with extraordinary success.",
    synonyms: ["tenacious", "determined", "relentless", "steadfast"],
    image: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=800"
  },
  meticulous: {
    word: "meticulous",
    phonetic: "/məˈtɪkjələs/",
    partOfSpeech: "adjective",
    level: "C1",
    oxfordDef: "showing great attention to detail; very careful and precise.",
    tflatDef: "tỉ mỉ, cẩn thận, kỹ lưỡng",
    example: "She was meticulous in preparing her lesson plans and research notes.",
    synonyms: ["thorough", "precise", "scrupulous", "painstaking"],
    image: "https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&q=80&w=800"
  },
  environment: {
    word: "environment",
    phonetic: "/ɪnˈvaɪrənmənt/",
    partOfSpeech: "noun",
    level: "B1",
    oxfordDef: "the surroundings or conditions in which a person, animal, or plant lives or operates.",
    tflatDef: "môi trường, hoàn cảnh xung quanh",
    example: "We must take immediate action to protect the natural environment.",
    synonyms: ["habitat", "surroundings", "ecosystem", "nature"],
    image: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&q=80&w=800"
  }
};

const lookupWordDefinition = (term: string): DictWord => {
  const clean = term.trim().toLowerCase();
  if (!clean) return comprehensiveDictionary['serendipity'];

  if (comprehensiveDictionary[clean]) {
    return comprehensiveDictionary[clean];
  }

  return {
    word: clean,
    phonetic: `/${clean}/`,
    partOfSpeech: "noun / adjective",
    level: "B1",
    oxfordDef: `the English word or term '${clean}' used across spoken and written communication.`,
    tflatDef: `Nghĩa tiếng Việt: từ vựng tiếng Anh "${clean}"`,
    example: `The term "${clean}" is widely used in everyday conversation and academic contexts.`,
    synonyms: ["expression", "vocabulary", "term", "phrase"],
    image: "https://images.unsplash.com/photo-1457369804613-52c61a468e7d?auto=format&fit=crop&q=80&w=800"
  };
};

export const DictionaryView: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('work');
  const [activeTab, setActiveTab] = useState<'all' | 'word' | 'example' | 'idiom'>('all');
  const [bookmarked, setBookmarked] = useState(false);
  const [copied, setCopied] = useState(false);
  const [savingFlashcard, setSavingFlashcard] = useState(false);
  const [flashcardSaved, setFlashcardSaved] = useState(false);
  const [historyItems, setHistoryItems] = useState<HistoryItem[]>([]);

  const currentWord = lookupWordDefinition(searchTerm);

  // Load history on mount
  useEffect(() => {
    getHistory().then((r) => setHistoryItems(r.history?.slice(0, 5) || [])).catch(() => {});
  }, []);

  // Save to history when search changes (debounced)
  const saveHistory = useCallback((word: string) => {
    if (word.trim().length < 2) return;
    addHistory(word.trim().toLowerCase()).catch(() => {});
  }, []);

  useEffect(() => {
    const t = setTimeout(() => saveHistory(searchTerm), 800);
    return () => clearTimeout(t);
  }, [searchTerm, saveHistory]);

  const handleAddFlashcard = async () => {
    setSavingFlashcard(true);
    try {
      await saveFlashcard(currentWord.word, `${currentWord.tflatDef} | ${currentWord.oxfordDef}`);
      setFlashcardSaved(true);
      setTimeout(() => setFlashcardSaved(false), 2000);
    } catch {}
    finally { setSavingFlashcard(false); }
  };

  const handleToggleBookmark = async () => {
    setBookmarked(!bookmarked);
    toggleBookmark(currentWord.word, currentWord.tflatDef, currentWord.phonetic).catch(() => {});
  };

  const playAudio = (type: 'UK' | 'US') => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(currentWord.word);
      utterance.lang = type === 'UK' ? 'en-GB' : 'en-US';
      window.speechSynthesis.speak(utterance);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(`${currentWord.word} ${currentWord.phonetic} - ${currentWord.tflatDef}`);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="max-w-[1280px] mx-auto flex flex-col gap-6 font-sans animate-fade-in">
      {/* Top Search Header */}
      <Card className="p-4 flex flex-col sm:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <Search className="w-5 h-5 text-[#64748B] dark:text-[#94A3B8] absolute left-3.5 top-1/2 -translate-y-1/2 stroke-[2.2]" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Tra cứu từ vựng bất kỳ (ví dụ: work, travel, education, happy, ielts)..."
            className="w-full h-11 pl-11 pr-4 bg-[#F8FAFC] dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] rounded-xl text-[14px] font-semibold text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:ring-2 focus:ring-[#4F46E5]"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto py-1">
          {['work', 'travel', 'education', 'daily life', 'ielts'].map((w) => (
            <button
              key={w}
              onClick={() => setSearchTerm(w === 'daily life' ? 'life' : w)}
              className={`px-3 py-1.5 text-[12px] font-bold rounded-xl border transition-all shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
                searchTerm.toLowerCase() === w || (w === 'daily life' && searchTerm.toLowerCase() === 'life')
                  ? 'bg-[#4F46E5] text-white border-[#4F46E5]'
                  : 'bg-[#EEF2FF] dark:bg-[#4F46E5]/20 text-[#4F46E5] dark:text-[#818CF8] border-[#C7D2FE]/60 dark:border-[#4F46E5]/30 hover:bg-[#C7D2FE]/40'
              }`}
            >
              {w}
            </button>
          ))}
        </div>
      </Card>

      {/* Main Dictionary Word Card */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Column: Word Definition Details (8 cols) */}
        <div className="lg:col-span-8 flex flex-col gap-6">
          <Card className="p-6 md:p-8">
            
            {/* Filter Tabs */}
            <div className="flex items-center gap-2 border-b border-[#E2E8F0] dark:border-[#334155] pb-3 mb-6 overflow-x-auto">
              {[
                { id: 'all', label: 'Tất cả' },
                { id: 'word', label: 'Từ vựng' },
                { id: 'example', label: 'Ví dụ Oxford' },
                { id: 'idiom', label: 'Thành ngữ' }
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`px-4 py-1.5 rounded-xl text-[13px] font-bold transition-all shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
                    activeTab === tab.id
                      ? 'bg-[#4F46E5] text-white shadow-xs'
                      : 'text-[#64748B] dark:text-[#94A3B8] hover:bg-[#F8FAFC] dark:hover:bg-[#1E293B]'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Word Title Header */}
            <div className="flex items-start justify-between mb-4">
              <div>
                <div className="flex items-center gap-3 mb-1">
                  <h1 className="text-3xl md:text-4xl font-extrabold text-[#0F172A] dark:text-[#F8FAFC] capitalize tracking-tight">
                    {currentWord.word}
                  </h1>
                  <button
                    onClick={handleToggleBookmark}
                    aria-label="Lưu vào danh sách yêu thích"
                    className="p-1.5 text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-500/20 rounded-xl transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
                  >
                    <Star className={`w-6 h-6 ${bookmarked ? 'fill-amber-500' : ''}`} />
                  </button>
                </div>
                <div className="flex items-center gap-3 text-[14.5px] font-mono font-semibold text-[#64748B] dark:text-[#94A3B8]">
                  <span>{currentWord.phonetic}</span>
                  <div className="flex items-center gap-1.5 ml-2 font-sans">
                    <button
                      onClick={() => playAudio('UK')}
                      className="px-2.5 py-1 bg-[#EEF2FF] dark:bg-[#4F46E5]/20 hover:bg-[#4F46E5] hover:text-white text-[#4F46E5] dark:text-[#818CF8] rounded-md text-[11px] font-bold flex items-center gap-1 transition-colors"
                    >
                      <Volume2 className="w-3.5 h-3.5" /> UK
                    </button>
                    <button
                      onClick={() => playAudio('US')}
                      className="px-2.5 py-1 bg-[#EEF2FF] dark:bg-[#4F46E5]/20 hover:bg-[#4F46E5] hover:text-white text-[#4F46E5] dark:text-[#818CF8] rounded-md text-[11px] font-bold flex items-center gap-1 transition-colors"
                    >
                      <Volume2 className="w-3.5 h-3.5" /> US
                    </button>
                  </div>
                </div>
              </div>

              <Button variant="outline" size="sm" onClick={handleCopy} leftIcon={<Copy className="w-4 h-4" />}>
                {copied ? 'Đã chép!' : 'Sao chép'}
              </Button>
            </div>

            {/* Part of Speech & Level Badges */}
            <div className="flex items-center gap-2 mb-6">
              <Badge variant="indigo" size="md">{currentWord.partOfSpeech}</Badge>
              <Badge variant="emerald" size="md">{currentWord.level} · Oxford CEFR</Badge>
            </div>

            {/* Oxford Definition Section */}
            <div className="mb-5 bg-[#F8FAFC] dark:bg-[#1E293B]/60 p-4 rounded-2xl border border-[#E2E8F0] dark:border-[#334155]">
              <div className="flex items-center gap-2 text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC] mb-1.5">
                <Sparkles className="w-4 h-4 text-[#4F46E5] dark:text-[#818CF8]" />
                <span>Định nghĩa Oxford (English):</span>
              </div>
              <p className="text-[14.5px] text-[#334155] dark:text-[#E2E8F0] font-serif-craft italic leading-relaxed">
                "{currentWord.oxfordDef}"
              </p>
            </div>

            {/* TFLAT Translation Section */}
            <div className="mb-5 bg-emerald-50/70 dark:bg-emerald-500/10 p-4 rounded-2xl border border-emerald-200/80 dark:border-emerald-500/30">
              <div className="text-[12px] font-mono font-bold text-emerald-800 dark:text-emerald-300 mb-1 uppercase tracking-wider">
                Dịch Nghĩa Tiếng Việt (TFLAT):
              </div>
              <div className="text-xl font-extrabold text-emerald-950 dark:text-emerald-200">
                {currentWord.tflatDef}
              </div>
            </div>

            {/* Example Sentence Section */}
            <div className="mb-6">
              <div className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC] mb-2">Ví dụ ngữ cảnh thực tế:</div>
              <div className="bg-amber-50/70 dark:bg-amber-500/10 border border-amber-200/80 dark:border-amber-500/30 p-4 rounded-2xl text-[14px] text-amber-950 dark:text-amber-200 font-serif-craft italic leading-relaxed">
                "{currentWord.example}"
              </div>
            </div>

            {/* Synonyms / Related Words */}
            <div>
              <div className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC] mb-2">Từ đồng nghĩa (Synonyms):</div>
              <div className="flex flex-wrap gap-2">
                {currentWord.synonyms.map((syn) => (
                  <button
                    key={syn}
                    onClick={() => setSearchTerm(syn)}
                    className="px-3 py-1 bg-[#EEF2FF] dark:bg-[#4F46E5]/20 hover:bg-[#4F46E5] hover:text-white text-[#4F46E5] dark:text-[#818CF8] rounded-xl text-[12px] font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
                  >
                    {syn}
                  </button>
                ))}
              </div>
            </div>

          </Card>
        </div>

        {/* Right Column: Visual Preview & Quick History (4 cols) */}
        <div className="lg:col-span-4 flex flex-col gap-6">
          {/* Image Illustration */}
          <Card className="p-5 flex flex-col gap-3">
            <h3 className="text-[15px] font-bold text-[#0F172A] dark:text-[#F8FAFC]">Minh họa từ vựng</h3>
            <div className="w-full h-[180px] rounded-xl overflow-hidden border border-[#E2E8F0] dark:border-[#334155]">
              <img
                src={currentWord.image}
                alt={currentWord.word}
                className="w-full h-full object-cover"
              />
            </div>
            <Button variant="primary" size="md" onClick={handleAddFlashcard}
              leftIcon={flashcardSaved ? <Check className="w-4 h-4" /> : savingFlashcard ? <Loader2 className="w-4 h-4 animate-spin" /> : <Bookmark className="w-4 h-4" />}>
              {flashcardSaved ? 'Đã lưu vào SM-2!' : 'Thêm vào thẻ ghi nhớ SM-2'}
            </Button>
          </Card>

          {/* Quick Lookup History */}
          <Card className="p-5">
            <h3 className="text-[15px] font-bold text-[#0F172A] dark:text-[#F8FAFC] mb-3">Lịch sử tra cứu gần đây</h3>
            <div className="flex flex-col gap-2">
              {historyItems.length === 0 ? (
                <p className="text-[13px] text-[#94A3B8] text-center py-3">Chưa có lịch sử tra cứu</p>
              ) : historyItems.map((item) => (
                <button
                  key={item.word + item.searchedAt}
                  onClick={() => setSearchTerm(item.word)}
                  className="flex items-center justify-between p-2.5 rounded-xl hover:bg-[#F8FAFC] dark:hover:bg-[#1E293B]/60 border border-transparent hover:border-[#E2E8F0] dark:hover:border-[#334155] transition-all text-left group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5]"
                >
                  <div>
                    <div className="font-extrabold text-[13.5px] text-[#0F172A] dark:text-[#F8FAFC] capitalize group-hover:text-[#4F46E5] dark:group-hover:text-[#818CF8] transition-colors">{item.word}</div>
                    <div className="text-[11.5px] text-[#64748B] dark:text-[#94A3B8]">{new Date(item.searchedAt).toLocaleDateString('vi-VN')}</div>
                  </div>
                  <ArrowRight className="w-4 h-4 text-[#94A3B8] group-hover:translate-x-1 transition-transform" />
                </button>
              ))}
            </div>
          </Card>
        </div>

      </div>
    </div>
  );
};
