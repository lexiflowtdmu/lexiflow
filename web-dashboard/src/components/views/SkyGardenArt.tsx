import React from 'react';

// Keep this geometry in sync with lib/presentation/widgets/sky_garden_art.dart.
// All coordinates live in a 64x64 box.
type Shape = [cx: number, cy: number, rx: number, ry: number, color: string];

const CROP_SHAPES: Record<string, { shapes: Shape[]; face: [number, number] }> = {
  corn: { shapes: [[24, 30, 5, 14, '#15803D'], [40, 30, 5, 14, '#15803D'], [32, 24, 8, 16, '#FACC15']], face: [32, 25] },
  tomato: { shapes: [[32, 26, 14, 13, '#EF4444']], face: [32, 27] },
  flower: {
    shapes: [[32, 13, 7, 8, '#F472B6'], [43, 21, 8, 7, '#F472B6'], [39, 34, 7, 8, '#F472B6'], [25, 34, 7, 8, '#F472B6'], [21, 21, 8, 7, '#F472B6'], [32, 24, 8, 8, '#FDE047']],
    face: [32, 24],
  },
  apple: { shapes: [[32, 27, 14, 14, '#DC2626'], [39, 11, 5, 3, '#22C55E']], face: [32, 28] },
  herbs: { shapes: [[20, 28, 8, 11, '#16A34A'], [44, 28, 8, 11, '#16A34A'], [32, 22, 11, 15, '#22C55E']], face: [32, 24] },
  blueberry: { shapes: [[21, 32, 9, 9, '#6366F1'], [43, 32, 9, 9, '#4F46E5'], [32, 21, 12, 12, '#4338CA']], face: [32, 22] },
};

/** Growth level: 0 = sprout (under 34%), 1 = growing, 2 = ripe. */
export function growthLevel(progress: number, needed: number, ripe: boolean): 0 | 1 | 2 {
  if (ripe) return 2;
  return needed > 0 && progress / needed >= 0.34 ? 1 : 0;
}

export const CropArt: React.FC<{ crop?: string; level: 0 | 1 | 2; className?: string }> = ({ crop, level, className }) => {
  const def = CROP_SHAPES[crop ?? ''] ?? CROP_SHAPES.herbs;
  const leafY = level === 0 ? 46 : 50;
  const scale = level === 2 ? 1 : 0.6;
  return (
    <svg viewBox="0 0 64 64" aria-hidden="true" className={className}>
      <path d={level === 0 ? 'M32 64 L32 44' : 'M32 64 L32 28'} stroke="#15803D" strokeWidth="4" strokeLinecap="round" />
      <ellipse cx="21" cy={leafY} rx="11" ry="5" fill="#22C55E" transform={`rotate(25 21 ${leafY})`} />
      <ellipse cx="43" cy={leafY} rx="11" ry="5" fill="#16A34A" transform={`rotate(-25 43 ${leafY})`} />
      {level > 0 && (
        <g transform={`translate(32 26) scale(${scale}) translate(-32 -26)`}>
          {def.shapes.map(([cx, cy, rx, ry, color], i) => (
            <g key={i}>
              <ellipse cx={cx} cy={cy} rx={rx} ry={ry} fill={color} />
              <ellipse cx={cx - rx * 0.35} cy={cy - ry * 0.4} rx={rx * 0.28} ry={ry * 0.22} fill="#FFFFFF" opacity="0.4" />
            </g>
          ))}
          <circle cx={def.face[0] - 4} cy={def.face[1] - 1} r="1.6" fill="#0C2D48" />
          <circle cx={def.face[0] + 4} cy={def.face[1] - 1} r="1.6" fill="#0C2D48" />
          <path d={`M${def.face[0] - 3} ${def.face[1] + 3} Q${def.face[0]} ${def.face[1] + 6} ${def.face[0] + 3} ${def.face[1] + 3}`} fill="none" stroke="#0C2D48" strokeWidth="1.5" strokeLinecap="round" />
        </g>
      )}
    </svg>
  );
};

const POT_COLORS: [string, string, string][] = [
  ['#67E8F9', '#0E7490', '#FFFFFF'],
  ['#FDBA74', '#C2410C', '#FEF08A'],
  ['#86EFAC', '#15803D', '#FFFFFF'],
  ['#D97706', '#78350F', '#FEF3C7'],
];

export const PotArt: React.FC<{ variant: number; className?: string }> = ({ variant, className }) => {
  const [top, bottom, rim] = POT_COLORS[variant % POT_COLORS.length];
  const id = `sky-pot-${variant % POT_COLORS.length}`;
  return (
    <svg viewBox="0 0 64 44" aria-hidden="true" className={className}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={top} />
          <stop offset="1" stopColor={bottom} />
        </linearGradient>
      </defs>
      <path d="M8 10 H56 L50 38 Q49 43 44 43 H20 Q15 43 14 38 Z" fill={`url(#${id})`} stroke={rim} strokeWidth="2" />
      <rect x="4" y="3" width="56" height="10" rx="4" fill={`url(#${id})`} stroke={rim} strokeWidth="2" />
      <rect x="11" y="6" width="42" height="4" rx="2" fill="#000000" opacity="0.25" />
      <path d="M17 17 L20 35" stroke="#FFFFFF" strokeWidth="3" strokeLinecap="round" opacity="0.45" />
    </svg>
  );
};

export const CloudPlatform: React.FC = () => (
  <svg
    viewBox="0 0 400 80"
    preserveAspectRatio="none"
    aria-hidden="true"
    className="absolute inset-x-0 bottom-6 h-20 w-full drop-shadow-[0_12px_14px_rgba(3,105,161,0.35)]"
  >
    <path d="M 12 62 Q 100 50 200 55 Q 300 50 388 62 Q 396 78 370 80 L 30 80 Q 4 78 12 62 Z" fill="#7DD3FC" opacity="0.6" />
    <path d="M 15 45 Q 30 10 75 30 Q 120 0 170 28 Q 230 -5 290 25 Q 345 5 385 45 Q 400 70 380 75 L 20 75 Q 0 70 15 45 Z" fill="#FFFFFF" />
    <path d="M 20 70 Q 200 52 380 70 L 380 75 L 20 75 Z" fill="#BAE6FD" />
  </svg>
);

export const Beanstalk: React.FC = () => (
  <svg viewBox="0 0 60 400" preserveAspectRatio="none" aria-hidden="true" className="pointer-events-none absolute inset-y-0 left-0 h-full w-8 sm:w-16">
    <path d="M 25 400 C 8 280 45 140 18 0" fill="none" stroke="#15803D" strokeWidth="11" strokeLinecap="round" />
    <path d="M 25 400 C 8 280 45 140 18 0" fill="none" stroke="#22C55E" strokeWidth="5" strokeLinecap="round" />
    <ellipse cx="42" cy="248" rx="15" ry="7" fill="#22C55E" />
    <ellipse cx="14" cy="128" rx="13" ry="6" fill="#16A34A" />
    <ellipse cx="40" cy="60" rx="13" ry="6" fill="#22C55E" />
  </svg>
);

export const DriftCloud: React.FC<{ className?: string }> = ({ className }) => (
  <svg viewBox="0 0 120 50" aria-hidden="true" className={`pointer-events-none absolute ${className ?? ''}`}>
    <path d="M10 42 Q0 28 18 26 Q22 8 44 16 Q60 0 78 16 Q104 12 104 30 Q118 34 108 42 Z" fill="#FFFFFF" />
  </svg>
);
