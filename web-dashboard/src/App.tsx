import { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Topbar } from './components/Topbar';
import { Greeting } from './components/Greeting';
import { HeroSearch } from './components/HeroSearch';
import { FeatureCards } from './components/FeatureCards';
import { RecentWords } from './components/RecentWords';
import { WordOfTheDay } from './components/WordOfTheDay';
import { LearningJourney } from './components/LearningJourney';
import { TodaySchedule } from './components/TodaySchedule';
import { MemoryStats } from './components/MemoryStats';
import { RecentActivity } from './components/RecentActivity';
import { SearchModal } from './components/SearchModal';
import { NotificationModal } from './components/NotificationModal';
import { Toast } from './components/Toast';
import type { ToastMessage } from './components/Toast';
import { AuthScreen } from './components/auth/AuthScreen';
import { useAuth } from './contexts/AuthContext';

// Feature Views
import { DictionaryView } from './components/views/DictionaryView';
import { FlashcardView } from './components/views/FlashcardView';
import { OcrView } from './components/views/OcrView';
import { QuizView } from './components/views/QuizView';
import { StatsView } from './components/views/StatsView';
import { ProfileSettingsView } from './components/views/ProfileSettingsView';
import { AdminEventsView } from './components/views/AdminEventsView';
import { FriendsView } from './components/views/FriendsView';
import { GroupsLeaderboardView } from './components/views/GroupsLeaderboardView';
import { FarmView } from './components/views/FarmView';
import { WordBattleView } from './components/views/WordBattleView';
import { CommunityEventsWidget } from './components/CommunityEventsWidget';

import { mockUser } from './data';
import { Menu, X, ArrowLeft, BookOpen } from 'lucide-react';

function LoadingScreen() {
  return (
    <div className="min-h-screen bg-[#0B0F19] flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#4338CA] to-[#6366F1] flex items-center justify-center animate-pulse">
          <BookOpen className="w-8 h-8 text-white" />
        </div>
        <div className="flex gap-1.5">
          {[0,1,2].map((i) => (
            <div key={i} className="w-2 h-2 rounded-full bg-[#6366F1] animate-bounce"
              style={{ animationDelay: `${i * 0.15}s` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

export function App() {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('home');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [searchModalOpen, setSearchModalOpen] = useState(false);
  const [notificationModalOpen, setNotificationModalOpen] = useState(false);
  const [hasUnreadNotifications, setHasUnreadNotifications] = useState(true);
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  if (loading) return <LoadingScreen />;
  if (!user) return <AuthScreen />;

  // Build user profile from Firebase user
  const currentUser = {
    ...mockUser,
    name: user.displayName || user.email?.split('@')[0] || 'Người dùng',
    email: user.email || '',
    avatar: user.photoURL || mockUser.avatar,
  };

  const addToast = (title: string, message: string) => {
    const id = Date.now().toString();
    setToasts((prev) => [...prev, { id, type: 'success', title, message }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 4000);
  };

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dictionary':
      case 'oxford':
        return <DictionaryView />;
      case 'flashcards':
      case 'sm2':
        return <FlashcardView />;
      case 'ocr':
        return <OcrView />;
      case 'quiz':
        return <QuizView />;
      case 'stats':
        return <StatsView />;
      case 'friends':
        return <FriendsView />;
      case 'groups':
      case 'group-leaderboard':
        return <GroupsLeaderboardView />;
      case 'admin-events':
      case 'events':
        return <AdminEventsView />;
      case 'profile':
      case 'settings':
        return <ProfileSettingsView />;
      case 'farm':
        return <FarmView onNavigate={setActiveTab} />;
      case 'wordbattle':
        return <WordBattleView />;
      case 'home':
      default:
        return (
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
            {/* Center Main Column */}
            <div className="xl:col-span-8 flex flex-col gap-8 min-w-0">
              <Greeting user={currentUser} />
              <HeroSearch />
              <CommunityEventsWidget onSelectEvent={() => setActiveTab('admin-events')} />
              <FeatureCards onSelectFeature={(id) => setActiveTab(id)} />
              <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-stretch">
                <div className="md:col-span-7 flex flex-col"><RecentWords /></div>
                <div className="md:col-span-5 flex flex-col"><WordOfTheDay /></div>
              </div>
            </div>

            {/* Right Column Widgets */}
            <div className="xl:col-span-4 flex flex-col gap-6 w-full">
              <LearningJourney />
              <TodaySchedule />
              <MemoryStats />
              <RecentActivity />
            </div>
          </div>
        );
    }
  };

  return (
    <div className="min-h-screen bg-[#0B0F19] flex flex-col md:flex-row text-[#F8FAFC]">
      <Toast toasts={toasts} onClose={removeToast} />

      <SearchModal
        isOpen={searchModalOpen}
        onClose={() => setSearchModalOpen(false)}
        onSelectResult={(tabId, word) => {
          setActiveTab(tabId);
          if (word) addToast('Đã mở từ vựng', `Đang xem thông tin chi tiết của từ "${word}"`);
        }}
      />

      <NotificationModal
        isOpen={notificationModalOpen}
        onClose={() => setNotificationModalOpen(false)}
        onMarkRead={() => {
          setHasUnreadNotifications(false);
          addToast('Thông báo', 'Đã đánh dấu tất cả thông báo là đã đọc');
        }}
      />

      {/* Mobile Overlay */}
      {mobileSidebarOpen && (
        <div onClick={() => setMobileSidebarOpen(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-30 md:hidden animate-fade-in" />
      )}

      {/* Sidebar */}
      <div className={`fixed inset-y-0 left-0 z-40 transform transition-transform duration-300 md:relative md:translate-x-0 ${
        mobileSidebarOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <Sidebar activeTab={activeTab} onTabChange={(tab) => {
          setActiveTab(tab);
          setMobileSidebarOpen(false);
        }} />
      </div>

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0 h-screen overflow-y-auto">
        {/* Mobile Header */}
        <div className="md:hidden flex items-center justify-between px-4 py-3 bg-[#0F172A] border-b border-[#1E293B]">
          <button onClick={() => setMobileSidebarOpen(!mobileSidebarOpen)}
            className="p-2 rounded-xl bg-[#151C2C] text-[#6366F1] border border-[#2D3748]">
            {mobileSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
          <span className="font-bold text-lg text-white" style={{ fontFamily: "'Outfit', sans-serif" }}>LexiFlow</span>
          <img src={currentUser.avatar} alt={currentUser.name}
            className="w-8 h-8 rounded-full object-cover ring-2 ring-[#6366F1]/40" />
        </div>

        <Topbar
          user={currentUser}
          onOpenSearch={() => setSearchModalOpen(true)}
          onOpenNotifications={() => setNotificationModalOpen(true)}
          hasUnread={hasUnreadNotifications}
          onProfileClick={() => setActiveTab('profile')}
        />

        {activeTab !== 'home' && (
          <div className="px-6 md:px-8 pt-4 pb-0 flex items-center gap-3 animate-fade-in">
            <button onClick={() => setActiveTab('home')}
              className="flex items-center gap-2 px-3.5 py-1.5 bg-[#151C2C] hover:bg-[#1E293B] border border-[#2D3748] rounded-xl text-[13px] font-bold text-[#6366F1] transition-colors">
              <ArrowLeft className="w-4 h-4" />
              <span>Quay lại Trang chủ</span>
            </button>
          </div>
        )}

        <main key={activeTab} className="p-6 md:p-8 flex-1 max-w-[1600px] w-full mx-auto animate-fade-in">
          {renderContent()}
        </main>
      </div>
    </div>
  );
}

export default App;
