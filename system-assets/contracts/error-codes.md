# 错误码规范（v0.1）

## 统一格式
```json
{ "ok": false, "code": "ERR_XXXX", "message": "...", "traceId": "...", "details": {} }
```

## 最低错误码集合
- ERR_BAD_REQUEST：参数错误 / 校验失败
- ERR_UNAUTHORIZED：鉴权失败 / 失效
- ERR_RATE_LIMITED：限流 / 频控
- ERR_TIMEOUT：超时
- ERR_UPSTREAM：上游服务失败
- ERR_UNKNOWN：未知错误

## 上传相关
- ERR_UPLOAD_SIZE_EXCEEDED：上传超限
- ERR_UPLOAD_EXPIRED：上传凭证过期
- ERR_UPLOAD_FAILED：上传失败

## 任务相关
- ERR_JOB_NOT_FOUND：任务不存在
- ERR_JOB_FAILED：任务失败
