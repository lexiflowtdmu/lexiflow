import React from 'react';

const asset = (name: string) => `${import.meta.env.BASE_URL}farm/${name}.png`;

const CROPS = new Set(['corn', 'tomato', 'flower', 'apple', 'herbs', 'blueberry']);

/** Growth level: 0 = sprout (under 34%), 1 = growing, 2 = ripe. */
export function growthLevel(progress: number, needed: number, ripe: boolean): 0 | 1 | 2 {
  if (ripe) return 2;
  return needed > 0 && progress / needed >= 0.34 ? 1 : 0;
}

export const GameIcon: React.FC<{ name: 'coin' | 'drop' | 'basket' | 'icon-orders' | 'icon-study' | 'icon-inventory'; className?: string }> = ({ name, className }) => (
  <img src={asset(name)} alt="" aria-hidden="true" draggable={false} className={`object-contain ${className ?? ''}`} />
);

export const CropArt: React.FC<{ crop?: string; level: 0 | 1 | 2; className?: string }> = ({ crop, level, className }) => (
  <img
    src={asset(`crop-${CROPS.has(crop ?? '') ? crop : 'herbs'}-${level}`)}
    alt=""
    aria-hidden="true"
    draggable={false}
    className={`object-contain object-bottom ${className ?? ''}`}
  />
);

export const PotArt: React.FC<{ variant: number; className?: string }> = ({ variant, className }) => (
  <img src={asset(`pot-${variant % 4}`)} alt="" aria-hidden="true" draggable={false} className={className} />
);

/** Cloud with a fence, shown at its drawn proportions so the fence does not look stretched. */
export const CloudPlatform: React.FC = () => (
  <img
    src={asset('cloud-fence')}
    alt=""
    aria-hidden="true"
    draggable={false}
    className="pointer-events-none absolute inset-0 h-full w-full object-fill drop-shadow-[0_14px_14px_rgba(3,105,161,0.35)]"
  />
);

export const SceneArt: React.FC<{ name: 'island-home' | 'island-mill' | 'pet-cat' | 'pet-corgi' | 'house' | 'barn' | 'well' | 'shop' | 'tree-apple' | 'tree-pink'; className?: string }> = ({ name, className }) => (
  <img src={asset(name)} alt="" aria-hidden="true" draggable={false} className={`pointer-events-none object-contain ${className ?? ''}`} />
);

/** Climbs the whole world: stacked, alternately flipped segments overlap so leaves hide the joins. */
export const Beanstalk: React.FC = () => (
  <div aria-hidden="true" className="pointer-events-none absolute bottom-16 left-0 top-10 z-[1] flex w-14 flex-col-reverse overflow-hidden sm:w-24 lg:w-32">
    {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
      <img key={i} src={asset('beanstalk')} alt="" draggable={false} className={`-mt-6 w-full shrink-0 ${i % 2 ? '-scale-x-100' : ''}`} />
    ))}
  </div>
);

export const DriftCloud: React.FC<{ className?: string }> = ({ className }) => (
  <img src={asset('cloud-small')} alt="" aria-hidden="true" draggable={false} className={`pointer-events-none absolute ${className ?? ''}`} />
);
