# 闲聊系统快速集成指南

## 🚀 5分钟快速集成

### 步骤 1：在对话文件中添加闲聊节点

编辑 `data/dialogues/dialogue.json`，添加闲聊节点：

```json
{
  "village_chief_start": {
    // ... 现有对话 ...
  },
  "village_chief_chatter": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": [
      "VILLAGE_CHIEF_CHATTER_1",
      "VILLAGE_CHIEF_CHATTER_2",
      "VILLAGE_CHIEF_CHATTER_3",
      "VILLAGE_CHIEF_CHATTER_4"
    ],
    "next_node": "END"
  }
}
```

**重要**：闲聊节点 ID 必须是 `{npc_id}_chatter`（如 `village_chief_chatter`）

### 步骤 2：在 NPC 场景中添加 NPCComponent

1. 打开 `prefabs/npc.tscn`
2. 在 NPC 根节点下添加 `NPCComponent` 节点
3. 配置属性：
   - **npc_id**: `"village_chief"`
   - **dialogue_node_id**: `"village_chief_start"`（现有对话节点）
   - **enable_chatter**: `true`
   - **auto_chatter_interval**: `0.0`（不自动触发，仅在交互时触发）

### 步骤 3：完成！

现在当玩家与 NPC 交互时：
- ✅ 如果 `village_chief_start` 对话存在，优先启动它
- ✅ 如果 `village_chief_start` 不存在，自动触发 `village_chief_chatter` 闲聊
- ✅ 闲聊会从 4 条文本中随机选择一条

---

## 📝 完整示例

### 对话文件（`data/dialogues/dialogue.json`）

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
      "VILLAGE_CHIEF_CHATTER_3",
      "VILLAGE_CHIEF_CHATTER_4"
    ],
    "next_node": "END"
  }
}
```

### NPC 场景结构

```
NPC (CharacterBody3D)
├── Mage
├── CollisionShape3D
├── InteractionComponent
│   └── (NPCComponent 会自动配置)
├── InteractionLabel
├── QuestIcon
└── NPCComponent  ← 新增
    ├── npc_id: "village_chief"
    ├── dialogue_node_id: "village_chief_start"
    ├── enable_chatter: true
    └── auto_chatter_interval: 0.0
```

---

## 🎯 常见场景

### 场景 1：只有闲聊的 NPC（没有特定对话）

```gdscript
# NPCComponent 配置
npc_id = "merchant"
dialogue_node_id = ""  # 留空
enable_chatter = true
```

**行为**：交互时直接触发闲聊

### 场景 2：任务 NPC（优先任务对话）

```gdscript
# NPCComponent 配置
npc_id = "village_chief"
dialogue_node_id = "village_chief_start"
enable_chatter = true
```

**行为**：优先任务对话，如果不存在则触发闲聊

### 场景 3：自动触发闲聊

```gdscript
# NPCComponent 配置
npc_id = "guard"
dialogue_node_id = ""
enable_chatter = true
auto_chatter_interval = 60.0  # 每60秒自动触发
```

**行为**：每60秒自动触发一次闲聊（如果对话系统未激活）

---

## ⚠️ 注意事项

1. **命名规范**：闲聊节点 ID = `{npc_id}_chatter`
2. **本地化文本**：确保闲聊文本键在 `localization/translations.csv` 中
3. **对话文件加载**：确保在 NPC 交互前加载对话文件

---

## 🔍 测试

1. 运行游戏
2. 与 NPC 交互
3. 如果特定对话存在，应该看到特定对话
4. 如果特定对话不存在，应该看到随机闲聊

---

## 📚 更多信息

查看 [完整集成指南](./chatter_integration_guide.md) 了解更多高级用法。

