// Fangcun Characters - SVG Components
// Based on confirmed reference: blue woodblock-print outlines, white bodies, soft orange accents

const FC_BLUE = '#2B5EA7';
const FC_ORANGE = '#E07B4F';
const FC_BLUE_LIGHT = '#94B3D7';

// Grain texture filter (shared)
const grainFilter = `
<filter id="grain" x="0" y="0" width="100%" height="100%">
  <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch" result="noise"/>
  <feColorMatrix type="saturate" values="0" in="noise" result="gray"/>
  <feBlend in="SourceGraphic" in2="gray" mode="multiply" result="blend"/>
  <feComponentTransfer in="blend">
    <feFuncA type="linear" slope="0.4" intercept="0.6"/>
  </feComponentTransfer>
</filter>`;

// Cat - sitting, content/calm
function catSitting(size = 80) {
  return `<svg width="${size}" height="${size}" viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>${grainFilter}</defs>
  <g filter="url(#grain)">
    <!-- Body -->
    <ellipse cx="52" cy="78" rx="28" ry="24" fill="white" stroke="${FC_BLUE}" stroke-width="4" stroke-linecap="round"/>
    <!-- Head -->
    <circle cx="52" cy="48" r="22" fill="white" stroke="${FC_BLUE}" stroke-width="4"/>
    <!-- Left ear -->
    <path d="M36 32 L30 14 L44 28" fill="white" stroke="${FC_BLUE}" stroke-width="4" stroke-linejoin="round"/>
    <!-- Right ear (orange) -->
    <path d="M68 32 L74 14 L60 28" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="4" stroke-linejoin="round"/>
    <!-- Eyes -->
    <circle cx="43" cy="46" r="3" fill="${FC_BLUE}"/>
    <circle cx="61" cy="46" r="3" fill="${FC_BLUE}"/>
    <!-- Whiskers -->
    <line x1="28" y1="50" x2="38" y2="50" stroke="${FC_BLUE}" stroke-width="2" stroke-linecap="round"/>
    <line x1="28" y1="54" x2="37" y2="53" stroke="${FC_BLUE}" stroke-width="2" stroke-linecap="round"/>
    <line x1="66" y1="50" x2="76" y2="50" stroke="${FC_BLUE}" stroke-width="2" stroke-linecap="round"/>
    <line x1="67" y1="53" x2="76" y2="54" stroke="${FC_BLUE}" stroke-width="2" stroke-linecap="round"/>
    <!-- Nose/mouth -->
    <circle cx="52" cy="52" r="1.5" fill="${FC_BLUE}"/>
    <path d="M49 55 Q52 58 55 55" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- Tail -->
    <path d="M24 70 Q12 55 18 42" stroke="${FC_BLUE}" stroke-width="4" fill="none" stroke-linecap="round"/>
    <!-- Front paws -->
    <ellipse cx="40" cy="96" rx="8" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
    <ellipse cx="64" cy="96" rx="8" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
  </g>
</svg>`;
}

// Cat - small/icon version
function catIcon(size = 32) {
  return `<svg width="${size}" height="${size}" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="26" r="14" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
  <path d="M14 16 L11 6 L18 14" fill="white" stroke="${FC_BLUE}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M34 16 L37 6 L30 14" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="2.5" stroke-linejoin="round"/>
  <circle cx="19" cy="24" r="2" fill="${FC_BLUE}"/>
  <circle cx="29" cy="24" r="2" fill="${FC_BLUE}"/>
  <path d="M22 29 Q24 31 26 29" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
</svg>`;
}

// Dog - lying down, relaxed
function dogLying(size = 100) {
  return `<svg width="${size}" height="${size * 0.6}" viewBox="0 0 160 96" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>${grainFilter}</defs>
  <g filter="url(#grain)">
    <!-- Body -->
    <ellipse cx="90" cy="58" rx="50" ry="26" fill="white" stroke="${FC_BLUE}" stroke-width="4" stroke-linecap="round"/>
    <!-- Head -->
    <circle cx="48" cy="42" r="22" fill="white" stroke="${FC_BLUE}" stroke-width="4"/>
    <!-- Ear left -->
    <path d="M30 30 Q22 20 28 40" fill="white" stroke="${FC_BLUE}" stroke-width="3.5" stroke-linecap="round"/>
    <!-- Ear right (orange patch) -->
    <ellipse cx="62" cy="28" rx="10" ry="8" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="3.5" transform="rotate(-15 62 28)"/>
    <!-- Eyes -->
    <circle cx="40" cy="40" r="3" fill="${FC_BLUE}"/>
    <circle cx="56" cy="40" r="3" fill="${FC_BLUE}"/>
    <!-- Nose/mouth -->
    <ellipse cx="48" cy="48" rx="4" ry="3" fill="${FC_BLUE}" opacity="0.8"/>
    <path d="M44 51 Q48 55 52 51" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- Body patch -->
    <ellipse cx="105" cy="50" rx="16" ry="12" fill="${FC_ORANGE}" opacity="0.6"/>
    <!-- Tail -->
    <path d="M138 48 Q148 38 144 52" stroke="${FC_BLUE}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <!-- Front paws -->
    <ellipse cx="60" cy="80" rx="10" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
    <ellipse cx="80" cy="82" rx="10" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
  </g>
</svg>`;
}

// Dog - small/icon version
function dogIcon(size = 32) {
  return `<svg width="${size}" height="${size}" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="26" r="14" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
  <path d="M13 20 Q9 12 14 22" fill="white" stroke="${FC_BLUE}" stroke-width="2.5" stroke-linecap="round"/>
  <ellipse cx="32" cy="16" rx="6" ry="5" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="2.5" transform="rotate(-10 32 16)"/>
  <circle cx="19" cy="24" r="2" fill="${FC_BLUE}"/>
  <circle cx="29" cy="24" r="2" fill="${FC_BLUE}"/>
  <ellipse cx="24" cy="29" rx="3" ry="2" fill="${FC_BLUE}" opacity="0.7"/>
</svg>`;
}

// Cat + Dog together (compact, for headers)
function catDogPair(width = 140) {
  const h = width * 0.55;
  return `<svg width="${width}" height="${h}" viewBox="0 0 200 110" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>${grainFilter}</defs>
  <g filter="url(#grain)">
    <!-- Cat sitting (left) -->
    <g transform="translate(15, 10)">
      <ellipse cx="40" cy="68" rx="24" ry="20" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
      <circle cx="40" cy="40" r="19" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
      <path d="M27 27 L22 12 L34 24" fill="white" stroke="${FC_BLUE}" stroke-width="3" stroke-linejoin="round"/>
      <path d="M53 27 L58 12 L46 24" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="3" stroke-linejoin="round"/>
      <circle cx="33" cy="38" r="2.5" fill="${FC_BLUE}"/>
      <circle cx="47" cy="38" r="2.5" fill="${FC_BLUE}"/>
      <line x1="22" y1="42" x2="29" y2="42" stroke="${FC_BLUE}" stroke-width="1.5" stroke-linecap="round"/>
      <line x1="51" y1="42" x2="58" y2="42" stroke="${FC_BLUE}" stroke-width="1.5" stroke-linecap="round"/>
      <path d="M37 46 Q40 49 43 46" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
      <path d="M18 60 Q8 48 13 36" stroke="${FC_BLUE}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
      <ellipse cx="30" cy="84" rx="7" ry="4" fill="white" stroke="${FC_BLUE}" stroke-width="2.5"/>
      <ellipse cx="50" cy="84" rx="7" ry="4" fill="white" stroke="${FC_BLUE}" stroke-width="2.5"/>
    </g>
    <!-- Dog lying (right) -->
    <g transform="translate(85, 24)">
      <ellipse cx="50" cy="44" rx="42" ry="22" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
      <circle cx="22" cy="30" r="18" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
      <path d="M8 20 Q2 12 7 28" fill="white" stroke="${FC_BLUE}" stroke-width="3" stroke-linecap="round"/>
      <ellipse cx="35" cy="18" rx="8" ry="6" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="3" transform="rotate(-10 35 18)"/>
      <circle cx="16" cy="28" r="2.5" fill="${FC_BLUE}"/>
      <circle cx="28" cy="28" r="2.5" fill="${FC_BLUE}"/>
      <ellipse cx="22" cy="34" rx="3" ry="2" fill="${FC_BLUE}" opacity="0.7"/>
      <ellipse cx="62" cy="38" rx="12" ry="9" fill="${FC_ORANGE}" opacity="0.5"/>
      <path d="M90 36 Q98 28 96 40" stroke="${FC_BLUE}" stroke-width="3" fill="none" stroke-linecap="round"/>
      <ellipse cx="32" cy="62" rx="8" ry="4" fill="white" stroke="${FC_BLUE}" stroke-width="2.5"/>
      <ellipse cx="48" cy="64" rx="8" ry="4" fill="white" stroke="${FC_BLUE}" stroke-width="2.5"/>
    </g>
  </g>
</svg>`;
}

// Cat breathing - expanded belly (for breathing exercise)
function catBreathing(size = 160, phase = 'inhale') {
  const bellyRx = phase === 'inhale' ? 32 : 26;
  const bellyRy = phase === 'inhale' ? 28 : 22;
  return `<svg width="${size}" height="${size}" viewBox="0 0 140 140" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>${grainFilter}</defs>
  <g filter="url(#grain)" transform="translate(10, 10)">
    <!-- Body with breathing belly -->
    <ellipse cx="60" cy="82" rx="${bellyRx}" ry="${bellyRy}" fill="white" stroke="${FC_BLUE}" stroke-width="4" stroke-linecap="round"/>
    <!-- Head -->
    <circle cx="60" cy="46" r="24" fill="white" stroke="${FC_BLUE}" stroke-width="4"/>
    <!-- Ears -->
    <path d="M42 28 L36 8 L52 24" fill="white" stroke="${FC_BLUE}" stroke-width="3.5" stroke-linejoin="round"/>
    <path d="M78 28 L84 8 L70 24" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="3.5" stroke-linejoin="round"/>
    <!-- Closed eyes (peaceful) -->
    <path d="M48 44 Q52 40 56 44" stroke="${FC_BLUE}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <path d="M64 44 Q68 40 72 44" stroke="${FC_BLUE}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <!-- Nose/mouth -->
    <path d="M57 52 Q60 55 63 52" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- Tail -->
    <path d="M30 72 Q16 58 22 44" stroke="${FC_BLUE}" stroke-width="4" fill="none" stroke-linecap="round"/>
    <!-- Paws -->
    <ellipse cx="46" cy="104" rx="9" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
    <ellipse cx="74" cy="104" rx="9" ry="5" fill="white" stroke="${FC_BLUE}" stroke-width="3"/>
  </g>
</svg>`;
}

// Cat sleepy (for NSDR/rest)
function catSleepy(size = 80) {
  return `<svg width="${size}" height="${size * 0.6}" viewBox="0 0 140 84" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>${grainFilter}</defs>
  <g filter="url(#grain)">
    <ellipse cx="70" cy="52" rx="48" ry="22" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
    <circle cx="36" cy="36" r="18" fill="white" stroke="${FC_BLUE}" stroke-width="3.5"/>
    <path d="M22 24 L18 10 L30 22" fill="white" stroke="${FC_BLUE}" stroke-width="3" stroke-linejoin="round"/>
    <path d="M50 24 L54 10 L42 22" fill="${FC_ORANGE}" stroke="${FC_BLUE}" stroke-width="3" stroke-linejoin="round"/>
    <!-- Closed eyes -->
    <path d="M28 34 Q32 31 36 34" stroke="${FC_BLUE}" stroke-width="2" fill="none" stroke-linecap="round"/>
    <path d="M38 34 Q42 31 46 34" stroke="${FC_BLUE}" stroke-width="2" fill="none" stroke-linecap="round"/>
    <path d="M33 40 Q36 42 39 40" stroke="${FC_BLUE}" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <path d="M116 42 Q124 34 122 46" stroke="${FC_BLUE}" stroke-width="3" fill="none" stroke-linecap="round"/>
    <!-- Zzz -->
    <text x="108" y="24" font-size="14" fill="${FC_BLUE_LIGHT}" font-weight="600" opacity="0.6">z</text>
    <text x="116" y="16" font-size="11" fill="${FC_BLUE_LIGHT}" font-weight="600" opacity="0.4">z</text>
  </g>
</svg>`;
}
