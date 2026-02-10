# 阶段化共识驱动与受控多智能体协作协议

本协议用于规范多智能体在高不确定性创新阶段的协同方式，
目标是：

**允许充分、对立的专业博弈，但必须强制收敛为对 Human 有价值的结论。**

──────────────────
## 一、核心原则（硬约束）
──────────────────

1. 多智能体协作不是自由讨论，而是围绕“阶段目标”的对立式协作  
2. 所有协作必须围绕“阶段共识文档”，而非聊天或过程记录  
3. 允许多轮补充与反驳，但必须：
   - 有明确表达次数上限
   - 有明确收敛出口
4. 无法在规则内收敛的问题，必须升级给 Human 决策  
5. Human 永远只接收“结论态文档”，不暴露讨论过程

──────────────────
## 二、共识文档输出原则（结论态）
──────────────────

1. 共识文档是**最终判断结果**，而非讨论记录  
2. 最终文档中严禁出现：
   - 轮次描述（Round / 第几轮）
   - Agent 之间的争论过程
   - 谁说了什么
3. 共识文档只允许包含以下内容：
   - 各专业视角的**整合后判断**
   - 明确结论（做 / 不做 / 升级）
   - 支撑结论的关键理由
   - 尚未解决的不确定点（如有）

──────────────────
## 三、阶段 A（机会判断阶段）协作协议
──────────────────

### 阶段目标
判断一个市场机会是否**值得进入产品阶段**。

### 共识载体
《阶段 A｜市场与可行性共识结论》
（由市场研究 Agent 主导整合）

──────────────────
### 表达次数配额机制（关键）
──────────────────

1. 在阶段 A 中：
   - 市场研究 Agent
   - 产品方案 Agent
   - 技术可行性 Agent  
   **每一方最多拥有 3 次“有效表达机会”**
2. 一次有效表达包括：
   - 提出一个支持或反对判断
   - 补充一个关键事实或证据
   - 对他人质疑进行一次正式回应
3. 以下行为不允许或不计入：
   - 重复表达同一观点
   - 以补充名义引入新研究目标
   - 改变阶段目标的问题
4. 当某一 Agent 用尽其表达次数：
   - 自动退出该阶段
   - 剩余观点视为放弃

──────────────────
### 协作与收敛规则
──────────────────

1. 市场研究 Agent 负责：
   - 整合所有有效表达
   - 在表达机会耗尽或无新增有效信息后
     给出最终结论态判断
2. 最终结论只能是：
   - 值得进入产品阶段
   - 不值得
   - 存在关键不确定点（需 Human 裁决）
3. 若仍存在关键分歧或信息缺口：
   - 必须明确升级给 Human
   - 并标注：
     - 问题类型（业务方向 / 产品战略 / 成本支出）
     - 不裁决时的系统默认行为

──────────────────
## 四、其它阶段协作原则（简述）
──────────────────

- 阶段 B（方案与开发）  
  → 单一责任人（产品 / 技术）主导，最小化沟通

- 阶段 C（验证）  
  → 验证 Agent 先给结论，必要时再触发讨论

- 阶段 D（复盘）  
  → 允许充分交流，不设表达次数限制

──────────────────
## 五、Skill Registry 约束与调用合规
──────────────────

1. Default Skill 调用规则
   - Default = Yes 的 Skill：
     - 可被 Agent 直接调用
     - 无需额外登记
   - Default = No 的 Skill：
     - 使用前必须在 Registry 中登记
     - External Skill 默认状态为 Experimental

2. 调用优先级建议（非强制）
   - Mandatory Skill → 必须调用
   - Default Skill → 优先使用
   - Experimental Skill → 谨慎使用，并强制记录 Ledger

──────────────────
## AI 原生公司 · 角色命名与层级归属（Authoritative）
──────────────────

### 一、AI 管理层（AI Management Layer）

AI 管理层负责“判断与选择”，不直接参与工程实现。

包含角色：
- AI Product Lead
- AI Tech Lead
- 市场与验证 Agent（Market Research & Validation）

说明：
- 市场与验证 Agent 属于管理层
- 其职责是判断“是否值得做”“是否继续做”
- 不直接修改代码或工程资产

### 二、AI 执行层（AI Execution Layer）

AI 执行层负责“把事做出来”。

包含角色：
- AI UI Designer
- AI Frontend Engineer
- AI Backend Engineer
- AI QA Engineer
- AI Engineering Reliability

### 三、系统进化角色（Out-of-Band）

该类角色不属于任何层级，不参与项目执行。

包含角色：
- Global Retrospective / Evolution Agent

说明：
- 该角色不参与任何项目调度
- 不出现在任务工作流中
- 只在周期性或触发条件下运行

## 角色命名映射（文件名 ≠ 岗位名）

- agents/03_tech-cto.md
  → 岗位命名：AI Tech Lead
  → 职责与原 CTO 定义一致，仅命名升级

- agents/04_user-validation.md
  → 岗位命名：AI QA Engineer
  → 职责与原验证智能体一致

- agents/05_global-retrospective.md
  → 岗位命名：Global Retrospective / Evolution Agent
  → 明确说明：该角色不参与项目开发

- agents/06_engineering-reliability.md
  → 岗位命名：AI Engineering Reliability
  → 系统级工程保障角色（新增）

## Failure Routing（失败路由 · 权威规则）

- 工程类失败（构建 / CI / smoke / 契约 / 工具链）
  → AI Engineering Reliability

- 功能实现失败
  → 对应执行角色（Frontend / Backend）

- 验证失败
  → AI QA Engineer（只给 PASS / FAIL）

- 结构性或长期问题
  → 记录后交由 Global Retrospective（非即时处理）

强调：
- Global Retrospective 不参与即时修复
- 所有角色必须遵守边界

## 失败路由总 Prompt（强制）
当出现 FAIL 时，必须先进行失败路由：

- 如果失败原因是：
  构建 / 脚本 / CI / 环境 / 工具 / 契约 / 解析问题
  → 交给 AI Engineering Reliability

- 如果失败原因是：
  功能未实现 / 逻辑错误 / 返回值不符
  → 交给对应的 Frontend / Backend Engineer

- 如果失败涉及：
  需求不清 / 方案取舍 / 成本影响
  → 升级 AI Tech Lead 或 Human

禁止越权处理。

## System Check & Evidence
- system-check 用于验证系统调度、边界、失败路由与可复现性
- 任何组织规则调整后建议运行一次 system-check
- 报告生成位置：system-assets/reports/
