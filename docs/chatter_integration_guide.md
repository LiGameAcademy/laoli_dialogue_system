# 闲聊系统集成指南

## 📖 概述

本指南介绍如何将闲聊系统集成到游戏中的 NPC，实现"优先特定对话，否则触发闲聊"的功能。

## 🎯 核心功能

- **智能对话选择**：优先启动特定对话，如果不存在则自动触发闲聊
- **自动闲聊**：NPC 可以定时自动触发闲聊对话
- **简单配置**：通过 `NPCComponent` 组件轻松配置 NPC 的对话和闲聊行为

---

## 🚀 快速开始

### 方法一：使用 NPCComponent（推荐）

`NPCComponent` 是最简单的集成方式，它会自动配置 `InteractionComponent`。

#### 1. 在 NPC 场景中添加 NPCComponent

1. 打开 NPC 场景（如 `prefabs/npc.tscn`）
2. 在 NPC 根节点下添加 `NPCComponent` 节点
3. 配置属性：
   - **npc_id**: NPC 的唯一 ID（如 `"village_chief"`）
   - **dialogue_node_id**: 优先启动的对话节点（如 `"village_chief_start"`）
   - **enable_chatter**: 是否启用闲聊（默认 `true`）
   - **force_dialogue**: 是否强制使用特定对话（默认 `false`）
   - **auto_chatter_interval**: 自动触发闲聊的间隔（秒，0 表示不自动触发）

#### 2. 配置示例

```gdscript
# NPCComponent 会自动：
# 1. 查找 InteractionComponent
# 2. 创建 ActionStartDialogueOrChatter
# 3. 配置交互行为
```

#### 3. 场景结构示例

```
NPC (CharacterBody3D)
├── Mage (视觉模型)
├── CollisionShape3D
├── InteractionComponent (Area3D)
│   └── CollisionShape3D
├── InteractionLabel (Label3D)
├── QuestIcon
└── NPCComponent (Node)  ← 新增
    ├── npc_id: "village_chief"
    ├── dialogue_node_id: "village_chief_start"
    ├── enable_chatter: true
    └── auto_chatter_interval: 60.0
```

---

### 方法二：手动配置 InteractionComponent

如果你不想使用 `NPCComponent`，可以手动配置 `InteractionComponent`。

#### 1. 创建 ActionStartDialogueOrChatter

在 `InteractionComponent` 的 `actions` 数组中添加 `ActionStartDialogueOrChatter`：

```gdscript
# 在场景编辑器中：
# 1. 选择 InteractionComponent
# 2. 在 Actions 数组中添加新项
# 3. 选择 ActionStartDialogueOrChatter 类型
# 4. 配置属性：
#    - dialogue_node_id: "village_chief_start"
#    - npc_id: "village_chief"
#    - force_dialogue: false
```

#### 2. 代码配置示例

```gdscript
# 在脚本中动态配置
var action = ActionStartDialogueOrChatter.new()
action.dialogue_node_id = "village_chief_start"
action.npc_id = "village_chief"
action.force_dialogue = false

interaction_component.actions = [action]
```

---

## 📝 对话文件配置

### 1. 创建闲聊节点

在对话 JSON 文件中，为每个 NPC 创建闲聊节点：

```json
{
  "village_chief_chatter": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": [
      "VILLAGE_CHIEF_CHATTER_1",
      "VILLAGE_CHIEF_CHATTER_2",
      "VILLAGE_CHIEF_CHATTER_3"
    ],
    "next_node": "END"
  }
}
```

**命名规范**：闲聊节点 ID = `{npc_id}_chatter`

### 2. 创建特定对话节点

```json
{
  "village_chief_start": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": "VILLAGE_CHIEF_GREETING",
    "choices": [
      {
        "text": "VILLAGE_CHIEF_CHOICE_ACCEPT",
        "next_node": "village_chief_accept_reply"
      }
    ]
  }
}
```

---

## 🔧 工作原理

### ActionStartDialogueOrChatter 逻辑

1. **优先特定对话**：
   - 如果配置了 `dialogue_node_id` 且对话节点存在，启动该对话
   - 如果 `force_dialogue=true` 但对话不存在，输出警告，不触发闲聊

2. **回退到闲聊**：
   - 如果没有配置特定对话，或特定对话不存在
   - 尝试触发闲聊（`ChatterManager.try_trigger_chatter`）
   - 如果闲聊触发失败（间隔太短），强制触发一次

### NPCComponent 自动配置

- 自动查找 `InteractionComponent`（在父节点或同级节点中）
- 如果 `InteractionComponent` 只有 `ActionStartDialogue` 动作，自动替换为 `ActionStartDialogueOrChatter`
- 如果启用了自动闲聊，创建定时器定期触发闲聊

---

## 💡 使用场景

### 场景 1：任务 NPC（有特定对话）

```gdscript
# NPCComponent 配置
npc_id = "village_chief"
dialogue_node_id = "village_chief_start"  # 任务对话
enable_chatter = true
force_dialogue = false  # 如果任务对话不存在，触发闲聊
auto_chatter_interval = 0.0  # 不自动触发
```

**行为**：
- 玩家交互时，优先启动任务对话
- 如果任务对话不存在，触发闲聊
- 不会自动触发闲聊

### 场景 2：普通 NPC（只有闲聊）

```gdscript
# NPCComponent 配置
npc_id = "merchant"
dialogue_node_id = ""  # 没有特定对话
enable_chatter = true
auto_chatter_interval = 60.0  # 每60秒自动触发一次
```

**行为**：
- 玩家交互时，直接触发闲聊
- 每60秒自动触发一次闲聊（如果对话系统未激活）

### 场景 3：强制特定对话（不触发闲聊）

```gdscript
# NPCComponent 配置
npc_id = "quest_giver"
dialogue_node_id = "quest_start"
enable_chatter = false
force_dialogue = true  # 强制使用特定对话
```

**行为**：
- 玩家交互时，只启动特定对话
- 如果特定对话不存在，输出警告，不触发闲聊
- 不会自动触发闲聊

---

## 🎮 完整示例

### 1. 对话文件（`data/dialogues/village_dialogue.json`）

```json
{
  "village_chief_start": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": "VILLAGE_CHIEF_GREETING",
    "choices": [
      {
        "text": "VILLAGE_CHIEF_CHOICE_ACCEPT",
        "next_node": "village_chief_accept_reply"
      }
    ]
  },
  "village_chief_chatter": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": [
      "VILLAGE_CHIEF_CHATTER_1",
      "VILLAGE_CHIEF_CHATTER_2",
      "VILLAGE_CHIEF_CHATTER_3"
    ],
    "next_node": "END"
  }
}
```

### 2. NPC 场景配置

在 `prefabs/npc.tscn` 中：

```
NPC (CharacterBody3D)
├── ...
├── InteractionComponent
│   └── (NPCComponent 会自动配置 actions)
└── NPCComponent
    ├── npc_id: "village_chief"
    ├── dialogue_node_id: "village_chief_start"
    ├── enable_chatter: true
    └── auto_chatter_interval: 0.0
```

### 3. 游戏启动时加载对话文件

```gdscript
# main.gd 或场景脚本
func _ready() -> void:
	# 加载对话文件
	DialogueManager.load_dialogue_file("res://data/dialogues/village_dialogue.json")
```

---

## 🔍 调试技巧

### 1. 检查对话节点是否存在

```gdscript
# 在 _ready() 中
if DialogueManager.dialogue_graph.has("village_chief_chatter"):
	print("闲聊节点存在")
else:
	print("闲聊节点不存在，请检查对话文件")
```

### 2. 手动触发闲聊

```gdscript
# 在 NPCComponent 或脚本中
ChatterManager.force_trigger_chatter("village_chief")
```

### 3. 检查闲聊间隔

```gdscript
var last_time = ChatterManager.get_last_chatter_time("village_chief")
var current_time = Time.get_ticks_msec() / 1000.0
print("距离上次闲聊: %.1f 秒" % (current_time - last_time))
```

---

## ⚠️ 注意事项

1. **命名规范**：闲聊节点 ID 必须是 `{npc_id}_chatter`
2. **对话文件加载**：确保在 NPC 交互前加载包含闲聊节点的对话文件
3. **本地化文本**：确保所有闲聊文本键都在 `translations.csv` 中
4. **自动闲聊**：只有在 `DialogueManager.is_active = false` 时才会自动触发闲聊
5. **间隔控制**：`ChatterManager.MIN_CHATTER_INTERVAL` 控制闲聊的最小间隔（默认30秒）

---

## 📚 相关文档

- [随机闲聊系统文档](./random_chatter_system.md)
- [对话系统 API 文档](./api_reference.md)
- [多文件管理指南](./multi_file_management.md)

---

## 🎓 总结

通过 `NPCComponent` 和 `ActionStartDialogueOrChatter`，你可以轻松实现：

✅ **智能对话选择**：优先特定对话，否则触发闲聊  
✅ **自动闲聊**：NPC 定时自动触发闲聊  
✅ **简单配置**：只需配置几个属性即可  

现在你的 NPC 可以更生动地与玩家互动了！🎉

