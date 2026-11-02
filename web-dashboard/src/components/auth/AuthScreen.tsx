import { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { BookOpen, Eye, EyeOff, Mail, Lock, User, AlertCircle, Loader2 } from 'lucide-react';

type Tab = 'login' | 'register' | 'forgot';

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
      <path d="M17.64 9.205c0-.639-.057-1.252-.164-1.841H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615Z" fill="#4285F4"/>
      <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18Z" fill="#34A853"/>
      <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332Z" fill="#FBBC05"/>
      <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 6.29C4.672 4.163 6.656 3.58 9 3.58Z" fill="#EA4335"/>
    </svg>
  );
}

export function AuthScreen() {
  const { login, register, loginWithGoogle, resetPassword } = useAuth();
  const [tab, setTab] = useState<Tab>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const mapError = (e: unknown) => {
    const msg = (e as Error).message || '';
    if (msg.includes('user-not-found') || msg.includes('wrong-password') || msg.includes('invalid-credential'))
      return 'Email hoặc mật khẩu không chính xác.';
    if (msg.includes('email-already-in-use')) return 'Email này đã được đăng ký.';
    if (msg.includes('weak-password')) return 'Mật khẩu phải ít nhất 6 ký tự.';
    if (msg.includes('invalid-email')) return 'Email không hợp lệ.';
    if (msg.includes('popup-closed')) return 'Đăng nhập Google bị hủy.';
    if (msg.includes('popup-blocked')) return 'Trình duyệt đã chặn popup. Vui lòng cho phép và thử lại.';
    if (msg.includes('too-many-requests')) return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
    if (msg.includes('network')) return 'Lỗi kết nối mạng. Kiểm tra Internet và thử lại.';
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setSuccess('');
    setLoading(true);
    try {
      if (tab === 'login') {
        await login(email, password);
      } else if (tab === 'register') {
        if (!name.trim()) { setError('Vui lòng nhập họ tên.'); setLoading(false); return; }
        await register(email, password, name);
      } else {
        await resetPassword(email);
        setSuccess('Email đặt lại mật khẩu đã được gửi. Kiểm tra hộp thư của bạn.');
      }
    } catch (e) {
      setError(mapError(e));
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    setError(''); setLoading(true);
    try { await loginWithGoogle(); }
    catch (e) { setError(mapError(e)); }
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen bg-[#0B0F19] flex items-center justify-center p-4">
      {/* Background glow */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-indigo-600/10 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 left-1/3 w-[400px] h-[400px] bg-cyan-500/8 rounded-full blur-3xl" />
      </div>

      <div className="w-full max-w-[420px] relative z-10">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#4338CA] to-[#6366F1] flex items-center justify-center shadow-lg shadow-indigo-500/30 mb-4">
            <BookOpen className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight" style={{ fontFamily: "'Outfit', sans-serif" }}>LexiFlow</h1>
          <p className="text-[#94A3B8] text-sm mt-1">Dòng chảy từ vựng & Ghi nhớ dài lâu</p>
        </div>

        {/* Card */}
        <div className="bg-[#151C2C] border border-[#2D3748] rounded-2xl p-6 shadow-2xl">
          {/* Tabs */}
          {tab !== 'forgot' && (
            <div className="flex bg-[#0B0F19] rounded-xl p-1 mb-6">
              {(['login', 'register'] as Tab[]).map((t) => (
                <button
                  key={t}
                  onClick={() => { setTab(t); setError(''); setSuccess(''); }}
                  className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${
                    tab === t
                      ? 'bg-gradient-to-r from-[#4338CA] to-[#6366F1] text-white shadow-md shadow-indigo-500/30'
                      : 'text-[#94A3B8] hover:text-white'
                  }`}
                >
                  {t === 'login' ? 'Đăng nhập' : 'Đăng ký'}
                </button>
              ))}
            </div>
          )}

          {tab === 'forgot' && (
            <div className="mb-6">
              <button onClick={() => { setTab('login'); setError(''); setSuccess(''); }}
                className="text-[#94A3B8] text-sm hover:text-white flex items-center gap-1 mb-3 transition-colors">
                ← Quay lại đăng nhập
              </button>
              <h2 className="text-white font-bold text-lg">Quên mật khẩu</h2>
              <p className="text-[#94A3B8] text-sm mt-1">Nhập email để nhận liên kết đặt lại mật khẩu.</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            {/* Name (register only) */}
            {tab === 'register' && (
              <div className="relative">
                <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6366F1]" />
                <input
                  type="text"
                  placeholder="Họ và tên"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  className="w-full bg-[#1E293B] border border-[#2D3748] text-white placeholder-[#64748B] rounded-xl pl-10 pr-4 py-3 text-sm focus:outline-none focus:border-[#6366F1] focus:ring-1 focus:ring-[#6366F1]/50 transition-colors"
                />
              </div>
            )}

            {/* Email */}
            <div className="relative">
              <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6366F1]" />
              <input
                type="email"
                placeholder="Địa chỉ email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full bg-[#1E293B] border border-[#2D3748] text-white placeholder-[#64748B] rounded-xl pl-10 pr-4 py-3 text-sm focus:outline-none focus:border-[#6366F1] focus:ring-1 focus:ring-[#6366F1]/50 transition-colors"
              />
            </div>

            {/* Password */}
            {tab !== 'forgot' && (
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6366F1]" />
                <input
                  type={showPass ? 'text' : 'password'}
                  placeholder="Mật khẩu"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  className="w-full bg-[#1E293B] border border-[#2D3748] text-white placeholder-[#64748B] rounded-xl pl-10 pr-11 py-3 text-sm focus:outline-none focus:border-[#6366F1] focus:ring-1 focus:ring-[#6366F1]/50 transition-colors"
                />
                <button type="button" onClick={() => setShowPass(!showPass)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#64748B] hover:text-white transition-colors">
                  {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            )}

            {/* Forgot link */}
            {tab === 'login' && (
              <button type="button" onClick={() => { setTab('forgot'); setError(''); setSuccess(''); }}
                className="text-right text-xs text-[#6366F1] hover:text-[#818CF8] transition-colors self-end -mt-2">
                Quên mật khẩu?
              </button>
            )}

            {/* Error / Success */}
            {error && (
              <div className="flex items-start gap-2 bg-red-500/10 border border-red-500/30 rounded-xl px-3 py-2.5 text-red-400 text-sm">
                <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}
            {success && (
              <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-xl px-3 py-2.5 text-emerald-400 text-sm">
                {success}
              </div>
            )}

            {/* Submit */}
            <button type="submit" disabled={loading}
              className="w-full py-3 bg-gradient-to-r from-[#4338CA] to-[#6366F1] hover:from-[#4F46E5] hover:to-[#818CF8] text-white font-semibold rounded-xl text-sm transition-all shadow-lg shadow-indigo-500/30 disabled:opacity-60 flex items-center justify-center gap-2">
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              {tab === 'login' ? 'Đăng nhập' : tab === 'register' ? 'Tạo tài khoản' : 'Gửi email đặt lại'}
            </button>
          </form>

          {/* Google Sign-In */}
          {tab !== 'forgot' && (
            <>
              <div className="flex items-center gap-3 my-4">
                <div className="flex-1 h-px bg-[#2D3748]" />
                <span className="text-[#64748B] text-xs">hoặc</span>
                <div className="flex-1 h-px bg-[#2D3748]" />
              </div>

              <button onClick={handleGoogle} disabled={loading}
                className="w-full flex items-center justify-center gap-3 py-2.5 bg-[#1E293B] hover:bg-[#243047] border border-[#2D3748] hover:border-[#3D4E66] text-white font-medium rounded-xl text-sm transition-all disabled:opacity-60">
                <GoogleIcon />
                Tiếp tục với Google
              </button>
            </>
          )}
        </div>

        <p className="text-center text-[#64748B] text-xs mt-6">
          LexiFlow v2.0 · Oxford Authority Studio
        </p>
      </div>
    </div>
  );
}
