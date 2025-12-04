# 简化闲聊系统使用指南

## 📖 概述

闲聊系统已简化为使用条件判断和动作回退机制，无需额外的管理器。通过配置多个 `ActionStartDialogue` 动作，系统会按顺序尝试执行，直到成功。

---

## 🎯 核心原理

1. **条件判断**：`ActionStartDialogue` 支持条件检查，如果条件不满足则跳过
2. **回退机制**：如果对话节点不存在且设置了 `silent_fallback=true`，则静默跳过
3. **顺序执行**：`InteractionComponent` 按顺序尝试执行动作，直到成功

---

## 🚀 快速开始

### 步骤 1：在对话文件中配置闲聊节点

编辑 `data/dialogues/dialogue.json`：

```json
{
  "village_chief_start": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": "VILLAGE_CHIEF_GREETING",
    "choices": [
      {
        "text": "VILLAGE_CHIEF_CHOICE_ACCEPT",
        "next_node": "accept_quest_forest"
      }
    ]
  },
  "village_chief_chatter": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": [
      "VILLAGE_CHIEF_CHATTER_1",
      "VILLAGE_CHIEF_CHATTER_2",
      "VILLAGE_CHATTER_3",
      "VILLAGE_CHIEF_CHATTER_4"
    ],
    "next_node": "END"
  }
}
```

### 步骤 2：在 NPC 场景中配置两个 ActionStartDialogue

在 `prefabs/npc.tscn` 的 `InteractionComponent` 中：

1. **第一个动作**：任务对话（带条件）
   - `dialogue_node_id`: `"village_chief_start"`
   - `condition`: 配置 `ConditionQuestStatus`（任务未完成）
   - `silent_fallback`: `true`

2. **第二个动作**：闲聊对话（无条件）
   - `dialogue_node_id`: `"village_chief_chatter"`
   - `condition`: `null`（无条件）
   - `silent_fallback`: `true`

### 步骤 3：完成！

现在当玩家与 NPC 交互时：
- ✅ 如果任务未完成 → 启动任务对话
- ✅ 如果任务已完成或任务对话不存在 → 启动闲聊对话

---

## 📝 详细配置示例

### 场景编辑器配置

在 `InteractionComponent` 的 `Actions` 数组中：

```
Actions[0]: ActionStartDialogue
  ├── dialogue_node_id: "village_chief_start"
  ├── condition: ConditionQuestStatus
  │   ├── quest_id: "chief_forest_quest"
  │   └── status: "can_accept"
  └── silent_fallback: true

Actions[1]: ActionStartDialogue
  ├── dialogue_node_id: "village_chief_chatter"
  ├── condition: null
  └── silent_fallback: true
```

### 代码配置示例

```gdscript
# 在脚本中动态配置
var quest_condition = ConditionQuestStatus.new()
quest_condition.quest_id = "chief_forest_quest"
quest_condition.status = "can_accept"

var task_dialogue = ActionStartDialogue.new()
task_dialogue.dialogue_node_id = "village_chief_start"
task_dialogue.condition = quest_condition
task_dialogue.silent_fallback = true

var chatter_dialogue = ActionStartDialogue.new()
chatter_dialogue.dialogue_node_id = "village_chief_chatter"
chatter_dialogue.silent_fallback = true

interaction_component.actions = [task_dialogue, chatter_dialogue]
```

---

## 🔧 工作原理

### ActionStartDialogue 执行流程

1. **检查条件**：
   - 如果配置了 `condition` 且条件不满足 → 返回 `false`（跳过）

2. **检查对话节点**：
   - 如果对话节点不存在：
     - `silent_fallback=true` → 返回 `false`（静默跳过）
     - `silent_fallback=false` → 报错并返回 `false`

3. **启动对话**：
   - 如果对话节点存在 → 启动对话并返回 `true`

### InteractionComponent 执行流程

1. 按顺序遍历 `actions` 数组
2. 对每个动作调用 `execute()`
3. 如果返回 `true` → 停止执行后续动作
4. 如果返回 `false` → 继续尝试下一个动作

---

## 💡 使用场景

### 场景 1：任务 NPC（优先任务对话）

```gdscript
# 动作 1：任务对话（条件：任务未完成）
var task_action = ActionStartDialogue.new()
task_action.dialogue_node_id = "village_chief_start"
task_action.condition = ConditionQuestStatus.new()  # 配置条件
task_action.silent_fallback = true

# 动作 2：闲聊对话（无条件）
var chatter_action = ActionStartDialogue.new()
chatter_action.dialogue_node_id = "village_chief_chatter"
chatter_action.silent_fallback = true

interaction_component.actions = [task_action, chatter_action]
```

**行为**：
- 任务未完成 → 启动任务对话
- 任务已完成 → 启动闲聊对话

### 场景 2：只有闲聊的 NPC

```gdscript
# 只配置一个闲聊动作
var chatter_action = ActionStartDialogue.new()
chatter_action.dialogue_node_id = "merchant_chatter"
chatter_action.silent_fallback = true

interaction_component.actions = [chatter_action]
```

### 场景 3：多个对话优先级

```gdscript
# 动作 1：主线对话（条件：主线任务进行中）
# 动作 2：支线对话（条件：支线任务进行中）
# 动作 3：闲聊对话（无条件）

interaction_component.actions = [main_action, side_action, chatter_action]
```

---

## ⚠️ 注意事项

1. **条件配置**：确保条件的逻辑正确（如 `status: "can_accept"` 表示任务可以接取）
2. **silent_fallback**：建议设置为 `true`，避免节点不存在时报错
3. **动作顺序**：优先级高的动作放在前面
4. **对话节点命名**：闲聊节点建议使用 `{npc_id}_chatter` 格式

---

## 🎓 总结

通过简化的设计：

✅ **无需额外管理器**：直接使用现有的条件系统  
✅ **配置简单**：只需配置两个 `ActionStartDialogue`  
✅ **灵活扩展**：可以配置多个优先级不同的对话  
✅ **代码简洁**：减少了系统复杂度  

闲聊的本质就是触发随机文本，通过条件判断和回退机制，我们可以用最简单的方式实现它！

