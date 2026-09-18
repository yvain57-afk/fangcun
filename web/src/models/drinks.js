// Fictional portion presets for interaction testing, not a nutrition database.
export const PRESETS = {
  water: { category: 'water', name: '白水', size: '250 ml / 杯', fluidMl: 250, caffeineMg: 0, alcoholG: 0, sugarServings: 0 },
  coffee: { category: 'coffee', name: '美式', size: '300 ml · 咖啡因预估', fluidMl: 300, caffeineMg: 140, alcoholG: 0, sugarServings: 0 },
  sweetCoffee: { category: 'coffee', name: '甜拿铁', size: '300 ml · 同计咖啡因与糖饮', fluidMl: 300, caffeineMg: 140, alcoholG: 0, sugarServings: 1 },
  beer: { category: 'alcohol', name: '啤酒', size: '330 ml · 约 10 g 酒精（预设）', fluidMl: 330, caffeineMg: 0, alcoholG: 10, sugarServings: 0 },
  soda: { category: 'sugary', name: '含糖汽水', size: '330 ml / 份 · 不估算糖克数', fluidMl: 330, caffeineMg: 0, alcoholG: 0, sugarServings: 1 },
};
export const EMPTY_LOG = { entries: [], history: [] };
const fields = ['fluidMl', 'caffeineMg', 'alcoholG', 'sugarServings'];
const validEntry = entry => entry && Object.hasOwn(PRESETS, entry.preset) && fields.every(field => Number.isFinite(entry[field]) && entry[field] >= 0 && entry[field] <= 10000);
export function validLog(value) {
  return value && Array.isArray(value.entries) && value.entries.length <= 1000 &&
    value.entries.every(validEntry) && Array.isArray(value.history) &&
    value.history.length <= 50 && value.history.every(row => Array.isArray(row) && row.length <= 1000 && row.every(validEntry));
}
export function countCategory(entries, category) {
  return entries.filter(entry => PRESETS[entry.preset].category === category).length;
}
export function changeLog(log, action) {
  if (action.type === 'undo') {
    if (!log.history.length) return log;
    return { entries: log.history.at(-1), history: log.history.slice(0, -1) };
  }
  let next;
  if (action.type === 'add' && Object.hasOwn(PRESETS, action.preset)) {
    if (log.entries.length >= 1000) return log;
    const preset = PRESETS[action.preset];
    const caffeineMg = preset.category === 'coffee' && Number.isFinite(action.coffeeMg) ? Math.max(0, Math.min(500, action.coffeeMg)) : preset.caffeineMg;
    next = [...log.entries, { preset: action.preset, fluidMl: preset.fluidMl, caffeineMg, alcoholG: preset.alcoholG, sugarServings: preset.sugarServings }];
  } else if (action.type === 'remove') {
    const index = log.entries.findLastIndex(entry => PRESETS[entry.preset].category === action.category);
    if (index === -1) return log;
    next = log.entries.filter((_, i) => i !== index);
  } else return log;
  return { entries: next, history: [...log.history, [...log.entries]].slice(-50) };
}
export function totalDrinks(entries) {
  return entries.reduce((total, entry) => {
    for (const field of fields) total[field] += entry[field];
    return total;
  }, { fluidMl: 0, caffeineMg: 0, alcoholG: 0, sugarServings: 0 });
}
export function localDayKey() {
  const d = new Date();
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}
