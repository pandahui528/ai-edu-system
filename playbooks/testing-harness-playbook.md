---
# 冒烟测试 Harness Playbook（一键验证接口可用）

## 目标
发布前必须一键跑通核心链路，避免“手测+猜问题”。

## 必备测试
1) health：GET /health → 200 + ok=true
2) 核心接口：至少 1 个成功用例 + 1 个失败用例（参数错误）
3) 上传链路：若有上传，测试“超限/超时”错误码是否正确
4) traceId：所有响应必须返回 traceId

## 建议产物
- scripts/smoke.sh（curl）
- 或 scripts/smoke.mjs（node）
- 产出日志：保存响应与 traceId
---
