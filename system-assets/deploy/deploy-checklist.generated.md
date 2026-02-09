# 部署检查清单（v0.2 Generated）

## 部署前（必做）
- 构建目录已确认
- 环境变量：local/test/prod 已区分且无缺失
- CORS：prod 不允许 *
- 配额/超时：上传大小、函数超时、内存配置确认
- 日志：traceId 已接入
- 冒烟测试：已在目标环境跑过并通过

## 部署后（必做）
- 线上 /health 通过
- 核心链路 smoke-tests 通过
- 错误码 & traceId 能定位

## 运行时建议
- 运行时：CloudBase 云函数
- 回退策略：不可用时返回可解释降级结果
