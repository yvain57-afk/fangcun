// Scene meaning is separate from drawing and from the health-data conclusion.
export function companionScene({ scene = 'home', mood = 'stable', paused = false, phase = 'inhale' } = {}) {
  if (scene === 'breathing') return { pose: paused ? 'pause' : 'breathe', gaze: 'closed', mouth: !paused && phase === 'exhale' ? 'exhale' : 'soft', label: paused ? '猫咪安静等你继续' : '猫咪跟着节拍轻轻呼吸' };
  if (scene === 'drink') return { pose: 'cup', gaze: 'cup', mouth: 'soft', label: '狗狗看着杯子，陪你记一笔' };
  if (scene === 'recorded') return { pose: 'acknowledge', gaze: 'cup', mouth: 'soft', label: '狗狗轻轻点头，记录已收到' };
  if (scene === 'complete') return { pose: 'touch', gaze: 'soft', mouth: 'soft', label: '猫狗轻碰爪，回应这段留给自己的时间' };
  if (scene === 'rest') return { pose: 'rest', gaze: 'closed', mouth: 'soft', label: '小狗趴下来休息，停在这里也可以' };
  if (scene === 'practice') return { pose: 'ready', gaze: 'closed', mouth: 'soft', label: '猫咪坐好，陪你留一口气' };
  if (mood === 'elevated') return { pose: 'support', gaze: 'soft', mouth: 'soft', label: '小狗收好前爪，安静陪你休息' };
  if (mood === 'insufficient') return { pose: 'curious', gaze: 'look', mouth: 'soft', label: '猫咪独自探身观察，等身体的线索' };
  return { pose: 'relaxed', gaze: 'soft', mouth: 'soft', label: '猫咪坐好，小狗歪着头靠在身边' };
}
