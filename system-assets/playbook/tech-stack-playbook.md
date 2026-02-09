# 技术栈选择与组合 Playbook（v0.1）

## 选型输入（系统从自然语言抽取）
- 交互形态：miniprogram | h5 | mp+webview | official_account | video_account
- 输入类型：text | image | audio | video | file
- 单次最大文件：<10MB | 10-50MB | 50-200MB | >200MB
- 时延：instant(<3s) | short(<10s) | async(可等待)
- 登录：none | wechat_login | org_account
- 合规：china_required(必须国内) | global_ok
- 并发级别：low(<50/d) | mid(<5k/d) | high(>5k/d)
- 成本敏感：high | medium | low

## 系统输出（默认选“最稳+最省时间”）
### 默认推荐组合（适用于 80% MVP）
- 前端：小程序原生 +（可选）H5 WebView 承载
- 后端：CloudBase 云函数（HTTP 触发）
- 存储：COS（大文件/图片/视频）+ CloudBase Storage（轻量）
- 鉴权：微信登录（如需要）
- LLM：优先国内可用（腾讯混元 / 火山·豆包）
- 可观测：统一日志字段 + traceId + 错误码规范（见 2.2）
- 回退策略：LLM/外部服务不可用 → 返回可解释降级结果

## 触发条件 → 方案切换规则（机器可执行的决策要点）
### 大文件上传（≥10MB）
- 禁止：把文件/图片 base64 走 JSON 进云函数
- 选择：客户端直传 COS（带临时密钥）或分片上传 COS
- 云函数只接收：cosKey + metadata

### 耗时任务（>10s）
- 选择：异步任务队列/延迟处理
- 兜底：轮询 + jobId 最小实现

### 强实时（<3s）且模型不稳定
- 选择：先返回结构化占位结果 + 后补齐

### 需要稳定公网回调/长连接/复杂路由
- 选择：CloudBase Run（容器）优先
- 云函数只做轻接口

### 合规必须国内
- 禁止：Firebase/Vercel/海外模型默认路径
- 选择：国内云 + 国内模型 + 国内对象存储

## 预算预估（触发成本确认规则）
仅在以下情况触发 Human（成本支出确认）：
- 新增付费第三方（短信、OCR、付费模型、大流量 CDN、付费队列）
- 预计月成本 > 阈值（默认 ¥500/月）

其余情况默认按免费额度/最低配置推进。
