# Execution Engine v1 · 严格执行版实施清单

## 总原则（冻结）
- 不重新讨论业务方向、产品形态、技术栈（阶段2已冻结）
- 不引入新系统规则
- 不绕过 playbooks
- 不绕过 Failure Routing
- 所有执行均视为一次 **Execution Round（执行轮次）** 的“实例化与推进”

---

## Step 0｜Execution Round 初始化
**目的**：明确这是“一次执行实例”，而不是系统变更

- 输入
  - 自然语言输入（想法或调整说明）
  - 或已有 Execution Round 的 delta
- 输出（必须）
  - `execution-round/{id}/context.md`
  - 唯一 Round ID（贯穿本轮所有产物与证据）

**验收**
- Round ID 全程贯穿，所有产物可追溯

---

## Step 1｜执行参数实例化（Execution Parameters）
**目的**：把“模糊输入”约束成阶段2规则允许的参数集合（实例化，而非决策）

- 输入
  - Round context
  - 阶段2冻结规则（隐式前提）
- 输出（必须）
  - `execution-round/{id}/execution-params.json`

**硬约束**
- 只能使用阶段2已允许的选项
- 不得新增产品形态 / 技术路径

**失败路由**
- 若检测到规则冲突 → 视为规则/系统定义问题 → Failure Routing → AI Tech Lead

---

## Step 2｜原型作用域确认（Prototype Scope）
**目的**：定义“这一轮跑多大”，只描述最短可验证路径（范围控制，而非战略裁剪）

- 输入
  - execution-params
- 输出（必须）
  - `execution-round/{id}/prototype-scope.md`

**约束**
- 只描述最短可验证路径（能看、能试、能判断去留）
- 不涉及战略扩展

**失败路由**
- scope 不可执行 / 无法落地 → dispatch 给 07_delivery-manager

---

## Step 3｜执行清单展开（Execution Manifest）
**目的**：把既有 playbooks / MCP / skills 展开成本轮可执行清单（不创造新规则）

- 输入
  - execution-params
  - prototype-scope
- 输出（必须）
  - `execution-round/{id}/execution-manifest.md`

**manifest 必须包含**
- 本轮将调用哪些 playbooks / MCP / skills
- 每一步的输入 / 输出
- fallback 策略（mock / skip / degrade）
- 证据落盘点（evidence / logs / artifacts 的相对路径）

**失败路由**
- 工程/工具/环境导致无法展开或执行 → AI Engineering Reliability

---

## Step 4｜原型生成（Prototype Generation）
**目的**：产出“可看、可感知”的原型结果（System 1.0 的肉眼可见价值点）

- 输入
  - execution-manifest
- 输出（必须）
  - `execution-round/{id}/prototype-artifact/`
  - `execution-round/{id}/preview.md`（如何查看/打开原型）

**允许的原型形式（任选其一即可）**
- 静态页面原型（HTML/可预览）
- API mock + 示例响应 + 最小交互说明
- MCP 生成的 demo artifact（可视化结果）

**约束**
- 不追求生产级
- 不引入阶段2未允许的技术形态

---

## Step 5｜验证与稳定性检查
**目的**：确保能跑、能复现；复用阶段2已验证的 system-check / smoke-tests

- 执行
  - system-check
  - smoke-tests（按 contract）
- 输出（必须）
  - PASS/FAIL 结果
  - evidence（日志/trace/报告的落盘路径）

**失败路由**
- 失败自动交由现有 Failure Routing（不人工猜测归因）

---

## Step 6｜Execution Round 结束态（可决策信息）
**目的**：形成“是否继续”的信息集合，不替代人做决策

- 输出（必须）
  - Round 状态：PASS / FAIL / PARTIAL
  - 下一步建议（信息性质）：
    - 继续调整（给出建议的调整方向）
    - 收敛（建议冻结并进入试用）
    - 放弃（提示风险与复盘原因）

**约束**
- 不做方向决策
- 只提供信息、风险提示与复盘理由
