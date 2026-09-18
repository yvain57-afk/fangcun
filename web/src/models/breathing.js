// Timing is a provisional interaction model, not a prescribed clinical protocol.
export const SESSION_SECONDS = 300;
export const CYCLE_SECONDS = 12;
export const PHASES = [
  { id: 'inhale', label: '轻轻吸气', hint: '吸入一口，让呼吸慢下来', duration: 4, from: .64, to: .92 },
  { id: 'topup', label: '再补一小口', hint: '轻轻补吸，不必吸到满', duration: 1, from: .92, to: 1 },
  { id: 'exhale', label: '缓缓呼气', hint: '像叹一口气，慢慢松下来', duration: 7, from: 1, to: .64 },
];
export function phaseAt(seconds) {
  const elapsed = Math.max(0, Math.min(SESSION_SECONDS, seconds));
  let position = elapsed % CYCLE_SECONDS;
  let phase = PHASES[0];
  let phaseIndex = 0;
  for (let i = 0; i < PHASES.length; i++) {
    if (position < PHASES[i].duration) { phase = PHASES[i]; phaseIndex = i; break; }
    position -= PHASES[i].duration;
  }
  const fraction = position / phase.duration;
  const eased = (1 - Math.cos(Math.PI * fraction)) / 2;
  return { ...phase, phaseIndex, fraction, scale: phase.from + (phase.to - phase.from) * eased,
    cycle: Math.min(25, Math.floor(elapsed / CYCLE_SECONDS) + 1), complete: elapsed >= SESSION_SECONDS };
}
export function formatTime(seconds) {
  const value = Math.max(0, Math.ceil(seconds));
  return `${Math.floor(value / 60)}:${String(value % 60).padStart(2, '0')}`;
}
