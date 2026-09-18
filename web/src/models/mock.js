export const SCENARIOS = {
  stable: { label: '平稳', status: '负荷平稳', title: '今日压力负荷平稳', subtitle: '身体的节奏，还不错。', description: '睡眠与恢复接近平常，今天按自己的节奏来。', evidence: '睡眠充足，恢复指标接近平常', sleep: '7 小时 42 分', recovery: '接近平常', heartRate: '59 次 / 分', hrv: '44 ms', movement: '步行 6,280 步', sleepNote: '比个人通常时长多 18 分钟', recoveryNote: '静息心率与 HRV 接近个人近期水平' },
  elevated: { label: '偏高', status: '负荷偏高', title: '今日压力负荷偏高', subtitle: '今天，给自己一点缓冲。', description: '昨晚休息少了一点，恢复也慢一些。先留一口气给自己。', evidence: '睡眠少于平常，恢复指标有变化', sleep: '5 小时 36 分', recovery: '需要缓冲', heartRate: '65 次 / 分', hrv: '32 ms', movement: '昨天有 42 分钟训练', sleepNote: '少于个人通常时长', recoveryNote: '静息心率与 HRV 较个人近期水平有变化' },
  insufficient: { label: '数据不足', status: '数据不足', title: '暂时还无法判断', subtitle: '先从一口舒服的呼吸开始。', description: '近期恢复数据还不完整。等数据准备好，再一起看看。', evidence: '缺少近期恢复数据，暂不做结论', sleep: '暂无完整记录', recovery: '资料不足', heartRate: '—', hrv: '—', movement: '暂无完整记录', sleepNote: '没有记录不等于没有睡眠', recoveryNote: '需要更多有效记录来建立个人参照' },
};
export const WEEK = [
  { day: '11', weekday: '五', date: '9 月 11 日', state: 'stable', sleep: '7 小时 18 分', activity: '步行 5,430 步', practice: '呼吸练习 · 5 分钟', drinks: '白水 1,250 ml · 咖啡 1 杯' },
  { day: '12', weekday: '六', date: '9 月 12 日', state: 'stable', sleep: '8 小时 02 分', activity: '步行 8,620 步', practice: '未记录练习', drinks: '白水 1,500 ml' },
  { day: '13', weekday: '日', date: '9 月 13 日', state: 'insufficient', sleep: '暂无完整记录', activity: '暂无完整记录', practice: '未记录练习', drinks: '暂无记录' },
  { day: '14', weekday: '一', date: '9 月 14 日', state: 'elevated', sleep: '5 小时 50 分', activity: '有氧训练 35 分钟', practice: '呼吸练习 · 5 分钟', drinks: '白水 750 ml · 咖啡 2 杯' },
  { day: '15', weekday: '二', date: '9 月 15 日', state: 'stable', sleep: '7 小时 26 分', activity: '步行 6,080 步', practice: '呼吸练习 · 5 分钟', drinks: '白水 1,500 ml · 咖啡 1 杯' },
  { day: '16', weekday: '三', date: '9 月 16 日', state: 'stable', sleep: '7 小时 40 分', activity: '步行 7,140 步', practice: '未记录练习', drinks: '白水 1,250 ml' },
  { day: '17', weekday: '四', date: '9 月 17 日', state: 'stable', today: true },
];
