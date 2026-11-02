import React, { useState, useEffect } from 'react';
import {
  Users,
  Plus,
  Flame,
  Sparkles,
  Copy,
  Check,
  Heart,
  Zap,
  X,
  Crown,
  UserPlus,
  Trophy
} from 'lucide-react';
import { Card } from '../ui/Card';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';
import { getAdminLeaderboard, type LeaderboardEntry } from '../../lib/api';

export interface GroupMember {
  uid: string;
  displayName: string;
  avatarUrl: string;
  userCode: string;
  xp: number;
  streakDays: number;
  role: 'owner' | 'member';
  hasLearnedToday: boolean;
}

export interface GroupData {
  id: string;
  name: string;
  description: string;
  inviteCode: string;
  members: GroupMember[];
}

export const mockGroups: GroupData[] = [
  {
    id: 'grp-1',
    name: 'Nhóm Luyện Thi IELTS 7.5+ 🎯',
    description: 'Nhóm 10 bạn cùng lớp quyết tâm chinh phục 8.0 IELTS Reading & Vocabulary.',
    inviteCode: 'GRP-8492',
    members: [
      {
        uid: 'm-1',
        displayName: 'Trần Trung Đức',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=250',
        userCode: '#LEXI-7721',
        xp: 5400,
        streakDays: 32,
        role: 'owner',
        hasLearnedToday: true
      },
      {
        uid: 'm-2',
        displayName: 'Hoàng Nam',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=250',
        userCode: '#LEXI-8492',
        xp: 2850,
        streakDays: 15,
        role: 'member',
        hasLearnedToday: true
      },
      {
        uid: 'm-3',
        displayName: 'Lê Minh Hoa',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=250',
        userCode: '#LEXI-3910',
        xp: 1420,
        streakDays: 8,
        role: 'member',
        hasLearnedToday: false
      },
      {
        uid: 'm-4',
        displayName: 'Vũ Phương Anh',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
        userCode: '#LEXI-1092',
        xp: 980,
        streakDays: 5,
        role: 'member',
        hasLearnedToday: false
      }
    ]
  },
  {
    id: 'grp-2',
    name: 'Devs & Data English Guild 💻',
    description: 'Chuyên từ vựng IT, Data, System Architecture cho lập trình viên.',
    inviteCode: 'GRP-3019',
    members: [
      {
        uid: 'm-1',
        displayName: 'Trần Trung Đức',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=250',
        userCode: '#LEXI-7721',
        xp: 5400,
        streakDays: 32,
        role: 'member',
        hasLearnedToday: true
      }
    ]
  }
];

export const GroupsLeaderboardView: React.FC = () => {
  const [groups, setGroups] = useState<GroupData[]>(mockGroups);
  const [selectedGroupId, setSelectedGroupId] = useState<string>('grp-1');
  const [period, setPeriod] = useState<'all' | 'weekly'>('weekly');
  const [globalLeaderboard, setGlobalLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [leaderboardLoading, setLeaderboardLoading] = useState(true);

  useEffect(() => {
    getAdminLeaderboard()
      .then((r) => setGlobalLeaderboard(r.leaderboard.slice(0, 10)))
      .catch(() => {})
      .finally(() => setLeaderboardLoading(false));
  }, []);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isJoinModalOpen, setIsJoinModalOpen] = useState(false);

  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupDesc, setNewGroupDesc] = useState('');
  const [joinInviteCode, setJoinInviteCode] = useState('');
  const [copiedInvite, setCopiedInvite] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const activeGroup = groups.find((g) => g.id === selectedGroupId) || groups[0];

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleCopyInviteCode = () => {
    navigator.clipboard.writeText(activeGroup.inviteCode);
    setCopiedInvite(true);
    setTimeout(() => setCopiedInvite(false), 2000);
    showToast(`Đã sao chép mã mời nhóm: ${activeGroup.inviteCode}`);
  };

  const handleCreateGroup = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;

    const newGroup: GroupData = {
      id: `grp-${Date.now()}`,
      name: newGroupName,
      description: newGroupDesc || 'Nhóm học tập LexiFlow',
      inviteCode: `GRP-${Math.floor(1000 + Math.random() * 9000)}`,
      members: [
        {
          uid: 'm-self',
          displayName: 'Nguyễn Văn A (Bạn)',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
          userCode: '#LEXI-9821',
          xp: 1420,
          streakDays: 12,
          role: 'owner',
          hasLearnedToday: true
        }
      ]
    };

    setGroups((prev) => [newGroup, ...prev]);
    setSelectedGroupId(newGroup.id);
    setIsCreateModalOpen(false);
    setNewGroupName('');
    setNewGroupDesc('');
    showToast(`Đã tạo nhóm "${newGroup.name}" thành công!`);
  };

  const handleJoinGroup = (e: React.FormEvent) => {
    e.preventDefault();
    if (!joinInviteCode.trim()) return;

    const code = joinInviteCode.trim().toUpperCase();
    showToast(`Đã gia nhập nhóm thành công với mã ${code}!`);
    setIsJoinModalOpen(false);
    setJoinInviteCode('');
  };

  const handleCheerMember = (name: string) => {
    showToast(`💖 Bạn vừa thả tim chúc mừng ${name}!`);
  };

  const handleNudgeMember = (name: string) => {
    showToast(`🔥 Đã gửi thông báo nhắc học đến ${name}!`);
  };

  return (
    <div className="flex flex-col gap-6 w-full max-w-[1500px] mx-auto animate-fade-in font-sans text-[#0F172A] dark:text-[#F8FAFC] pb-12">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="fixed top-6 right-6 z-50 bg-[#0F172A] text-white px-5 py-3.5 rounded-2xl shadow-xl border border-white/10 flex items-center gap-3 animate-pop-in">
          <Sparkles className="w-5 h-5 text-[#4F46E5]" />
          <span className="text-[13.5px] font-semibold">{toastMessage}</span>
        </div>
      )}

      {/* Top Header Banner */}
      <Card className="p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-4 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-96 h-96 bg-gradient-to-bl from-[#4F46E5]/10 via-[#6366F1]/5 to-transparent rounded-bl-full pointer-events-none" />

        <div className="flex flex-col gap-1.5 z-10">
          <div className="flex items-center gap-2">
            <Badge variant="indigo" size="sm" pill>Private Group Arena</Badge>
            <Badge variant="emerald" size="sm" pill>● Live Leaderboard</Badge>
          </div>
          <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight text-[#0F172A] dark:text-[#F8FAFC]">
            Bảng Xếp Hạng Nhóm Học Tập 🏆
          </h1>
          <p className="text-[#64748B] dark:text-[#94A3B8] text-[14px] max-w-xl">
            Tạo nhóm học tập riêng, mời bạn bè qua Mã Nhóm, thi đua Streak & XP và tương tác động viên nhau hàng ngày.
          </p>
        </div>

        <div className="flex items-center gap-3 z-10 shrink-0">
          <Button variant="secondary" size="md" onClick={() => setIsJoinModalOpen(true)} leftIcon={<UserPlus className="w-4.5 h-4.5" />}>
            Vào Nhóm Mới
          </Button>
          <Button variant="gradient" size="md" onClick={() => setIsCreateModalOpen(true)} leftIcon={<Plus className="w-4.5 h-4.5" />}>
            Tạo Nhóm Mới
          </Button>
        </div>
      </Card>

      {/* Group Selector Pills */}
      <div className="flex items-center gap-3 overflow-x-auto pb-1">
        {groups.map((g) => {
          const isSelected = g.id === selectedGroupId;
          return (
            <button
              key={g.id}
              onClick={() => setSelectedGroupId(g.id)}
              className={`flex items-center gap-2.5 px-5 py-3 rounded-2xl font-bold text-[14px] transition-all shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4F46E5] ${
                isSelected
                  ? 'bg-[#0F172A] dark:bg-[#1E293B] text-white shadow-md'
                  : 'bg-white dark:bg-[#0B0F19] border border-[#E2E8F0] dark:border-[#334155] text-[#64748B] dark:text-[#94A3B8] hover:bg-[#F8FAFC]'
              }`}
            >
              <Users className={`w-4.5 h-4.5 ${isSelected ? 'text-[#4F46E5] dark:text-[#818CF8]' : 'text-[#94A3B8]'}`} />
              <span>{g.name}</span>
              <span className={`px-2 py-0.5 rounded-full text-[11px] font-mono ${isSelected ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300'}`}>
                {g.members.length} tv
              </span>
            </button>
          );
        })}
      </div>

      {/* Active Group Details & Invite Card */}
      {activeGroup && (
        <Card className="p-6 md:p-8 flex flex-col gap-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-[#F1F5F9] dark:border-[#334155]">
            <div className="flex flex-col gap-1">
              <h2 className="font-extrabold text-2xl text-[#0F172A] dark:text-[#F8FAFC]">{activeGroup.name}</h2>
              <p className="text-[13.5px] text-[#64748B] dark:text-[#94A3B8]">{activeGroup.description}</p>
            </div>

            {/* Invite Code Box */}
            <div className="bg-[#F8FAFC] dark:bg-[#1E293B] p-3.5 rounded-2xl border border-[#E2E8F0] dark:border-[#334155] flex items-center gap-3 shrink-0">
              <div className="flex flex-col">
                <span className="text-[10px] font-mono font-bold text-[#94A3B8] uppercase">Mã Mời Nhóm</span>
                <span className="font-mono font-extrabold text-base text-[#4F46E5] dark:text-[#818CF8]">{activeGroup.inviteCode}</span>
              </div>
              <Button variant="outline" size="sm" onClick={handleCopyInviteCode}>
                {copiedInvite ? <Check className="w-4 h-4 text-emerald-600" /> : <Copy className="w-4 h-4" />}
              </Button>
            </div>
          </div>

          {/* Group Leaderboard Members Table Header & Period Switcher */}
          <div className="flex items-center justify-between gap-4 flex-wrap">
            <span className="text-[12px] font-mono font-bold text-[#94A3B8] uppercase tracking-wider">
              Bảng Xếp Hạng Thành Viên Trong Nhóm
            </span>

            <div className="bg-[#F8FAFC] dark:bg-[#1E293B] p-1 rounded-xl border border-[#E2E8F0] dark:border-[#334155] flex items-center gap-1">
              <button
                onClick={() => setPeriod('weekly')}
                className={`px-3 py-1.5 rounded-lg font-bold text-[12.5px] transition-all ${
                  period === 'weekly'
                    ? 'bg-[#4F46E5] text-white shadow-xs'
                    : 'text-[#64748B] dark:text-[#94A3B8]'
                }`}
              >
                📅 Tuần này
              </button>
              <button
                onClick={() => setPeriod('all')}
                className={`px-3 py-1.5 rounded-lg font-bold text-[12.5px] transition-all ${
                  period === 'all'
                    ? 'bg-[#0F172A] text-white shadow-xs'
                    : 'text-[#64748B] dark:text-[#94A3B8]'
                }`}
              >
                🏆 Tổng XP Tích Lũy
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-3">
            {activeGroup.members.map((member, index) => {
              let rankIcon = (
                <span className="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-mono font-bold text-[13px] flex items-center justify-center">
                  #{index + 1}
                </span>
              );
              if (index === 0) {
                rankIcon = (
                  <span className="w-7 h-7 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center font-bold">
                    <Crown className="w-4 h-4 fill-amber-500 text-amber-500" />
                  </span>
                );
              }

              return (
                <div
                  key={member.uid}
                  className={`p-4 rounded-2xl border transition-all flex flex-col md:flex-row md:items-center justify-between gap-4 ${
                    index === 0
                      ? 'bg-amber-50/40 dark:bg-amber-500/10 border-amber-200/80 dark:border-amber-500/30'
                      : 'bg-[#F8FAFC] dark:bg-[#1E293B]/60 border-[#E2E8F0] dark:border-[#334155]'
                  }`}
                >
                  <div className="flex items-center gap-3.5">
                    {rankIcon}

                    <div className="relative shrink-0">
                      <img
                        src={member.avatarUrl}
                        alt={member.displayName}
                        className="w-12 h-12 rounded-full object-cover ring-2 ring-white"
                      />
                      <span
                        className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white dark:border-[#1E293B] ${
                          index % 2 === 0 ? 'bg-emerald-500' : 'bg-slate-300'
                        }`}
                      />
                    </div>

                    <div className="flex flex-col">
                      <div className="flex items-center gap-2">
                        <h4 className="font-extrabold text-[15px] text-[#0F172A] dark:text-[#F8FAFC]">{member.displayName}</h4>
                        {member.role === 'owner' && (
                          <Badge variant="indigo" size="sm">Trưởng nhóm</Badge>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-[11px] font-mono text-[#64748B] dark:text-[#94A3B8]">{member.userCode}</span>
                        <Badge variant="emerald" size="sm">
                          {index % 2 === 0 ? '🟢 Online' : '⏱️ 12m trước'}
                        </Badge>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between md:justify-end gap-6 border-t md:border-t-0 pt-3 md:pt-0 border-[#E2E8F0] dark:border-[#334155]">
                    <div className="flex items-center gap-4 font-mono">
                      <div className="flex items-center gap-1.5">
                        <Flame className="w-4 h-4 text-amber-500 fill-amber-500" />
                        <span className="font-bold text-[13px] text-[#0F172A] dark:text-[#F8FAFC]">{member.streakDays} Ngày</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <span className="font-extrabold text-[14px] text-[#4F46E5] dark:text-[#818CF8]">+{member.xp.toLocaleString('vi-VN')} XP</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      <Button variant="ghost" size="sm" onClick={() => handleCheerMember(member.displayName)} leftIcon={<Heart className="w-3.5 h-3.5 fill-rose-500 text-rose-500" />}>
                        Khen
                      </Button>

                      {!member.hasLearnedToday && (
                        <Button variant="secondary" size="sm" onClick={() => handleNudgeMember(member.displayName)} leftIcon={<Zap className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />}>
                          Nhắc học
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}

      {/* CREATE GROUP MODAL */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white dark:bg-[#1E293B] rounded-3xl border border-[#E6ECF5] dark:border-[#334155] shadow-2xl w-full max-w-md p-6 flex flex-col gap-5 animate-pop-in">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-[#4F46E5]">
                <Users className="w-5 h-5" />
                <h3 className="font-bold text-lg text-[#0F172A] dark:text-[#F8FAFC]">Tạo Nhóm Học Tập Mới</h3>
              </div>
              <button onClick={() => setIsCreateModalOpen(false)} className="p-1 rounded-lg text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateGroup} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC]">Tên Nhóm *</label>
                <input
                  type="text"
                  required
                  placeholder="Ví dụ: Team Oxford SM-2 C2"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  className="px-4 py-2.5 bg-[#F8FAFC] dark:bg-[#0F172A] border border-[#E2E8F0] dark:border-[#334155] rounded-xl text-[14px] text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:border-[#4F46E5]"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC]">Mô Tả Nhóm</label>
                <textarea
                  rows={3}
                  placeholder="Mô tả mục tiêu học tập của nhóm..."
                  value={newGroupDesc}
                  onChange={(e) => setNewGroupDesc(e.target.value)}
                  className="px-4 py-2.5 bg-[#F8FAFC] dark:bg-[#0F172A] border border-[#E2E8F0] dark:border-[#334155] rounded-xl text-[14px] text-[#0F172A] dark:text-[#F8FAFC] focus:outline-none focus:border-[#4F46E5]"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <Button variant="ghost" onClick={() => setIsCreateModalOpen(false)}>Hủy</Button>
                <Button type="submit" variant="primary">Tạo Nhóm Ngay</Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* GLOBAL LEADERBOARD */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-5 pb-3 border-b border-[#E2E8F0] dark:border-[#334155]">
          <Trophy className="w-5 h-5 text-amber-500 fill-amber-500" />
          <h3 className="font-extrabold text-lg text-[#0F172A] dark:text-[#F8FAFC]">Bảng Xếp Hạng Toàn Cầu LexiFlow</h3>
          <Badge variant="amber" size="sm" pill>Top 10</Badge>
        </div>
        {leaderboardLoading ? (
          <div className="flex flex-col gap-2">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-14 rounded-xl bg-[#F1F5F9] dark:bg-[#1E293B] animate-pulse" />
            ))}
          </div>
        ) : globalLeaderboard.length === 0 ? (
          <div className="text-center py-6 text-[#94A3B8] text-[13px]">Chưa có dữ liệu bảng xếp hạng.</div>
        ) : (
          <div className="flex flex-col gap-2">
            {globalLeaderboard.map((entry, i) => (
              <div
                key={entry.uid}
                className={`flex items-center justify-between gap-4 p-3.5 rounded-2xl border ${
                  i === 0 ? 'bg-amber-50/40 dark:bg-amber-500/10 border-amber-200/80 dark:border-amber-500/30'
                  : i === 1 ? 'bg-slate-50/60 dark:bg-slate-500/10 border-slate-200/80 dark:border-slate-500/20'
                  : i === 2 ? 'bg-orange-50/40 dark:bg-orange-500/10 border-orange-200/60 dark:border-orange-500/20'
                  : 'bg-[#F8FAFC] dark:bg-[#1E293B]/60 border-[#E2E8F0] dark:border-[#334155]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span className={`w-7 h-7 rounded-full flex items-center justify-center font-mono font-extrabold text-[13px] ${
                    i === 0 ? 'bg-amber-400 text-white' : i === 1 ? 'bg-slate-400 text-white' : i === 2 ? 'bg-orange-400 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300'
                  }`}>
                    {i < 3 ? ['🥇','🥈','🥉'][i] : `#${entry.rank}`}
                  </span>
                  <img
                    src={`https://ui-avatars.com/api/?name=${encodeURIComponent(entry.displayName)}&background=6366f1&color=fff&size=64`}
                    alt={entry.displayName}
                    className="w-9 h-9 rounded-full object-cover ring-2 ring-white dark:ring-[#1E293B]"
                  />
                  <span className="font-bold text-[14px] text-[#0F172A] dark:text-[#F8FAFC]">{entry.displayName}</span>
                </div>
                <div className="flex items-center gap-4 font-mono text-[13px]">
                  <div className="flex items-center gap-1.5">
                    <Flame className="w-4 h-4 text-amber-500 fill-amber-500" />
                    <span className="font-bold text-[#0F172A] dark:text-[#F8FAFC]">{entry.streak}d</span>
                  </div>
                  <span className="font-extrabold text-[#4F46E5] dark:text-[#818CF8]">+{entry.xp.toLocaleString('vi-VN')} XP</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* JOIN GROUP MODAL */}
      {isJoinModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white dark:bg-[#1E293B] rounded-3xl border border-[#E6ECF5] dark:border-[#334155] shadow-2xl w-full max-w-md p-6 flex flex-col gap-5 animate-pop-in">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-[#4F46E5]">
                <UserPlus className="w-5 h-5" />
                <h3 className="font-bold text-lg text-[#0F172A] dark:text-[#F8FAFC]">Gia Nhập Nhóm Học Tập</h3>
              </div>
              <button onClick={() => setIsJoinModalOpen(false)} className="p-1 rounded-lg text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleJoinGroup} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-[13px] font-bold text-[#0F172A] dark:text-[#F8FAFC]">Nhập Mã Mời Nhóm *</label>
                <input
                  type="text"
                  required
                  placeholder="Ví dụ: GRP-1024"
                  value={joinInviteCode}
                  onChange={(e) => setJoinInviteCode(e.target.value)}
                  className="px-4 py-2.5 bg-[#F8FAFC] dark:bg-[#0F172A] border border-[#E2E8F0] dark:border-[#334155] rounded-xl text-[14px] text-[#0F172A] dark:text-[#F8FAFC] font-mono font-bold uppercase focus:outline-none focus:border-[#4F46E5]"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <Button variant="ghost" onClick={() => setIsJoinModalOpen(false)}>Hủy</Button>
                <Button type="submit" variant="primary">Vào Nhóm</Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

