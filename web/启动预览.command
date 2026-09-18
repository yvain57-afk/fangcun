#!/bin/zsh
set -e
cd "$(dirname "$0")"
if curl --silent --max-time 2 http://127.0.0.1:4173/ | grep -q '方寸 Fangcun'; then
  open 'http://127.0.0.1:4173/'
  exit 0
fi
if ! command -v npm >/dev/null 2>&1; then
  print '需要先安装 Node.js 22.12 或更新版本，再双击此文件。'
  read '?按回车关闭…'
  exit 1
fi
if [[ ! -d node_modules ]]; then
  npm ci --no-audit --no-fund
fi
print '方寸预览即将打开。保留此窗口运行；按 Control-C 停止。'
exec npm run dev -- --open
