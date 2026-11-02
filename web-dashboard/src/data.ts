export interface UserProfile {
  name: string;
  email: string;
  avatar: string;
  streakDays: number;
  dailyGoalCurrent: number;
  dailyGoalTarget: number;
  quote: string;
}

export interface NavItem {
  id: string;
  label: string;
  iconName: string;
  active?: boolean;
}

export interface FeatureCardData {
  id: string;
  title: string;
  description: string;
  actionText: string;
  bgColor: string;
  borderColor: string;
  iconBg: string;
  iconColor: string;
  badgeColor?: string;
  iconName: string;
}

export interface RecentWord {
  id: string;
  word: string;
  partOfSpeech: string;
  meaning: string;
  timeAgo: string;
  phonetic: string;
  imageUrl: string;
}

export interface WordOfTheDayData {
  word: string;
  phonetic: string;
  partOfSpeech: string;
  definitionOxford: string;
  definitionTflat: string;
  example: string;
  highlightKeyword: string;
  paperNote: string;
  coverImage: string;
}

export interface ScheduleItem {
  id: string;
  time: string;
  title: string;
  subtitle: string;
  completed: boolean;
  type: 'flashcard' | 'quiz' | 'study';
}

export interface MemoryStatsData {
  period: string;
  accuracyRate: number;
  unlearned: number;
  learning: number;
  mastered: number;
}

export interface ActivityItem {
  id: string;
  title: string;
  timeAgo: string;
  type: 'search' | 'quiz' | 'bookmark';
}

export const mockUser: UserProfile = {
  name: "Nguyễn Văn A",
  email: "nguyenvana@example.com",
  avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250",
  streakDays: 12,
  dailyGoalCurrent: 8,
  dailyGoalTarget: 20,
  quote: "Kiên trì hôm nay, phiên bản tốt hơn ngày mai."
};

export const mainNavItems: NavItem[] = [
  { id: 'home', label: 'Trang chủ', iconName: 'Home', active: true },
  { id: 'dictionary', label: 'Từ điển', iconName: 'BookOpen' },
  { id: 'flashcards', label: 'Thẻ ghi nhớ', iconName: 'Layers' },
  { id: 'ocr', label: 'Quét tài liệu', iconName: 'Scan' },
  { id: 'quiz', label: 'Trắc nghiệm', iconName: 'HelpCircle' },
  { id: 'stats', label: 'Thống kê', iconName: 'BarChart2' },
  { id: 'farm', label: 'Farm', iconName: 'Sprout' },
  { id: 'wordbattle', label: 'Word Battle', iconName: 'Swords' },
];

export const secondaryNavItems: NavItem[] = [
  { id: 'friends', label: 'Bạn bè', iconName: 'Users' },
  { id: 'groups', label: 'BXH Nhóm', iconName: 'Trophy' },
  { id: 'admin-events', label: 'Quản lý sự kiện', iconName: 'Calendar' },
  { id: 'profile', label: 'Hồ sơ', iconName: 'User' },
  { id: 'settings', label: 'Cài đặt', iconName: 'Settings' },
];

export const featureCards: FeatureCardData[] = [
  {
    id: 'oxford',
    title: 'Từ điển Oxford & TFLAT',
    description: 'Tra cứu nhanh với định nghĩa chuẩn, phát âm và ví dụ thực tế.',
    actionText: 'Tra từ ngay',
    bgColor: 'bg-gradient-to-br from-[#F0F5FE] to-[#E6EFFF]',
    borderColor: 'border-[#D0E2FF]',
    iconBg: 'bg-[#1F6FEB]',
    iconColor: 'text-white',
    iconName: 'BookOpen'
  },
  {
    id: 'sm2',
    title: 'Thẻ ghi nhớ (SM-2)',
    description: 'Học thông minh hơn với lặp lại ngắt quãng.',
    actionText: 'Bắt đầu học',
    bgColor: 'bg-gradient-to-br from-[#EBFBFA] to-[#E2F7F4]',
    borderColor: 'border-[#C2EFE9]',
    iconBg: 'bg-[#10B981]',
    iconColor: 'text-white',
    iconName: 'Layers'
  },
  {
    id: 'ocr',
    title: 'Quét tài liệu Camera OCR',
    description: 'Chụp hoặc tải ảnh để nhận diện từ vựng tức thì.',
    actionText: 'Dùng camera',
    bgColor: 'bg-gradient-to-br from-[#FFF7ED] to-[#FFEDD5]',
    borderColor: 'border-[#FED7AA]',
    iconBg: 'bg-[#F59E0B]',
    iconColor: 'text-white',
    iconName: 'Camera'
  },
  {
    id: 'quiz',
    title: 'Trắc nghiệm từ vựng',
    description: 'Ôn tập và kiểm tra kiến thức của bạn.',
    actionText: 'Làm bài ngay',
    bgColor: 'bg-gradient-to-br from-[#F5F3FF] to-[#EDE9FE]',
    borderColor: 'border-[#DDD6FE]',
    iconBg: 'bg-[#7C5CFA]',
    iconColor: 'text-white',
    iconName: 'CheckSquare'
  }
];

export const recentWords: RecentWord[] = [
  {
    id: 'w1',
    word: 'serendipity',
    partOfSpeech: 'noun',
    meaning: 'sự tình cờ may mắn',
    timeAgo: '2 phút trước',
    phonetic: '/ˌserənˈdɪpəti/',
    imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&q=80&w=120'
  },
  {
    id: 'w2',
    word: 'persistent',
    partOfSpeech: 'adjective',
    meaning: 'kiên trì, bền bỉ',
    timeAgo: '15 phút trước',
    phonetic: '/pəˈsɪstənt/',
    imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=120'
  },
  {
    id: 'w3',
    word: 'meticulous',
    partOfSpeech: 'adjective',
    meaning: 'tỉ mỉ, cẩn thận',
    timeAgo: '1 giờ trước',
    phonetic: '/məˈtɪkjələs/',
    imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&q=80&w=120'
  },
  {
    id: 'w4',
    word: 'innovation',
    partOfSpeech: 'noun',
    meaning: 'sự đổi mới',
    timeAgo: '3 giờ trước',
    phonetic: '/ˌɪnəˈveɪʃn/',
    imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=80&w=120'
  },
  {
    id: 'w5',
    word: 'vocabulary',
    partOfSpeech: 'noun',
    meaning: 'từ vựng',
    timeAgo: '5 giờ trước',
    phonetic: '/vəˈkæbjələri/',
    imageUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?auto=format&fit=crop&q=80&w=120'
  }
];

export const wordOfTheDay: WordOfTheDayData = {
  word: "serendipity",
  phonetic: "/ˌserənˈdɪpəti/",
  partOfSpeech: "noun",
  definitionOxford: "the occurrence and development of events by chance in a happy or beneficial way.",
  definitionTflat: "sự tình cờ may mắn",
  example: "Her meeting with the investor was a serendipity that changed her life.",
  highlightKeyword: "serendipity",
  paperNote: "Good things take time.",
  coverImage: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&q=80&w=600"
};

export const initialSchedule: ScheduleItem[] = [
  {
    id: 's1',
    time: '09:00',
    title: 'Ôn 20 thẻ ghi nhớ',
    subtitle: 'Thẻ đang đến hạn',
    completed: true,
    type: 'flashcard'
  },
  {
    id: 's2',
    time: '14:00',
    title: 'Làm quiz 10 câu',
    subtitle: 'Ôn tập chủ đề: Travel',
    completed: false,
    type: 'quiz'
  },
  {
    id: 's3',
    time: '20:00',
    title: 'Học từ vựng mới',
    subtitle: 'Chủ đề: Work',
    completed: false,
    type: 'study'
  }
];

export const memoryStatsMap: Record<string, MemoryStatsData> = {
  '7days': {
    period: '7 ngày qua',
    accuracyRate: 68,
    unlearned: 24,
    learning: 56,
    mastered: 120
  },
  '30days': {
    period: '30 ngày qua',
    accuracyRate: 78,
    unlearned: 45,
    learning: 110,
    mastered: 380
  }
};

export const recentActivities: ActivityItem[] = [
  {
    id: 'a1',
    title: 'Đã tra cứu: innovation',
    timeAgo: '3 giờ trước',
    type: 'search'
  },
  {
    id: 'a2',
    title: 'Hoàn thành quiz (8/10)',
    timeAgo: '5 giờ trước',
    type: 'quiz'
  },
  {
    id: 'a3',
    title: 'Đã thêm vào thẻ ghi nhớ: meticulous',
    timeAgo: '1 ngày trước',
    type: 'bookmark'
  }
];

export const quickSearchTags = ['environment', 'opportunity', 'innovation', 'culture', 'sustainable'];
