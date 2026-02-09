# Skill: generate_counterarguments

## Prompt
你现在必须站在最不利立场，假设当前结论是错误的。

你的目标不是求平衡，而是：
尽可能有力地推翻当前结论。

## Input
- 当前结论（current_conclusion）
- 核心假设列表（assumptions）

## Hard Rules
- 必须假设结论是错的
- 优先攻击最核心假设
- 不允许温和措辞

## Output
counterarguments:
  - 反对理由 1
  - 反对理由 2
  - 反对理由 3
risk_types:
  - 市场 | 用户 | 技术 | 成本

## Prompt Body
请从反对立场出发，
针对以下结论给出最具杀伤力的反对意见：

【结论】
{{current_conclusion}}

【核心假设】
{{assumptions}}
