/**
 * The accent engine — a port of ThemeStore's palette derivation. The user
 * picks ONE colour and the engine derives the full supporting palette for
 * both appearances, written as CSS variables on <html>.
 *
 * · Signature (LexIndia Violet, the default): the hand-tuned colourful mix.
 * · Monochrome (any custom colour): every decorative token re-derives as
 *   shades of the chosen hue. Backgrounds never change.
 */

export interface AccentPreset {
  id: string;
  name: string;
  hex: number;
}

export const SIGNATURE_HEX = 0x9853f5;

export const ACCENT_PRESETS: AccentPreset[] = [
  { id: "violet", name: "LexIndia Violet", hex: 0x9853f5 },
  { id: "indigo", name: "Royal Indigo", hex: 0x4f46e5 },
  { id: "peacock", name: "Peacock Teal", hex: 0x0d9488 },
  { id: "forest", name: "Forest Green", hex: 0x15803d },
  { id: "marigold", name: "Marigold", hex: 0xd97706 },
  { id: "rose", name: "Rose", hex: 0xe11d48 },
  { id: "ocean", name: "Deep Ocean", hex: 0x0369a1 },
  { id: "earth", name: "Earthen Brown", hex: 0x92400e },
];

type Rgb = { r: number; g: number; b: number };

export const hexToCss = (hex: number): string => `#${hex.toString(16).padStart(6, "0")}`;

export const cssToHex = (css: string): number | null => {
  const match = /^#?([0-9a-f]{6})$/i.exec(css.trim());
  return match ? parseInt(match[1], 16) : null;
};

const hexToRgb = (hex: number): Rgb => ({ r: (hex >> 16) & 0xff, g: (hex >> 8) & 0xff, b: hex & 0xff });

const rgbToCss = ({ r, g, b }: Rgb): string =>
  `#${[r, g, b].map((channel) => Math.round(Math.min(Math.max(channel, 0), 255)).toString(16).padStart(2, "0")).join("")}`;

const clamp01 = (value: number) => Math.min(Math.max(value, 0), 1);

/** Hue 0…1, saturation 0…1, brightness 0…1 — matches UIColor's HSB space. */
function rgbToHsb({ r, g, b }: Rgb): { h: number; s: number; v: number } {
  const rn = r / 255;
  const gn = g / 255;
  const bn = b / 255;
  const max = Math.max(rn, gn, bn);
  const min = Math.min(rn, gn, bn);
  const delta = max - min;
  let h = 0;
  if (delta > 0) {
    if (max === rn) h = ((gn - bn) / delta) % 6;
    else if (max === gn) h = (bn - rn) / delta + 2;
    else h = (rn - gn) / delta + 4;
    h /= 6;
    if (h < 0) h += 1;
  }
  return { h, s: max === 0 ? 0 : delta / max, v: max };
}

function hsb(h: number, s: number, v: number): Rgb {
  const sat = clamp01(s);
  const val = clamp01(v);
  const i = Math.floor(h * 6);
  const f = h * 6 - i;
  const p = val * (1 - sat);
  const q = val * (1 - f * sat);
  const t = val * (1 - (1 - f) * sat);
  let r = 0;
  let g = 0;
  let b = 0;
  switch (i % 6) {
    case 0:
      [r, g, b] = [val, t, p];
      break;
    case 1:
      [r, g, b] = [q, val, p];
      break;
    case 2:
      [r, g, b] = [p, val, t];
      break;
    case 3:
      [r, g, b] = [p, q, val];
      break;
    case 4:
      [r, g, b] = [t, p, val];
      break;
    default:
      [r, g, b] = [val, p, q];
  }
  return { r: r * 255, g: g * 255, b: b * 255 };
}

const luminance = ({ r, g, b }: Rgb): number => (0.299 * r + 0.587 * g + 0.114 * b) / 255;

export interface PalettePair {
  light: string;
  dark: string;
}

export interface DerivedPalette {
  brand: PalettePair;
  brandDeep: PalettePair;
  brandSoft: PalettePair;
  onBrand: PalettePair;
  saffron: PalettePair;
  saffronDeep: PalettePair;
  saffronSoft: PalettePair;
  blueSoft: PalettePair;
  blueDeep: PalettePair;
  mint: PalettePair;
  mintDeep: PalettePair;
  pastels: { fill: PalettePair; tone: PalettePair }[];
}

const pair = (light: number, dark: number): PalettePair => ({ light: hexToCss(light), dark: hexToCss(dark) });

/** The hand-tuned colourful LexIndia mix (default). */
export const signaturePalette: DerivedPalette = {
  brand: pair(0x9853f5, 0xa874ff),
  brandDeep: pair(0x7c3aed, 0x9853f5),
  brandSoft: pair(0xe9d5fe, 0x2c2145),
  onBrand: pair(0xffffff, 0x17102a),
  saffron: pair(0xff9b7b, 0xff9b7b),
  saffronDeep: pair(0xc2410c, 0xffb399),
  saffronSoft: pair(0xffdfbc, 0x38221a),
  blueSoft: pair(0xd3dcfe, 0x211e44),
  blueDeep: pair(0x3730a3, 0xb4beff),
  mint: pair(0xd2f0e0, 0x163227),
  mintDeep: pair(0x166534, 0x8fe6b4),
  pastels: [
    { fill: pair(0xe6d0fe, 0x2b2052), tone: pair(0x4c1d95, 0xd9c7ff) },
    { fill: pair(0xccd6fe, 0x1f2350), tone: pair(0x3730a3, 0xb9c4ff) },
    { fill: pair(0xc8ecd9, 0x143528), tone: pair(0x166534, 0x93e8be) },
    { fill: pair(0xffdcb0, 0x3d2517), tone: pair(0x9a3412, 0xffc9a6) },
    { fill: pair(0xffbdd0, 0x421b2a), tone: pair(0x9f1239, 0xffafc7) },
    { fill: pair(0xf9c9e4, 0x3c1830), tone: pair(0x9d174d, 0xf5aedc) },
    { fill: pair(0xfbe45e, 0x38300e), tone: pair(0x854d0e, 0xf2e38e) },
    { fill: pair(0xc3a6ff, 0x33265a), tone: pair(0x3b1544, 0xcfb8ff) },
  ],
};

/**
 * Monochrome mode: every decorative token becomes a shade of the chosen
 * hue. Roles keep their contrast relationships so readability never drops.
 */
export function monochromePalette(hex: number): DerivedPalette {
  const { h: hue, s: sat, v: bri } = rgbToHsb(hexToRgb(hex));

  const famSat = sat < 0.12 ? sat : Math.min(Math.max(sat, 0.45), 1);
  const actionBri = Math.min(Math.max(bri, 0.34), 0.86);
  const light = hsb(hue, famSat, actionBri);
  const dark = hsb(hue, Math.max(famSat * 0.82, sat < 0.12 ? 0 : 0.3), Math.min(actionBri + 0.16, 1));

  const dyn = (l: Rgb, d: Rgb): PalettePair => ({ light: rgbToCss(l), dark: rgbToCss(d) });
  const tone = (satMul: number, brightness: number): Rgb => hsb(hue, famSat * satMul, brightness);
  const ink = hexToRgb(0x1e1b2e);
  const nightInk = hexToRgb(0x17102a);
  const white = { r: 255, g: 255, b: 255 };

  return {
    brand: dyn(light, dark),
    brandDeep: dyn(
      hsb(hue, Math.min(famSat * 1.05, 1), actionBri * 0.78),
      hsb(hue, famSat, Math.min(actionBri + 0.04, 0.9)),
    ),
    brandSoft: dyn(
      hsb(hue, Math.min(Math.max(famSat * 0.34, sat < 0.12 ? 0 : 0.1), 0.3), 0.97),
      hsb(hue, Math.min(famSat * 0.55, 0.55), 0.25),
    ),
    onBrand: dyn(luminance(light) > 0.62 ? ink : white, luminance(dark) > 0.62 ? nightInk : white),
    saffron: dyn(tone(0.62, Math.min(actionBri + 0.26, 0.97)), tone(0.52, 0.98)),
    saffronDeep: dyn(tone(1.05, Math.max(actionBri * 0.6, 0.3)), tone(0.42, 0.95)),
    saffronSoft: dyn(tone(0.32, 0.975), tone(0.55, 0.27)),
    blueSoft: dyn(tone(0.24, 0.965), tone(0.48, 0.235)),
    blueDeep: dyn(tone(1.1, Math.max(actionBri * 0.52, 0.26)), tone(0.38, 0.92)),
    mint: dyn(tone(0.16, 0.955), tone(0.42, 0.2)),
    mintDeep: dyn(tone(0.95, Math.max(actionBri * 0.46, 0.22)), tone(0.32, 0.88)),
    pastels: Array.from({ length: 8 }, (_, index) => {
      const step = index / 7;
      return {
        fill: dyn(
          hsb(hue, famSat * (0.15 + 0.3 * step), 0.975 - 0.085 * step),
          hsb(hue, famSat * (0.34 + 0.24 * step), 0.16 + 0.13 * step),
        ),
        tone: dyn(
          hsb(hue, Math.min(famSat * (1.15 - 0.3 * step), 1), 0.3 + 0.13 * step),
          hsb(hue, famSat * (0.46 - 0.14 * step), 0.97 - 0.09 * step),
        ),
      };
    }),
  };
}

/** Writes the palette for the active appearance onto <html>. */
export function applyPalette(palette: DerivedPalette, isDark: boolean): void {
  const root = document.documentElement.style;
  const side = isDark ? "dark" : "light";
  root.setProperty("--brand", palette.brand[side]);
  root.setProperty("--brand-deep", palette.brandDeep[side]);
  root.setProperty("--brand-soft", palette.brandSoft[side]);
  root.setProperty("--on-brand", palette.onBrand[side]);
  root.setProperty("--saffron", palette.saffron[side]);
  root.setProperty("--saffron-deep", palette.saffronDeep[side]);
  root.setProperty("--saffron-soft", palette.saffronSoft[side]);
  root.setProperty("--blue-soft", palette.blueSoft[side]);
  root.setProperty("--blue-deep", palette.blueDeep[side]);
  root.setProperty("--mint", palette.mint[side]);
  root.setProperty("--mint-deep", palette.mintDeep[side]);
  palette.pastels.forEach((pastel, index) => {
    root.setProperty(`--pastel-${index}-fill`, pastel.fill[side]);
    root.setProperty(`--pastel-${index}-tone`, pastel.tone[side]);
  });
}
