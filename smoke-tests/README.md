# Smoke Tests

## 必须设置 API_BASE
示例：
API_BASE=https://your-api.example.com SMOKE_PROFILE=health-only bash smoke-tests/smoke.curl.sh

生成器输出在此目录。

## 模式说明
- contract 模式（默认）：解析 `api-contract.md` 中 `@smoke: required` 的接口并测试
- profile 模式：若设置 `SMOKE_PROFILE`，则按 profile 执行并覆盖 contract

示例：
- API_BASE=... bash smoke-tests/smoke.curl.sh              # contract 模式
- API_BASE=... SMOKE_PROFILE=health-only bash smoke-tests/smoke.curl.sh  # profile 覆盖
