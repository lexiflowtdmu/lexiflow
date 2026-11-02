import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Beanstalk, CloudPlatform, CropArt, DriftCloud, PotArt, growthLevel } from './SkyGardenArt';
import { Backpack, BookOpen, Coins, Droplets, Loader2, Plus, ReceiptText, RefreshCw, X } from 'lucide-react';
import {
  fulfillFarmOrder,
  getFarmState,
  harvestCrop,
  plantCrop,
  type FarmOrder,
  type FarmPlot,
  type FarmState,
} from '../../lib/api';

const CROP_DISPLAY: Record<string, { name: string; emoji: string }> = {
  corn: { name: 'Ngô Vàng', emoji: '🌽' },
  tomato: { name: 'Cà Chua', emoji: '🍅' },
  flower: { name: 'Hoa Bách Hợp', emoji: '🌸' },
  apple: { name: 'Táo Thần', emoji: '🍎' },
  herbs: { name: 'Thảo Mộc', emoji: '🌿' },
  blueberry: { name: 'Việt Quất', emoji: '🫐' },
};
const cropOf = (id?: string) => CROP_DISPLAY[id ?? ''] ?? { name: id ?? 'Cây lạ', emoji: '🌱' };

const POT_NAMES = ['Chậu Rồng Biển', 'Chậu Phượng Hoàng', 'Chậu Ngọc Bích', 'Chậu Đất Nung Thần Bí'];

const SKY_STYLES = `
@keyframes spinWindmill { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
@keyframes plantSway { 0%, 100% { transform: rotate(-3deg); } 50% { transform: rotate(3deg); } }
@keyframes basketBounce { 0%, 100% { transform: translateY(0) scale(1); } 50% { transform: translateY(-5px) scale(1.08); } }
@keyframes harvestFloat { from { opacity: 1; transform: translate(-50%, 0); } to { opacity: 0; transform: translate(-50%, -48px); } }
@keyframes cloudDrift { from { transform: translateX(-30%); } to { transform: translateX(130%); } }
.sky-spin { animation: spinWindmill 4s linear infinite; }
.sky-sway { animation: plantSway 3.2s ease-in-out infinite; transform-origin: bottom center; }
.sky-bounce { animation: basketBounce 1.1s ease-in-out infinite; }
.sky-float { animation: harvestFloat 1.4s ease-out forwards; }
.sky-drift-a { width: 34%; top: 14%; left: 0; opacity: .35; animation: cloudDrift 70s linear infinite; }
.sky-drift-b { width: 22%; top: 58%; left: 0; opacity: .3; animation: cloudDrift 40s linear infinite; }
@media (prefers-reduced-motion: reduce) {
  .sky-spin, .sky-sway, .sky-bounce, .sky-drift-a, .sky-drift-b { animation: none; }
  .sky-float { animation-duration: 0.01s; }
}
`;

type Sheet =
  | { kind: 'plant'; slot: number }
  | { kind: 'water'; plot: FarmPlot }
  | { kind: 'orders' }
  | { kind: 'inventory' }
  | null;

interface FarmViewProps {
  onNavigate?: (tab: string) => void;
}

const SkyPot: React.FC<{
  plot: FarmPlot | undefined;
  slot: number;
  busy: boolean;
  floatText: string | null;
  onTap: () => void;
}> = ({ plot, slot, busy, floatText, onTap }) => {
  const stage = plot?.stage ?? 'empty';
  const crop = cropOf(plot?.crop);
  const level = growthLevel(plot?.waterCount ?? 0, plot?.requiredWater ?? 0, stage === 'ready');
  const label =
    stage === 'empty'
      ? `Ô ${slot + 1}: chậu trống, bấm để gieo hạt`
      : stage === 'ready'
        ? `Ô ${slot + 1}: ${crop.name} đã chín, bấm để thu hoạch`
        : `Ô ${slot + 1}: ${crop.name}, ${plot?.waterCount}/${plot?.requiredWater} từ vựng`;

  return (
    <button
      type="button"
      onClick={onTap}
      disabled={busy}
      aria-label={label}
      title={POT_NAMES[slot % POT_NAMES.length]}
      className="group relative flex min-h-11 min-w-0 flex-col items-center rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white disabled:cursor-wait"
    >
      {floatText && (
        <span className="sky-float pointer-events-none absolute left-1/2 top-0 z-10 whitespace-nowrap rounded-full bg-black/60 px-2 py-0.5 text-xs font-bold text-white">
          {floatText}
        </span>
      )}
      <div className="relative flex h-16 w-full items-end justify-center transition-transform group-hover:-translate-y-0.5 sm:h-24 lg:h-28">
        {busy ? (
          <Loader2 className="mb-2 h-6 w-6 animate-spin text-white" />
        ) : stage === 'empty' ? (
          <span className="mb-1 flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-sky-800 shadow-[0_0_10px_rgba(56,189,248,0.7)]">
            <Plus className="h-5 w-5" />
          </span>
        ) : stage === 'ready' ? (
          <>
            <CropArt crop={plot?.crop} level={2} className="h-full" />
            <span className="sky-bounce absolute left-1/2 top-0 ml-3 rounded-full border border-white bg-yellow-400 p-0.5 text-sm shadow sm:ml-6">🧺</span>
          </>
        ) : (
          <span className="sky-sway flex h-full items-end" style={{ animationDelay: `${slot * -0.4}s` }}>
            <CropArt crop={plot?.crop} level={level} className="h-full" />
          </span>
        )}
      </div>
      <PotArt variant={slot} className="relative -mt-1 w-12 drop-shadow-md sm:w-16 lg:w-20" />
      {stage !== 'empty' && plot && (
        <span className={`relative mt-1 rounded-full px-1.5 text-xs font-bold ${stage === 'ready' ? 'bg-yellow-300 text-[#0C2D48]' : 'bg-[#0C2D48] text-white'}`}>
          {stage === 'ready' ? 'Chín' : `${plot.waterCount}/${plot.requiredWater}`}
        </span>
      )}
    </button>
  );
};

const CloudFloor: React.FC<{
  title: string;
  pet: string;
  petCls: string;
  slots: number[];
  plots: FarmPlot[];
  busySlot: number | null;
  floatFx: { slot: number; text: string } | null;
  onPotTap: (slot: number, plot: FarmPlot | undefined) => void;
}> = ({ title, pet, petCls, slots, plots, busySlot, floatFx, onPotTap }) => (
  <section aria-label={title} className="relative pb-14 pl-9 pr-2 sm:pl-16 sm:pr-4">
    <h3 className="mb-1 inline-flex items-center gap-2 rounded-full bg-[#0C2D48]/80 py-0.5 pl-0.5 pr-3 text-xs font-extrabold uppercase tracking-wider text-white">
      <span aria-hidden="true" className={`flex h-7 w-7 items-center justify-center rounded-full border-2 border-white text-base ${petCls}`}>{pet}</span>
      {title}
    </h3>
    <div className="relative">
      <CloudPlatform />
      <div className="relative z-[1] grid grid-cols-4 gap-1 pb-10 sm:gap-3">
        {slots.map((slot) => {
          const plot = plots.find((p) => p.id === slot);
          return (
            <SkyPot
              key={slot}
              slot={slot}
              plot={plot}
              busy={busySlot === slot}
              floatText={floatFx?.slot === slot ? floatFx.text : null}
              onTap={() => onPotTap(slot, plot)}
            />
          );
        })}
      </div>
      <div aria-hidden="true" className="absolute inset-x-0 -bottom-8 grid grid-cols-4 justify-items-center">
        {['🌸', '☂️', '🌸', '☂️'].map((ornament, i) => (
          <div key={i} className="flex flex-col items-center">
            <div className="h-3 w-px bg-white/80" />
            <span className={`text-base ${ornament === '🌸' ? 'sky-spin' : ''}`}>{ornament}</span>
          </div>
        ))}
      </div>
    </div>
  </section>
);

const SheetFrame: React.FC<{ title: string; onClose: () => void; children: React.ReactNode }> = ({ title, onClose, children }) => {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const opener = document.activeElement as HTMLElement | null;
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => {
      window.removeEventListener('keydown', onKey);
      opener?.focus();
    };
    // onClose changes identity each render; the listener only needs the mount-time closer.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-0 sm:items-center sm:p-4" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
        className="max-h-[85vh] w-full overflow-y-auto rounded-t-3xl bg-white p-5 text-[#0F172A] shadow-2xl dark:bg-[#151C2C] dark:text-[#F8FAFC] sm:max-w-lg sm:rounded-3xl"
      >
        <div className="mb-4 flex items-center justify-between gap-3">
          <h3 className="text-lg font-extrabold">{title}</h3>
          <button ref={closeRef} type="button" onClick={onClose} aria-label="Đóng" className="flex h-11 w-11 items-center justify-center rounded-lg hover:bg-black/5 dark:hover:bg-white/10">
            <X className="h-5 w-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
};

function nextHint(farm: FarmState, fulfillable: number): { text: string; action?: 'orders' | 'study' } {
  const ready = farm.plots.filter((p) => p.stage === 'ready').length;
  const growing = farm.plots.filter((p) => p.stage === 'growing');
  const hasEmpty = farm.plots.some((p) => p.stage === 'empty');
  if (ready > 0) return { text: `${ready} cây đã chín, bấm để thu hoạch` };
  if (fulfillable > 0) return { text: `Có ${fulfillable} đơn giao được`, action: 'orders' };
  if (hasEmpty && growing.length === 0) return { text: 'Bấm một chậu để gieo hạt' };
  if (growing.length > 0) {
    const nearest = Math.min(...growing.map((p) => Math.max(p.requiredWater - p.waterCount, 0)));
    return { text: `Học thêm ${nearest} từ để cây chín`, action: 'study' };
  }
  return { text: 'Gieo thêm cây để nhận đơn mới' };
}

const canFulfill = (order: FarmOrder, inventory: Record<string, number>) =>
  order.items.every((item) => (inventory[item.type] ?? 0) >= item.qty);

export const FarmView: React.FC<FarmViewProps> = ({ onNavigate }) => {
  const [farm, setFarm] = useState<FarmState | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadFailed, setLoadFailed] = useState(false);
  const [loadError, setLoadError] = useState('');
  const [busySlot, setBusySlot] = useState<number | null>(null);
  const [busyOrder, setBusyOrder] = useState<string | null>(null);
  const [sheet, setSheet] = useState<Sheet>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [floatFx, setFloatFx] = useState<{ slot: number; text: string } | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 3000);
  };

  const loadFarm = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      setFarm(await getFarmState());
      setLoadFailed(false);
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : String(err));
      setLoadFailed(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void loadFarm(); }, [loadFarm]);

  const handlePlant = async (slot: number, cropId: string) => {
    setSheet(null);
    setBusySlot(slot);
    try {
      await plantCrop(slot, cropId);
      showToast(`Đã gieo ${cropOf(cropId).name}. Học từ vựng để tưới cây nhé!`);
      await loadFarm(true);
    } catch {
      showToast('Gieo hạt thất bại, vui lòng thử lại');
    } finally {
      setBusySlot(null);
    }
  };

  const handleHarvest = async (plot: FarmPlot) => {
    setBusySlot(plot.id);
    try {
      const { crop_type, amount } = await harvestCrop(plot.dbId);
      setFloatFx({ slot: plot.id, text: `+${amount} ${cropOf(crop_type).emoji}` });
      window.setTimeout(() => setFloatFx(null), 1400);
      await loadFarm(true);
    } catch {
      showToast('Thu hoạch thất bại, vui lòng thử lại');
    } finally {
      setBusySlot(null);
    }
  };

  const handleFulfill = async (order: FarmOrder) => {
    setBusyOrder(order.id);
    try {
      const { coins_earned, xp_earned } = await fulfillFarmOrder(order.id);
      showToast(`Giao đơn thành công: +${coins_earned} xu, +${xp_earned} XP`);
      await loadFarm(true);
    } catch {
      showToast('Không giao được đơn, vui lòng tải lại');
    } finally {
      setBusyOrder(null);
    }
  };

  const onPotTap = (slot: number, plot: FarmPlot | undefined) => {
    if (!plot || plot.stage === 'empty') setSheet({ kind: 'plant', slot });
    else if (plot.stage === 'ready') void handleHarvest(plot);
    else setSheet({ kind: 'water', plot });
  };

  const dropsNeeded = farm
    ? farm.plots.filter((p) => p.stage === 'growing').reduce((sum, p) => sum + Math.max(p.requiredWater - p.waterCount, 0), 0)
    : 0;
  const fulfillableCount = farm ? farm.pendingOrders.filter((o) => canFulfill(o, farm.inventory)).length : 0;
  const inventoryItems = farm ? Object.entries(farm.inventory).filter(([, qty]) => qty > 0) : [];
  const hint = farm ? nextHint(farm, fulfillableCount) : null;
  const hintAction = hint?.action === 'orders'
    ? () => setSheet({ kind: 'orders' })
    : hint?.action === 'study' && onNavigate
      ? () => onNavigate('flashcards')
      : undefined;

  return (
    <div className="mx-auto max-w-[1040px] pb-12 font-sans animate-fade-in">
      <style>{SKY_STYLES}</style>

      {toast && (
        <div role="status" className="fixed left-4 right-4 top-6 z-[60] rounded-2xl border border-white/10 bg-[#0F172A] px-5 py-3.5 text-[13.5px] font-semibold text-white shadow-xl animate-pop-in sm:left-auto sm:right-6">
          {toast}
        </div>
      )}

      <div className="relative min-h-[620px] overflow-hidden rounded-3xl bg-gradient-to-b from-[#0284c7] via-[#38bdf8] to-[#bae6fd] shadow-xl">
        <DriftCloud className="sky-drift-a" />
        <DriftCloud className="sky-drift-b" />
        <Beanstalk />

        {/* HUD */}
        <header className="relative z-10 flex flex-wrap items-center justify-between gap-2 bg-[#0C2D48]/80 p-3 pl-9 sm:pl-16">
          <h2 className="text-lg font-extrabold tracking-tight text-white sm:text-xl">Khu Vườn Trên Mây</h2>
          <div className="flex items-center gap-1.5">
            {farm && (
              <>
                <span title="Xu vàng" className="flex items-center gap-1 rounded-full border border-white/80 bg-black/55 px-2.5 py-1 text-xs font-bold text-white">
                  <Coins className="h-3.5 w-3.5 text-amber-300" />{farm.coins.toLocaleString('vi-VN')}
                </span>
                <span title="Số từ cần học để tất cả cây đang lớn đều chín" className="flex items-center gap-1 rounded-full border border-white/80 bg-black/55 px-2.5 py-1 text-xs font-bold text-white">
                  <Droplets className="h-3.5 w-3.5 text-sky-300" />còn {dropsNeeded} từ
                </span>
              </>
            )}
            <button type="button" onClick={() => void loadFarm()} aria-label="Làm mới" className="flex h-11 w-11 items-center justify-center rounded-full border border-white/80 bg-black/55 text-white hover:bg-black/70">
              <RefreshCw className="h-4 w-4" />
            </button>
          </div>
        </header>

        {loading ? (
          <div role="status" aria-label="Đang tải khu vườn" className="relative z-[1] mt-16 grid grid-cols-4 gap-3 pl-12 pr-4 opacity-40 sm:pl-20">
            {[0, 1, 2, 3, 4, 5, 6, 7].map((slot) => <PotArt key={slot} variant={slot} className="mx-auto mb-16 w-12 sm:w-16" />)}
          </div>
        ) : !farm || loadFailed ? (
          <div className="relative z-10 mx-auto mt-16 max-w-xs rounded-2xl bg-white/90 p-6 text-center text-[#0F172A]">
            <p className="mb-1 text-sm font-semibold">Không thể tải khu vườn.</p>
            {loadError && <p className="mb-3 break-words text-xs text-[#475569]">{loadError}</p>}
            <button type="button" onClick={() => void loadFarm()} className="rounded-xl bg-sky-700 px-4 py-2 text-sm font-bold text-white">Thử lại</button>
          </div>
        ) : (
          <>
            {hint && (
              <div className="relative z-10 mx-3 mt-3 pl-6 sm:pl-12">
                {hintAction ? (
                  <button type="button" onClick={hintAction} className="min-h-11 w-full rounded-2xl bg-[#0C2D48]/85 px-4 py-2 text-left text-sm font-bold text-white hover:bg-[#0C2D48]">
                    {hint.text} →
                  </button>
                ) : (
                  <p className="rounded-2xl bg-[#0C2D48]/85 px-4 py-3 text-sm font-bold text-white">{hint.text}</p>
                )}
              </div>
            )}
            <div className="relative z-[1] mt-3 flex flex-col gap-2">
              <CloudFloor title="Tầng Thần Thoại" pet="🐌" petCls="bg-fuchsia-600" slots={[4, 5, 6, 7]} plots={farm.plots} busySlot={busySlot} floatFx={floatFx} onPotTap={onPotTap} />
              <CloudFloor title="Tầng Bồng Bềnh" pet="🐞" petCls="bg-orange-600" slots={[0, 1, 2, 3]} plots={farm.plots} busySlot={busySlot} floatFx={floatFx} onPotTap={onPotTap} />
            </div>

            {/* Menu */}
            <nav aria-label="Menu nông trại" className="relative z-10 flex justify-end gap-3 p-4">
              <button type="button" onClick={() => setSheet({ kind: 'orders' })} aria-label={`Đơn hàng, ${fulfillableCount} đơn có thể giao`} title="Đơn hàng" className="relative flex h-12 w-12 items-center justify-center rounded-full border-2 border-white bg-emerald-500 text-white shadow-lg transition-transform hover:scale-105">
                <ReceiptText className="h-6 w-6" />
                {fulfillableCount > 0 && <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-600 text-xs font-bold">{fulfillableCount}</span>}
              </button>
              <button type="button" onClick={() => setSheet({ kind: 'inventory' })} aria-label="Kho nông sản" title="Kho nông sản" className="flex h-12 w-12 items-center justify-center rounded-full border-2 border-white bg-sky-600 text-white shadow-lg transition-transform hover:scale-105">
                <Backpack className="h-6 w-6" />
              </button>
            </nav>
          </>
        )}
      </div>

      {farm && sheet?.kind === 'plant' && (
        <SheetFrame title={`Gieo hạt vào ô ${sheet.slot + 1}`} onClose={() => setSheet(null)}>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {Object.entries(farm.cropCatalog).map(([id, def]) => (
              <button key={id} type="button" onClick={() => void handlePlant(sheet.slot, id)} className="flex flex-col items-center gap-1 rounded-2xl border border-emerald-300 bg-emerald-50 p-3 transition-colors hover:bg-emerald-100 dark:bg-emerald-500/10 dark:hover:bg-emerald-500/20">
                <CropArt crop={id} level={2} className="h-14" />
                <span className="text-center text-xs font-bold">{cropOf(id).name}</span>
                <span className="text-xs text-emerald-800 dark:text-emerald-300">Cần {def.words_needed} từ</span>
              </button>
            ))}
          </div>
        </SheetFrame>
      )}

      {sheet?.kind === 'water' && (
        <SheetFrame title={`${cropOf(sheet.plot.crop).emoji} ${cropOf(sheet.plot.crop).name}`} onClose={() => setSheet(null)}>
          <p className="mb-2 text-sm font-semibold">Tiến độ: {sheet.plot.waterCount}/{sheet.plot.requiredWater} từ vựng</p>
          <div className="mb-4 h-2 overflow-hidden rounded-full bg-sky-100 dark:bg-sky-500/20">
            <div className="h-full rounded-full bg-sky-500" style={{ width: `${Math.min((sheet.plot.waterCount / sheet.plot.requiredWater) * 100, 100)}%` }} />
          </div>
          <p className="mb-4 text-sm text-[#475569] dark:text-[#94A3B8]">Học Flashcard hoặc làm Quiz để tưới cây. Nước được cộng khi bạn hoàn thành phiên học và tưới cho cây gần chín nhất.</p>
          {onNavigate && (
            <div className="grid grid-cols-2 gap-2">
              <button type="button" onClick={() => onNavigate('flashcards')} className="flex items-center justify-center gap-2 rounded-xl bg-sky-700 px-3 py-2.5 text-sm font-bold text-white hover:bg-sky-800"><BookOpen className="h-4 w-4" />Flashcard</button>
              <button type="button" onClick={() => onNavigate('quiz')} className="rounded-xl border border-sky-700 px-3 py-2.5 text-sm font-bold text-sky-700 hover:bg-sky-50 dark:text-sky-300 dark:hover:bg-sky-500/10">Làm Quiz</button>
            </div>
          )}
        </SheetFrame>
      )}

      {farm && sheet?.kind === 'orders' && (
        <SheetFrame title="Đơn Hàng Phù Thủy" onClose={() => setSheet(null)}>
          {farm.pendingOrders.length === 0 ? (
            <p className="py-6 text-center text-sm text-[#64748B]">Chưa có đơn hàng nào.</p>
          ) : (
            <ul className="flex flex-col gap-3">
              {farm.pendingOrders.map((order) => {
                const ok = canFulfill(order, farm.inventory);
                return (
                  <li key={order.id} className={`flex items-center justify-between gap-3 rounded-2xl border p-3 ${ok ? 'border-emerald-300 bg-emerald-50 dark:bg-emerald-500/10' : 'border-[#E2E8F0] dark:border-[#334155]'}`}>
                    <div className="flex min-w-0 flex-wrap gap-1.5">
                      {order.items.map((item) => {
                        const have = farm.inventory[item.type] ?? 0;
                        return (
                          <span key={item.type} title={cropOf(item.type).name} className={`rounded-lg border px-2 py-1 text-xs font-bold ${have >= item.qty ? 'border-emerald-400 text-emerald-700 dark:text-emerald-300' : 'border-[#CBD5E1] text-[#475569] dark:border-[#475569] dark:text-[#94A3B8]'}`}>
                            {cropOf(item.type).emoji} {have}/{item.qty}
                          </span>
                        );
                      })}
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1">
                      <span className="text-xs font-bold text-amber-700 dark:text-amber-300">+{order.reward} xu · +{order.rewardXp} XP</span>
                      <button type="button" disabled={!ok || busyOrder !== null} onClick={() => void handleFulfill(order)} className="rounded-lg bg-emerald-600 px-3 py-1 text-xs font-bold text-white disabled:cursor-not-allowed disabled:opacity-40">
                        {busyOrder === order.id ? 'Đang giao…' : ok ? 'Giao' : 'Thiếu'}
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </SheetFrame>
      )}

      {farm && sheet?.kind === 'inventory' && (
        <SheetFrame title="Kho Nông Sản" onClose={() => setSheet(null)}>
          {inventoryItems.length === 0 ? (
            <p className="py-6 text-center text-sm text-[#64748B]">Kho đang trống. Hãy thu hoạch cây trồng!</p>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
              {inventoryItems.map(([id, qty]) => (
                <div key={id} className="flex flex-col items-center rounded-2xl border border-[#E2E8F0] p-3 dark:border-[#334155]">
                  <CropArt crop={id} level={2} className="h-14" />
                  <span className="text-center text-xs font-bold">{cropOf(id).name}</span>
                  <span className="text-xs text-[#475569] dark:text-[#94A3B8]">Số lượng: {qty}</span>
                </div>
              ))}
            </div>
          )}
        </SheetFrame>
      )}
    </div>
  );
};
