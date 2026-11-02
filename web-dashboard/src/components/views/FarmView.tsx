import React, { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Beanstalk, CloudPlatform, CropArt, DriftCloud, GameIcon, PotArt, SceneArt, growthLevel } from './SkyGardenArt';
import { ArrowUp, BookOpen, Loader2, Plus, RefreshCw, X } from 'lucide-react';
import {
  fulfillFarmOrder,
  getFarmState,
  harvestCrop,
  plantCrop,
  type FarmOrder,
  type FarmPlot,
  type FarmState,
} from '../../lib/api';

const CROP_DISPLAY: Record<string, { name: string }> = {
  corn: { name: 'Ngô Vàng' },
  tomato: { name: 'Cà Chua' },
  flower: { name: 'Hoa Bách Hợp' },
  apple: { name: 'Táo Thần' },
  herbs: { name: 'Thảo Mộc' },
  blueberry: { name: 'Việt Quất' },
};
const cropOf = (id?: string) => CROP_DISPLAY[id ?? ''] ?? { name: id ?? 'Cây lạ' };

const POT_NAMES = ['Chậu Rồng Biển', 'Chậu Phượng Hoàng', 'Chậu Ngọc Bích', 'Chậu Đất Nung Thần Bí'];

const SKY_STYLES = `
@keyframes islandBob { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }
@keyframes plantSway { 0%, 100% { transform: rotate(-3deg); } 50% { transform: rotate(3deg); } }
@keyframes basketBounce { 0%, 100% { transform: translateY(0) scale(1); } 50% { transform: translateY(-5px) scale(1.08); } }
@keyframes harvestFloat { from { opacity: 1; transform: translate(-50%, 0); } to { opacity: 0; transform: translate(-50%, -48px); } }
@keyframes targetPulse { 0%, 100% { filter: drop-shadow(0 0 4px #fde047); } 50% { filter: drop-shadow(0 0 14px #fde047); } }
@keyframes cloudDrift { from { transform: translateX(-30%); } to { transform: translateX(130%); } }
.sky-bob { animation: islandBob 6s ease-in-out infinite; }
.sky-sway { animation: plantSway 3.2s ease-in-out infinite; transform-origin: bottom center; }
.sky-bounce { animation: basketBounce 1.1s ease-in-out infinite; }
.sky-target { animation: targetPulse 1s ease-in-out infinite; }
.sky-float { animation: harvestFloat 1.4s ease-out forwards; }
.sky-drift-a { width: 34%; top: 14%; left: 0; opacity: .35; animation: cloudDrift 70s linear infinite; }
.sky-drift-b { width: 22%; top: 58%; left: 0; opacity: .3; animation: cloudDrift 40s linear infinite; }
@media (prefers-reduced-motion: reduce) {
  .sky-bob, .sky-sway, .sky-bounce, .sky-drift-a, .sky-drift-b { animation: none; }
  .sky-target { animation: none; filter: drop-shadow(0 0 8px #fde047); }
  .sky-float { animation-duration: 0.01s; }
}
`;

type DragTool = { kind: 'seed'; crop: string } | { kind: 'harvest' };

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
  target: boolean;
  markedCrop: string | null;
  onTap: () => void;
}> = ({ plot, slot, busy, floatText, target, markedCrop, onTap }) => {
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
      data-slot={slot}
      onClick={onTap}
      disabled={busy}
      aria-label={label}
      title={POT_NAMES[slot % POT_NAMES.length]}
      className={`group relative flex min-h-11 min-w-0 flex-col items-center rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white disabled:cursor-wait ${target ? 'sky-target' : ''}`}
    >
      {floatText && (
        <span className="sky-float pointer-events-none absolute left-1/2 top-0 z-10 whitespace-nowrap rounded-full bg-black/60 px-2 py-0.5 text-xs font-bold text-white">
          {floatText}
        </span>
      )}
      <div className="relative flex h-16 w-full items-end justify-center transition-transform group-hover:-translate-y-0.5 sm:h-24 lg:h-28">
        {busy ? (
          <Loader2 className="mb-2 h-6 w-6 animate-spin text-[#0C2D48]" />
        ) : markedCrop ? (
          <CropArt crop={markedCrop} level={0} className="h-2/3" />
        ) : stage === 'empty' ? (
          <span className="mb-1 flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-sky-800 shadow-[0_0_10px_rgba(56,189,248,0.7)]">
            <Plus className="h-5 w-5" />
          </span>
        ) : stage === 'ready' ? (
          <>
            <CropArt crop={plot?.crop} level={2} className="h-full" />
            <span className="sky-bounce absolute left-1/2 top-0 ml-3 sm:ml-6"><GameIcon name="basket" className="h-7 w-7 drop-shadow sm:h-9 sm:w-9" /></span>
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
  pet: 'pet-cat' | 'pet-corgi';
  slots: number[];
  plots: FarmPlot[];
  busySlots: number[];
  floatFx: { slot: number; text: string } | null;
  targets: number[];
  marked: number[];
  markedCrop: string | null;
  onPotTap: (slot: number, plot: FarmPlot | undefined) => void;
}> = ({ title, pet, slots, plots, busySlots, floatFx, targets, marked, markedCrop, onPotTap }) => (
  <section aria-label={title} className="relative mx-auto w-full max-w-[600px] pl-10 pr-1 sm:pl-24 lg:pl-0">
    <h3 className="relative z-[2] mx-auto -mb-3 w-fit rounded-lg border-b-4 border-[#7c3f12] bg-[#a85c1c] px-3 py-1 text-xs font-extrabold uppercase tracking-wider text-[#fff8e7] shadow-md">
      {title}
    </h3>
    <div className="relative aspect-[5/3]">
      <CloudPlatform />
      <div className="absolute bottom-[14%] left-[4%] right-[15%] z-[1] grid grid-cols-4 items-end gap-0.5 sm:gap-2">
        {slots.map((slot) => {
          const plot = plots.find((p) => p.id === slot);
          return (
            <SkyPot
              key={slot}
              slot={slot}
              plot={plot}
              busy={busySlots.includes(slot)}
              floatText={floatFx?.slot === slot ? floatFx.text : null}
              target={targets.includes(slot)}
              markedCrop={marked.includes(slot) ? markedCrop : null}
              onTap={() => onPotTap(slot, plot)}
            />
          );
        })}
      </div>
      <SceneArt name={pet} className="absolute bottom-[6%] right-0 z-[2] w-[15%]" />
    </div>
  </section>
);

const Building: React.FC<{
  name: 'barn' | 'well' | 'shop';
  label: string;
  ariaLabel?: string;
  badge?: number;
  className: string;
  onClick: () => void;
}> = ({ name, label, ariaLabel, badge, className, onClick }) => (
  <button
    type="button"
    onClick={onClick}
    aria-label={ariaLabel ?? label}
    className={`absolute z-[2] flex flex-col items-center rounded-2xl transition-transform hover:-translate-y-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white ${className}`}
  >
    <SceneArt name={name} className="w-full drop-shadow-lg" />
    <span className="relative z-10 -mt-3 whitespace-nowrap rounded-lg border-b-4 border-[#7c3f12] bg-[#a85c1c] px-2 py-0.5 text-xs font-extrabold text-[#fff8e7] shadow-md sm:text-sm">{label}</span>
    {badge ? <span className="absolute right-0 top-0 flex h-6 w-6 items-center justify-center rounded-full border-2 border-white bg-red-600 text-xs font-bold text-white">{badge}</span> : null}
  </button>
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
        className="max-h-[85vh] w-full overflow-y-auto rounded-t-3xl border-4 border-[#a65a1e] bg-[#fff4d9] p-5 text-[#3b2410] shadow-2xl ring-4 ring-inset ring-[#e8b66c] sm:max-w-lg sm:rounded-3xl"
      >
        <div className="mb-4 flex items-center justify-between gap-3">
          <h3 className="rounded-lg border-b-4 border-[#7c3f12] bg-[#a85c1c] px-3 py-1 text-base font-extrabold text-[#fff8e7]">{title}</h3>
          <button ref={closeRef} type="button" onClick={onClose} aria-label="Đóng" className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border-2 border-white bg-red-600 text-white shadow hover:bg-red-700">
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
  const [busySlots, setBusySlots] = useState<number[]>([]);
  const [trayOpen, setTrayOpen] = useState(false);
  const [drag, setDrag] = useState<{ tool: DragTool; x: number; y: number } | null>(null);
  const [marked, setMarked] = useState<number[]>([]);
  const scrollerRef = useRef<HTMLDivElement>(null);
  const startedAtGround = useRef(false);
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
      // A stalled token refresh or request would otherwise leave the loading pots up forever.
      const timeout = new Promise<never>((_, reject) => {
        window.setTimeout(() => reject(new Error('Máy chủ không phản hồi sau 15 giây (kiểm tra mạng hoặc đăng nhập lại)')), 15000);
      });
      setFarm(await Promise.race([getFarmState(), timeout]));
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
    setBusySlots([slot]);
    try {
      await plantCrop(slot, cropId);
      showToast(`Đã gieo ${cropOf(cropId).name}. Học từ vựng để tưới cây nhé!`);
      await loadFarm(true);
    } catch {
      showToast('Gieo hạt thất bại, vui lòng thử lại');
    } finally {
      setBusySlots([]);
    }
  };

  const handleHarvest = async (plot: FarmPlot) => {
    setBusySlots([plot.id]);
    try {
      const { crop_type, amount } = await harvestCrop(plot.dbId);
      setFloatFx({ slot: plot.id, text: `+${amount} ${cropOf(crop_type).name}` });
      window.setTimeout(() => setFloatFx(null), 1400);
      await loadFarm(true);
    } catch {
      showToast('Thu hoạch thất bại, vui lòng thử lại');
    } finally {
      setBusySlots([]);
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

  // The world opens at the ground; the player scrolls up the beanstalk to the clouds.
  useLayoutEffect(() => {
    if (farm && !startedAtGround.current && scrollerRef.current) {
      startedAtGround.current = true;
      scrollerRef.current.scrollTop = scrollerRef.current.scrollHeight;
    }
  }, [farm]);

  const isTarget = (tool: DragTool, slot: number) => {
    const stage = farm?.plots.find((p) => p.id === slot)?.stage ?? 'empty';
    return tool.kind === 'seed' ? stage === 'empty' : stage === 'ready';
  };

  const runDragAction = async (tool: DragTool, slots: number[]) => {
    if (!farm) return;
    setBusySlots(slots);
    let failed = 0;
    let gained = 0;
    for (const slot of slots) {
      try {
        if (tool.kind === 'seed') {
          await plantCrop(slot, tool.crop);
        } else {
          const plot = farm.plots.find((p) => p.id === slot);
          if (plot) gained += (await harvestCrop(plot.dbId)).amount;
        }
      } catch {
        failed += 1;
      }
    }
    await loadFarm(true);
    setBusySlots([]);
    setMarked([]);
    if (failed > 0) showToast(`${failed} chậu chưa thực hiện được, vui lòng thử lại`);
    else if (tool.kind === 'seed') showToast(`Đã gieo ${slots.length} chậu ${cropOf(tool.crop).name}. Học từ vựng để tưới cây nhé!`);
    else showToast(`Thu hoạch được ${gained} nông sản, xem trong Kho`);
  };

  /** Hold a seed or the basket and sweep it over pots; every valid pot passed over is acted on at release. */
  const startDrag = (tool: DragTool, e: React.PointerEvent) => {
    e.preventDefault();
    const hits = new Set<number>();
    let pointerY = e.clientY;
    setDrag({ tool, x: e.clientX, y: e.clientY });

    const scrollTimer = window.setInterval(() => {
      const box = scrollerRef.current?.getBoundingClientRect();
      if (!box || !scrollerRef.current) return;
      if (pointerY < box.top + 90) scrollerRef.current.scrollTop -= 10;
      else if (pointerY > box.bottom - 170) scrollerRef.current.scrollTop += 10;
    }, 16);

    const onMove = (ev: PointerEvent) => {
      pointerY = ev.clientY;
      setDrag({ tool, x: ev.clientX, y: ev.clientY });
      const pot = document.elementFromPoint(ev.clientX, ev.clientY)?.closest<HTMLElement>('[data-slot]');
      if (!pot) return;
      const slot = Number(pot.dataset.slot);
      if (!hits.has(slot) && isTarget(tool, slot)) {
        hits.add(slot);
        setMarked([...hits]);
      }
    };
    const finish = (commit: boolean) => {
      window.clearInterval(scrollTimer);
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onCancel);
      setDrag(null);
      if (commit && hits.size > 0) void runDragAction(tool, [...hits]);
      else {
        setMarked([]);
        if (commit) showToast(tool.kind === 'seed' ? 'Giữ và kéo hạt vào chậu trống' : 'Giữ và kéo giỏ qua cây đã chín');
      }
    };
    const onUp = () => finish(true);
    const onCancel = () => finish(false);
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
    window.addEventListener('pointercancel', onCancel);
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
    <div className="mx-auto max-w-[1280px] font-sans animate-fade-in">
      <style>{SKY_STYLES}</style>

      {toast && (
        <div role="status" className="fixed left-4 right-4 top-6 z-[60] rounded-2xl border border-white/10 bg-[#0F172A] px-5 py-3.5 text-[13.5px] font-semibold text-white shadow-xl animate-pop-in sm:left-auto sm:right-6">
          {toast}
        </div>
      )}

      <div className="relative h-[calc(100vh-9rem)] min-h-[600px] overflow-hidden rounded-3xl bg-[#38bdf8] shadow-xl">
        {/* HUD */}
        <header className="pointer-events-none absolute inset-x-0 top-0 z-20 flex flex-wrap items-center justify-between gap-2 p-3">
          <h2 className="rounded-xl border-b-4 border-[#7c3f12] bg-[#a85c1c] px-4 py-1.5 text-base font-black tracking-tight text-[#fff8e7] shadow-lg sm:text-lg">Khu Vườn Trên Mây</h2>
          <div className="pointer-events-auto flex items-center gap-1.5">
            {farm && (
              <>
                <span title="Xu vàng" className="flex h-11 items-center gap-1.5 whitespace-nowrap rounded-full border-2 border-[#7c3f12] bg-[#fff4d9] px-2 text-sm font-black text-[#3b2410] shadow-lg sm:px-3">
                  <GameIcon name="coin" className="h-6 w-6" />{farm.coins.toLocaleString('vi-VN')}
                </span>
                <span title="Số từ cần học để tất cả cây đang lớn đều chín" className="flex h-11 items-center gap-1.5 whitespace-nowrap rounded-full border-2 border-[#7c3f12] bg-[#fff4d9] px-2 text-sm font-black text-[#3b2410] shadow-lg sm:px-3">
                  <GameIcon name="drop" className="h-6 w-6" />còn {dropsNeeded} từ
                </span>
              </>
            )}
            <button type="button" onClick={() => void loadFarm()} aria-label="Làm mới" className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-white/80 bg-black/55 text-white hover:bg-black/70">
              <RefreshCw className="h-4 w-4" />
            </button>
          </div>
        </header>

        {loading ? (
          <div role="status" className="absolute inset-0 flex items-center justify-center bg-gradient-to-b from-[#0284c7] to-[#bae6fd]">
            <p className="flex items-center gap-2 rounded-2xl border-2 border-[#7c3f12] bg-[#fff4d9] px-4 py-2 text-sm font-extrabold text-[#3b2410] shadow-lg">
              <Loader2 className="h-4 w-4 animate-spin" />Đang tải khu vườn…
            </p>
          </div>
        ) : !farm || loadFailed ? (
          <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-b from-[#0284c7] to-[#bae6fd] p-4">
            <div className="max-w-xs rounded-2xl bg-white/90 p-6 text-center text-[#0F172A]">
              <p className="mb-1 text-sm font-semibold">Không thể tải khu vườn.</p>
              {loadError && <p className="mb-3 break-words text-xs text-[#5b4023]">{loadError}</p>}
              <button type="button" onClick={() => void loadFarm()} className="rounded-xl bg-sky-700 px-4 py-2 text-sm font-bold text-white">Thử lại</button>
            </div>
          </div>
        ) : (
          <>
            {/* Thế giới dọc: mây ở trên, mặt đất ở dưới */}
            <div ref={scrollerRef} className="absolute inset-0 overflow-y-auto overflow-x-hidden overscroll-contain">
              <div className="relative flex min-h-full flex-col justify-end bg-gradient-to-b from-[#0284c7] via-[#38bdf8] to-[#bae6fd] pt-28">
                <DriftCloud className="sky-drift-a" />
                <DriftCloud className="sky-drift-b" />
                <Beanstalk />
                <SceneArt name="island-mill" className="sky-bob absolute right-[3%] top-24 hidden w-44 xl:block" />

                <div className="relative z-[2] flex flex-col gap-6 pb-6">
                  <CloudFloor title="Tầng Thần Thoại" pet="pet-corgi" slots={[4, 5, 6, 7]} plots={farm.plots} busySlots={busySlots} floatFx={floatFx} targets={drag ? [4, 5, 6, 7].filter((slot) => isTarget(drag.tool, slot)) : []} marked={marked} markedCrop={drag?.tool.kind === 'seed' ? drag.tool.crop : null} onPotTap={onPotTap} />
                  <CloudFloor title="Tầng Bồng Bềnh" pet="pet-cat" slots={[0, 1, 2, 3]} plots={farm.plots} busySlots={busySlots} floatFx={floatFx} targets={drag ? [0, 1, 2, 3].filter((slot) => isTarget(drag.tool, slot)) : []} marked={marked} markedCrop={drag?.tool.kind === 'seed' ? drag.tool.crop : null} onPotTap={onPotTap} />
                </div>

                {/* Mặt đất */}
                <section aria-label="Mặt đất" className="relative z-[3] h-[400px] shrink-0 sm:h-[500px]">
                  <div className="absolute inset-x-0 bottom-0 top-16 rounded-t-[50%_70px] border-t-8 border-[#7ccf3a] bg-gradient-to-b from-[#8fdc4a] via-[#5fb533] to-[#3f8f2a]" />
                  <button type="button" onClick={() => scrollerRef.current?.scrollTo({ top: 0, behavior: 'smooth' })} className="absolute left-1/2 top-0 z-[4] flex min-h-11 -translate-x-1/2 items-center gap-1 whitespace-nowrap rounded-full border-2 border-[#7c3f12] bg-[#fff4d9] px-3 text-xs font-extrabold text-[#3b2410] shadow-lg">
                    <ArrowUp className="h-4 w-4" />Lướt lên vườn mây
                  </button>
                  <SceneArt name="tree-pink" className="absolute left-[2%] top-[14%] w-[20%] max-w-[170px]" />
                  <SceneArt name="tree-apple" className="absolute right-[2%] top-[14%] w-[20%] max-w-[170px]" />
                  <SceneArt name="house" className="absolute left-1/2 top-[13%] z-[1] w-[48%] max-w-[400px] -translate-x-1/2 lg:left-[56%] lg:w-[30%]" />
                  <Building name="barn" label="Nhà kho" className="bottom-[27%] left-[3%] w-[32%] max-w-[270px]" onClick={() => setSheet({ kind: 'inventory' })} />
                  <Building name="shop" label="Đơn hàng" ariaLabel={`Đơn hàng, ${fulfillableCount} đơn có thể giao`} badge={fulfillableCount} className="bottom-[27%] right-[3%] w-[32%] max-w-[270px]" onClick={() => setSheet({ kind: 'orders' })} />
                  {onNavigate && <Building name="well" label="Giếng từ vựng" ariaLabel="Giếng từ vựng, học để tưới cây" className="bottom-[26%] left-1/2 w-[20%] max-w-[150px] -translate-x-1/2 lg:bottom-[24%] lg:left-[27%] lg:w-[12%] lg:translate-x-0" onClick={() => onNavigate('flashcards')} />}
                </section>
              </div>
            </div>

            {hint && (
              <div className="absolute left-1/2 top-[4.25rem] z-20 w-max max-w-[calc(100%-1.5rem)] -translate-x-1/2 max-sm:top-[6.75rem]">
                {hintAction ? (
                  <button type="button" onClick={hintAction} className="min-h-11 rounded-2xl border-2 border-[#7c3f12] bg-[#fff4d9] px-4 py-2 text-sm font-extrabold text-[#3b2410] shadow-lg">{hint.text} →</button>
                ) : (
                  <p className="rounded-2xl border-2 border-[#7c3f12] bg-[#fff4d9] px-4 py-2 text-sm font-extrabold text-[#3b2410] shadow-lg">{hint.text}</p>
                )}
              </div>
            )}

            {/* Công cụ: cầm và kéo vào chậu */}
            <div className="absolute inset-x-0 bottom-3 z-20 flex flex-col items-center gap-2 px-2">
              {trayOpen && (
                <div role="group" aria-label="Khay hạt giống, giữ và kéo vào chậu trống" className="flex max-w-full gap-1.5 overflow-x-auto rounded-2xl border-4 border-[#a65a1e] bg-[#fff4d9] p-1.5 shadow-xl">
                  {Object.entries(farm.cropCatalog).map(([id, def]) => (
                    <button
                      key={id}
                      type="button"
                      aria-label={`Hạt ${cropOf(id).name}, cần ${def.words_needed} từ`}
                      onPointerDown={(e) => startDrag({ kind: 'seed', crop: id }, e)}
                      onKeyDown={(e) => {
                        if (e.key !== 'Enter' && e.key !== ' ') return;
                        e.preventDefault();
                        const empty = [0, 1, 2, 3, 4, 5, 6, 7].filter((slot) => isTarget({ kind: 'seed', crop: id }, slot))[0];
                        if (empty !== undefined) void runDragAction({ kind: 'seed', crop: id }, [empty]);
                      }}
                      style={{ touchAction: 'none' }}
                      className="flex w-14 shrink-0 cursor-grab select-none flex-col items-center rounded-xl border border-[#e8b66c] bg-white/70 p-1 active:cursor-grabbing sm:w-16"
                    >
                      <CropArt crop={id} level={2} className="pointer-events-none h-9 sm:h-11" />
                      <span className="text-xs font-extrabold text-[#3b2410]">{def.words_needed} từ</span>
                    </button>
                  ))}
                </div>
              )}
              <nav aria-label="Công cụ nông trại" className="flex gap-2 rounded-3xl bg-[#3b2410]/85 p-2 shadow-xl">
                <button type="button" aria-expanded={trayOpen} onClick={() => setTrayOpen((v) => !v)} className={`flex h-16 w-24 flex-col items-center justify-center gap-0.5 rounded-2xl border-b-4 border-emerald-800 text-xs font-extrabold text-white transition-transform hover:-translate-y-0.5 ${trayOpen ? 'bg-emerald-800' : 'bg-emerald-600'}`}>
                  <CropArt crop="herbs" level={0} className="pointer-events-none h-8" />Hạt giống
                </button>
                <button type="button" aria-label="Giỏ thu hoạch, giữ và kéo qua cây đã chín" onPointerDown={(e) => startDrag({ kind: 'harvest' }, e)} style={{ touchAction: 'none' }} className="flex h-16 w-24 cursor-grab select-none flex-col items-center justify-center gap-0.5 rounded-2xl border-b-4 border-amber-600 bg-amber-400 text-xs font-extrabold text-[#3b2410] transition-transform hover:-translate-y-0.5">
                  <GameIcon name="basket" className="pointer-events-none h-8 w-8" />Thu hoạch
                </button>
              </nav>
            </div>

            {drag && (
              <div aria-hidden="true" className="pointer-events-none fixed z-[70] h-16 w-16 -translate-x-1/2 -translate-y-1/2 drop-shadow-xl" style={{ left: drag.x, top: drag.y }}>
                {drag.tool.kind === 'seed' ? <CropArt crop={drag.tool.crop} level={0} className="h-full w-full" /> : <GameIcon name="basket" className="h-full w-full" />}
              </div>
            )}
          </>
        )}
      </div>

      {farm && sheet?.kind === 'plant' && (
        <SheetFrame title={`Gieo hạt vào ô ${sheet.slot + 1}`} onClose={() => setSheet(null)}>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {Object.entries(farm.cropCatalog).map(([id, def]) => (
              <button key={id} type="button" onClick={() => void handlePlant(sheet.slot, id)} className="flex flex-col items-center gap-1 rounded-2xl border border-emerald-300 bg-emerald-50 p-3 transition-colors hover:bg-emerald-100">
                <CropArt crop={id} level={2} className="h-14" />
                <span className="text-center text-xs font-bold">{cropOf(id).name}</span>
                <span className="text-xs text-emerald-800">Cần {def.words_needed} từ</span>
              </button>
            ))}
          </div>
        </SheetFrame>
      )}

      {sheet?.kind === 'water' && (
        <SheetFrame title={cropOf(sheet.plot.crop).name} onClose={() => setSheet(null)}>
          <p className="mb-2 text-sm font-semibold">Tiến độ: {sheet.plot.waterCount}/{sheet.plot.requiredWater} từ vựng</p>
          <div className="mb-4 h-2 overflow-hidden rounded-full bg-sky-100">
            <div className="h-full rounded-full bg-sky-500" style={{ width: `${Math.min((sheet.plot.waterCount / sheet.plot.requiredWater) * 100, 100)}%` }} />
          </div>
          <p className="mb-4 text-sm text-[#5b4023]">Học Flashcard hoặc làm Quiz để tưới cây. Nước được cộng khi bạn hoàn thành phiên học và tưới cho cây gần chín nhất.</p>
          {onNavigate && (
            <div className="grid grid-cols-2 gap-2">
              <button type="button" onClick={() => onNavigate('flashcards')} className="flex items-center justify-center gap-2 rounded-xl bg-sky-700 px-3 py-2.5 text-sm font-bold text-white hover:bg-sky-800"><BookOpen className="h-4 w-4" />Flashcard</button>
              <button type="button" onClick={() => onNavigate('quiz')} className="rounded-xl border border-sky-700 px-3 py-2.5 text-sm font-bold text-sky-700 hover:bg-sky-50">Làm Quiz</button>
            </div>
          )}
        </SheetFrame>
      )}

      {farm && sheet?.kind === 'orders' && (
        <SheetFrame title="Đơn Hàng Phù Thủy" onClose={() => setSheet(null)}>
          {farm.pendingOrders.length === 0 ? (
            <p className="py-6 text-center text-sm text-[#5b4023]">Chưa có đơn hàng nào.</p>
          ) : (
            <ul className="flex flex-col gap-3">
              {farm.pendingOrders.map((order) => {
                const ok = canFulfill(order, farm.inventory);
                return (
                  <li key={order.id} className={`flex items-center justify-between gap-3 rounded-2xl border p-3 ${ok ? 'border-emerald-300 bg-emerald-50' : 'border-[#e8b66c] bg-white/60'}`}>
                    <div className="flex min-w-0 flex-wrap gap-1.5">
                      {order.items.map((item) => {
                        const have = farm.inventory[item.type] ?? 0;
                        return (
                          <span key={item.type} title={cropOf(item.type).name} className={`rounded-lg border px-2 py-1 text-xs font-bold ${have >= item.qty ? 'border-emerald-400 text-emerald-700' : 'border-[#c9a26b] text-[#5b4023]'}`}>
                            <CropArt crop={item.type} level={2} className="mr-1 inline h-6 w-6" />{have}/{item.qty}
                          </span>
                        );
                      })}
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1">
                      <span className="text-xs font-bold text-amber-700">+{order.reward} xu · +{order.rewardXp} XP</span>
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
            <p className="py-6 text-center text-sm text-[#5b4023]">Kho đang trống. Hãy thu hoạch cây trồng!</p>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
              {inventoryItems.map(([id, qty]) => (
                <div key={id} className="flex flex-col items-center rounded-2xl border border-[#e8b66c] bg-white/60 p-3">
                  <CropArt crop={id} level={2} className="h-14" />
                  <span className="text-center text-xs font-bold">{cropOf(id).name}</span>
                  <span className="text-xs text-[#5b4023]">Số lượng: {qty}</span>
                </div>
              ))}
            </div>
          )}
        </SheetFrame>
      )}
    </div>
  );
};
