# Dispatch（自动派单）

## 什么是 dispatch
当 system-check FAIL 时自动生成的派单文件，用于指派给对应智能体处理。

## 什么时候生成
- system-check 结果为 FAIL 时生成

## 如何使用
- 复制派单内容给对应智能体
- 按派单中的 Suggested Next Command 执行

## 模式
- advice（默认）：生成派单，但退出码保持 system-check 原始结果
- strict：生成派单 + 明确 BLOCKED，并返回失败码

## 示例命令
- bash scripts/auto-trigger.sh
- AUTO_TRIGGER_MODE=strict bash scripts/auto-trigger.sh
