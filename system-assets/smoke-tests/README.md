# Smoke Tests（v0.1）

## 目标
任何 API 改动 → 必须先在本地/测试环境通过冒烟测试，再允许部署。

## 覆盖范围（最小集合）
1. /health 必须 200
2. /upload/credential 返回字段齐全
3. /jobs/analyze 同步或返回 jobId
4. 若异步：轮询 /jobs/:jobId 最多 N 次直到 done/failed
5. 所有请求打印 traceId，失败时输出完整响应体

## 运行方式
- curl 版本：`smoke.curl.sh`
- Node 版本：`smoke.node.mjs`（可选）
