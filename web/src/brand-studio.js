const core = document.querySelector('#launch-core');
const phone = document.querySelector('#launch-phone');
const mark = document.querySelector('#launch-mark');
const replay = document.querySelector('#launch-replay');
const theme = document.querySelector('#launch-theme');
const reduced = document.querySelector('#launch-reduced');
const status = document.querySelector('#launch-status');
const preference = window.matchMedia('(prefers-reduced-motion: reduce)');
reduced.checked = preference.matches;

function stop(message) {
  core.classList.remove('is-playing');
  status.textContent = message;
}
replay.addEventListener('click', () => {
  if (reduced.checked || preference.matches) {
    stop('已使用静态展示，保留完整标志与留白。');
    return;
  }
  core.classList.remove('is-playing');
  void core.offsetWidth;
  core.classList.add('is-playing');
  status.textContent = '轻轻舒展，然后停留。';
});
mark.addEventListener('animationend', () => stop('启动预览结束。可以再次播放，或切换深浅色比较。'));
theme.addEventListener('click', () => {
  const dark = phone.dataset.theme !== 'dark';
  phone.dataset.theme = dark ? 'dark' : 'light';
  theme.setAttribute('aria-pressed', String(dark));
  theme.textContent = dark ? '浅色预览' : '深色预览';
  mark.src = dark ? '/brand/fangcun-mark-white.svg' : '/brand/fangcun-mark.svg';
});
reduced.addEventListener('change', () => stop(reduced.checked ? '已减少动态效果，使用静态展示。' : '可以播放一次轻柔的启动效果。'));
preference.addEventListener('change', event => {
  reduced.checked = event.matches;
  stop(event.matches ? '跟随系统，已减少动态效果。' : '可以播放一次轻柔的启动效果。');
});
const updateVisibility = visible => core.classList.toggle('is-paused', !visible || document.hidden);
let inView = true;
new IntersectionObserver(entries => {
  inView = entries[0].isIntersecting;
  updateVisibility(inView);
}).observe(phone);
document.addEventListener('visibilitychange', () => updateVisibility(inView));
