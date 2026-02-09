# 接口契约模板（v0.1）

## 统一约束
- 所有响应必须包含：traceId
- 所有错误必须是结构化 JSON：`{ ok:false, code, message, traceId, details? }`
- 所有接口必须写清：超时策略、上传大小限制、是否支持分片/直传、典型错误码

## 统一响应结构（强制）
```json
{
  "ok": true,
  "data": {},
  "error": { "code": "...", "message": "...", "details": {} },
  "traceId": "..."
}
```

## 示例：Health
GET /health

Response:
```json
{ "ok": true, "traceId": "..." }
```

## 示例：获取上传凭证（推荐）
POST /upload/credential

Request:
```json
{ "contentType": "image/jpeg", "size": 345678, "sha256": "..." }
```

Response:
```json
{
  "ok": true,
  "traceId": "...",
  "data": { "provider": "cos", "tempSecret": { }, "key": "uploads/xxx.jpg", "expireAt": 1234567890 }
}
```

## 示例：提交处理任务（云函数只收 cosKey）
POST /jobs/analyze

Request:
```json
{ "input": { "type": "image", "cosKey": "uploads/xxx.jpg" }, "options": { "mode": "extract_template_info" } }
```

Response（同步完成）：
```json
{ "ok": true, "traceId": "...", "data": { "result": {} } }
```

Response（异步）：
```json
{ "ok": true, "traceId": "...", "data": { "jobId": "job_123", "status": "queued" } }
```

## 示例：查询任务
GET /jobs/:jobId

Response:
```json
{ "ok": true, "traceId": "...", "data": { "status": "running|done|failed", "result": {} } }
```
