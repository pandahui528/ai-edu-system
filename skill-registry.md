# Skill Registry（能力注册与治理规范）

本文档用于定义和管理本系统中
**所有可被智能体调用的 Skill / MCP 能力**，
确保系统在长期演进中具备：

- 稳定的最低能力保障
- 对新能力的开放性
- 清晰的成本 / 风险 / 决策边界
- 与未来官方 Skill Market 的兼容性

## 一、核心概念定义

## 1. Skill 定义

Skill 是一个**具备明确语义、可复用、可治理的能力单元**，
通常由以下部分构成：

- Prompt Contract（思考与输出约束）
- Tool / MCP Binding（可选）
- 使用时机与边界

Skill ≠ Tool  
Tool / MCP 是 Skill 的实现方式之一。

---

## 2. Skill 分类（系统强制）

系统内的 Skill 必须归入以下三类之一：

### A. 内置 Skill（Built-in Skill）
- 由系统定义
- 作为最低质量保障线
- 部分 Skill 被列为「必调用 Skill」

### B. 自建 MCP Skill（Internal MCP Skill）
- 基于 MCP 接口实现
- 由系统维护
- 可逐步替代内置 Prompt Skill

### C. 外部 Skill（External Skill）
- 第三方 Skill / MCP
- 或未来官方 Skill Market 能力
- 作为增强能力使用

## 二、Skill Registry 表结构（必须维护）

所有 Skill 必须以表格形式登记如下字段：

| Skill Name | Category | Description | Used By Agent | Stage | Mandatory | Default | MCP Required | Cost Level | Risk Level | Status |
|-----------|----------|-------------|---------------|-------|-----------|---------|--------------|------------|------------|--------|

字段说明：
- Skill Name：唯一标识（动词 + 领域）
- Category：Built-in / Internal MCP / External
- Used By Agent：主要调用的 Agent
- Stage：主要使用阶段（A / B / C / D）
- Mandatory：是否必调用（Yes / No）
- Default：是否默认增强能力（Yes / No）
- MCP Required：是否依赖 MCP
- Cost Level：None / Low / Medium / High
- Risk Level：Low / Medium / High
- Status：Active / Experimental / Deprecated

Default 说明：
- Yes：默认增强能力（无需单独登记或审批即可使用）
- No：非默认能力（使用前需登记或标注）

Mandatory 与 Default 的区别：
- Mandatory = 最低质量保障线，**必须调用**
- Default = 已验证的增强能力，**可直接调用但非必须**

Mandatory Skill 的 Default 一律为 Yes。

## 三、当前已注册 Skill（示例，必须写入）

| Skill Name | Category | Used By Agent | Stage | Mandatory | Default | MCP Required | Cost Level | Risk Level | Status |
|-----------|----------|---------------|-------|-----------|---------|--------------|------------|------------|--------|
| validate_market_claim | Built-in | 市场研究 Agent | A | Yes | Yes | Optional | Medium | Low | Active |
| generate_counterarguments | Built-in | 市场研究 Agent | A | Yes | Yes | No | None | Low | Active |
| simulate_user_behavior | Built-in | 产品方案 Agent | A | Yes | Yes | No | None | Low | Active |
| trim_to_mvp | Built-in | 产品方案 Agent | B | Yes | Yes | No | None | Low | Active |
| scan_architecture_risks | Built-in | 技术 Agent | B | Yes | Yes | Optional | Low | Medium | Active |
| extract_reusable_patterns | Built-in | 复盘 Agent | D | Yes | Yes | Optional | None | Low | Active |

## 四、Skill 调用治理规则（硬约束）

### 1. 最低保障原则
- 所有 Mandatory = Yes 的 Skill
- 构成系统最低质量保障线
- 不得被任何外部 Skill 替代或绕过

### 2. 增强而非替代原则
- External / MCP Skill 只能：
  - 补充证据
  - 提升效率
  - 降低不确定性
- 不得直接生成最终结论

### 3. 折叠输出原则
- 所有 Skill 的输出
- 必须被 Agent 消化并折叠进交付物
- 禁止将原始结果直接抛给 Human

### 4. Registry 作为唯一合法来源
- 所有 Agent 仅允许使用 Skill Registry 中登记的 Skill
- 未登记 Skill 视为不合规，不得用于交付

### 5. Skill Usage Ledger 强制要求
- 所有阶段性交付必须附带 Skill Usage Ledger
- Ledger 至少包含：Skill Name / Registry Status / Default / 调用目的 / 影响 / 是否产生费用

## 五、Skill 生命周期管理

每个 Skill 必须处于以下状态之一：

- Experimental：试用中，非关键路径
- Active：稳定使用
- Deprecated：即将废弃（需给替代方案）

状态变更规则：
- Experimental → Active  
  - 至少在 2 个项目中验证有效
- Active → Deprecated  
  - 出现更优 Skill
  - 或成本 / 风险不可接受

## 六、Skill 引入与升级规则

### 引入新 Skill 的条件
- 明确解决一个已存在痛点
- 不破坏现有 Mandatory Skill
- 有明确的使用阶段与 Agent

### 升级为 Mandatory Skill 的条件
- 多项目验证
- 对成功率有显著提升
- 经 Human 确认（系统级决策）

## External Skill 自动升级为 Default 的规则（Capability Promotion）

External Skill 满足以下 **全部条件** 时，  
可自动升级为 Default = Yes（仍保留 Status = Active）：

1. **多项目验证**
   - 至少在 2 个不同项目中被调用
   - 且调用结果被记录在 Skill Usage Ledger 中

2. **正向贡献明确**
   - 至少在 1 个项目中：
     - 显著降低不确定性
     - 或明显提升判断/交付质量
   - 该贡献在复盘中被明确记录

3. **成本与风险可控**
   - Cost Level ≤ Medium
   - Risk Level ≤ Medium
   - 未触发过超预算或事故级风险

4. **未替代 Mandatory Skill**
   - 仅作为增强能力存在
   - 未绕过任何 Mandatory Skill

升级生效规则：
- Default = Yes 后：
  - Agent 可直接调用
  - 无需再单独登记或审批
- 若未来风险或成本失控：
  - Default 可被撤销
  - Status 可回退为 Experimental 或 Deprecated

是否允许 External Skill 升级为 Mandatory：
- ❌ 不允许自动升级
- ✅ 仅可经 Human 明确确认（系统级决策）

## 七、成本与 Human-in-the-loop 规则

以下情况必须升级给 Human：

- 新 Skill 引入产生新增成本
- Skill 调用频率或费用显著上升
- Skill 可能影响业务方向 / 产品战略

## 八、未来兼容性声明

- 本 Registry 与 Anthropic MCP / Skill Market 设计理念兼容
- 当官方 Skill Market 成熟：
  - 可将 External Skill 映射为 Market Skill
  - 不需要调整 Agent 或协作机制
