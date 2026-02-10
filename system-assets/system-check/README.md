# System Check

## 目标
验证系统是否顺畅（调度/边界/路由/可复现），并输出可追溯的检查报告。

## 如何运行
1) 离线：
bash scripts/system-check.sh

2) 在线：
API_BASE=https://your-api.example.com bash scripts/system-check.sh

可选：
SMOKE_PROFILE=health-only bash scripts/system-check.sh

## 结果解释
- PASS：检查通过
- FAIL：检查失败（脚本退出码为 1）
- WARNING：非阻断问题（不会导致退出失败）

## 常见问题
- API_BASE 未设置：仅执行离线检查，不跑在线 smoke
- smoke 脚本不可执行：脚本会尝试 chmod +x
- 契约缺 endpoint header：合同检查会提示并记录
