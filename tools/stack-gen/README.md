# Stack Generator (v0.2)

## 运行命令
- `node tools/stack-gen/stack-gen.mjs --profile miniprogram_image_async_china`
- `node tools/stack-gen/stack-gen.mjs --input tools/stack-gen/sample-inputs/miniprogram_image_async_china.json`

## 输出位置
- system-assets/contracts/api-contract.generated.md
- system-assets/contracts/env.generated.example
- system-assets/smoke-tests/smoke.generated.curl.sh
- system-assets/deploy/deploy-checklist.generated.md

根目录同步输出：
- `api-contract.md`（不存在则创建；存在则追加 `# Generated (v0.2)`）
- `env.example`（不存在则创建；存在则追加 `# Generated (v0.2)`）
- `smoke-tests/README.md` 与 `smoke-tests/smoke.curl.sh`（若已存在则保留并写入 `smoke-tests/smoke.generated.curl.sh`）
