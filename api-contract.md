# 接口契约模板（v0.2 Generated）

## 统一约束
- 所有响应必须包含：traceId
- 所有错误必须是结构化 JSON：{ ok:false, code, message, traceId, details? }
- 超时策略：异步（jobId + 轮询）
- 上传大小限制：MAX_UPLOAD_MB=20
- 直传/分片：客户端直传 COS 或分片上传 COS

## 统一响应结构（强制）
{ "ok": true/false, "data": {}, "error": {"code":"...","message":"...","details":{}}, "traceId": "..." }

## 错误码（示例）
- ERR_BAD_REQUEST / ERR_UNAUTHORIZED / ERR_RATE_LIMITED / ERR_TIMEOUT / ERR_UPSTREAM / ERR_UNKNOWN
- ERR_UPLOAD_SIZE_EXCEEDED / ERR_UPLOAD_EXPIRED / ERR_UPLOAD_FAILED
- ERR_JOB_NOT_FOUND / ERR_JOB_FAILED

## GET /health
@smoke: required
Response: { "ok": true, "traceId": "..." }

## POST /upload/credential
@smoke: optional
Request: { "contentType": "image/jpeg", "size": 345678, "sha256": "..." }
Response: { "ok": true, "traceId": "...", "data": { "provider": "cos", "tempSecret": {}, "key": "uploads/xxx.jpg", "expireAt": 1234567890 } }

## POST /jobs/analyze
@smoke: optional
Request: { "input": { "type": "image", "cosKey": "uploads/xxx.jpg" }, "options": { "mode": "extract_template_info" } }
Response（同步完成）: { "ok": true, "traceId": "...", "data": { "result": {} } }
Response（异步）: { "ok": true, "traceId": "...", "data": { "jobId": "job_123", "status": "queued" } }

## GET /jobs/:jobId
@smoke: optional
Response: { "ok": true, "traceId": "...", "data": { "status": "running|done|failed", "result": {} } }

# Generated (v0.2)

# 接口契约模板（v0.2 Generated）

## 统一约束
- 所有响应必须包含：traceId
- 所有错误必须是结构化 JSON：{ ok:false, code, message, traceId, details? }
- 超时策略：异步（jobId + 轮询）
- 上传大小限制：MAX_UPLOAD_MB=20
- 直传/分片：客户端直传 COS 或分片上传 COS

## 统一响应结构（强制）
{ "ok": true/false, "data": {}, "error": {"code":"...","message":"...","details":{}}, "traceId": "..." }

## 错误码（示例）
- ERR_BAD_REQUEST / ERR_UNAUTHORIZED / ERR_RATE_LIMITED / ERR_TIMEOUT / ERR_UPSTREAM / ERR_UNKNOWN
- ERR_UPLOAD_SIZE_EXCEEDED / ERR_UPLOAD_EXPIRED / ERR_UPLOAD_FAILED
- ERR_JOB_NOT_FOUND / ERR_JOB_FAILED

## GET /health
@smoke: required
Response: { "ok": true, "traceId": "..." }

## POST /upload/credential
@smoke: optional
Request: { "contentType": "image/jpeg", "size": 345678, "sha256": "..." }
Response: { "ok": true, "traceId": "...", "data": { "provider": "cos", "tempSecret": {}, "key": "uploads/xxx.jpg", "expireAt": 1234567890 } }

## POST /jobs/analyze
@smoke: optional
Request: { "input": { "type": "image", "cosKey": "uploads/xxx.jpg" }, "options": { "mode": "extract_template_info" } }
Response（同步完成）: { "ok": true, "traceId": "...", "data": { "result": {} } }
Response（异步）: { "ok": true, "traceId": "...", "data": { "jobId": "job_123", "status": "queued" } }

## GET /jobs/:jobId
@smoke: optional
Response: { "ok": true, "traceId": "...", "data": { "status": "running|done|failed", "result": {} } }
