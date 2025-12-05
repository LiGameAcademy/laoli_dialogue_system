# 快速开始指南

本指南将帮助你快速上手使用 Lao Li's Dialogue System。

## 📋 目录

1. [安装插件](#安装插件)
2. [创建第一个对话](#创建第一个对话)
3. [设置本地化](#设置本地化)
4. [连接 UI](#连接-ui)
5. [添加条件对话](#添加条件对话)
6. [使用变量](#使用变量)
7. [集成任务系统](#集成任务系统)

---

## 安装插件

1. 将 `addons/laoli_dialogue_system` 复制到你的项目
2. 在 Godot 编辑器中启用插件：`项目 > 项目设置 > 插件`
3. 启用 "Lao Li's Dialogue System"

---

## 创建第一个对话

### 步骤 1: 创建对话文件

创建 `res://data/dialogues/first_dialogue.json`：

```json
{
  "greeting": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_GREETING",
    "options": [
      {
        "text_key": "CHOICE_YES",
        "next_node_id": "positive_response"
      },
      {
        "text_key": "CHOICE_NO",
        "next_node_id": "negative_response"
      }
    ]
  },
  "positive_response": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_POSITIVE",
    "next_node_id": "END"
  },
  "negative_response": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_NEGATIVE",
    "next_node_id": "END"
  }
}
```

### 步骤 2: 加载对话

在你的游戏初始化脚本中：

```gdscript
func _ready():
    # 加载对话文件
    DialogueManager.load_dialogue_file("res://data/dialogues/first_dialogue.json")
    
    # 连接信号
    DialogueManager.text_updated.connect(_on_text_updated)
    DialogueManager.choices_updated.connect(_on_choices_updated)
    DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
```

### 步骤 3: 启动对话

```gdscript
func _on_npc_interacted():
    DialogueManager.start_dialogue("greeting")
```

---

## 设置本地化

### 步骤 1: 创建翻译文件

创建 `res://localization/translations.csv`：

```csv
keys,en,zh_CN
CHARACTER_NPC,Friendly NPC,友好的NPC
DIALOGUE_GREETING,Hello! How are you?,你好！你好吗？
CHOICE_YES,I'm fine, thanks!,我很好，谢谢！
CHOICE_NO,Not so good...,不太好...
DIALOGUE_POSITIVE,That's great!,太好了！
DIALOGUE_NEGATIVE,I'm sorry to hear that.,听到这个消息我很遗憾。
```

### 步骤 2: 导入翻译文件

1. 在 Godot 编辑器中，选择 `项目 > 项目设置 > 本地化`
2. 点击 "添加..." 按钮
3. 选择你的 `translations.csv` 文件
4. 添加语言代码（如 `en`、`zh_CN`）

### 步骤 3: 设置默认语言

在项目设置中设置默认语言，或在代码中：

```gdscript
TranslationServer.set_locale("zh_CN")
```

---

## 连接 UI

### 使用内置 UI

插件提供了 `DialogueUI` 组件，可以直接使用：

```gdscript
# 在场景中添加 DialogueUI 节点
# 或使用代码：
var dialogue_ui = preload("res://addons/laoli_dialogue_system/ui/dialogue_ui.tscn").instantiate()
get_tree().root.add_child(dialogue_ui)
```

### 自定义 UI

```gdscript
func _on_text_updated(character_name: String, text: String):
    # 更新角色名称显示
    character_label.text = character_name
    
    # 更新对话文本显示
    dialogue_label.text = text

func _on_choices_updated(choices: Array):
    # 清空现有选项
    for child in choices_container.get_children():
        child.queue_free()
    
    # 创建选项按钮
    for choice in choices:
        var button = Button.new()
        button.text = choice.text
        button.pressed.connect(func(): DialogueManager.make_choice(choice))
        choices_container.add_child(button)

func _on_dialogue_finished():
    # 隐藏对话 UI
    dialogue_panel.hide()
```

---

## 添加条件对话

### 步骤 1: 注册条件

```gdscript
# 创建自定义条件
extends GameCondition
class_name ConditionHasItem

@export var item_id: String
@export var required_amount: int = 1

func check(activator: Node) -> bool:
    # 实现物品检查逻辑
    var inventory = activator.get_inventory()
    return inventory.has_item(item_id, required_amount)

# 注册条件
DialogueManager.register_condition("has_item", ConditionHasItem.new())
```

### 步骤 2: 在对话中使用条件

```json
{
  "shop_dialogue": {
    "character_key": "CHARACTER_SHOPKEEPER",
    "text_key": "DIALOGUE_SHOP_GREETING",
    "options": [
      {
        "text_key": "CHOICE_BUY_SWORD",
        "next_node_id": "buy_sword",
        "condition": {
          "type": "has_item",
          "item_id": "gold",
          "required_amount": 100
        }
      }
    ]
  }
}
```

---

## 使用变量

### 步骤 1: 设置变量

```gdscript
# 直接设置
VariableManager.set_variable("player_name", "Alice")
VariableManager.set_variable("player_level", 10)

# 批量设置
VariableManager.batch_update_variables({
    "player_name": "Bob",
    "player_level": 15,
    "gold": 1000
})
```

### 步骤 2: 注册变量提供者

```gdscript
func _provide_game_variables() -> Dictionary:
    return {
        "player_name": player.name,
        "player_level": player.level,
        "gold": inventory.gold,
        "health": player.health,
        "max_health": player.max_health
    }

VariableManager.register_variable_provider(_provide_game_variables)
```

### 步骤 3: 在对话中使用变量

```json
{
  "player_greeting": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_GREETING_PLAYER",
    "text": "Hello, {player_name}! Your level is {player_level}."
  }
}
```

### 条件变量

```json
{
  "item_dialogue": {
    "character_key": "CHARACTER_NPC",
    "text": "You have {has_item:sword:Yes:No} a sword."
  }
}
```

---

## 集成任务系统

### 步骤 1: 创建任务资源

在编辑器中创建 `Quest` 资源：

```gdscript
# 或使用代码创建
var quest = Quest.new()
quest.id = "first_quest"
quest.title = "First Quest"
quest.description = "Complete your first quest"

var objective = ObjectiveKill.new()
objective.target_enemy_id = "skeleton"
objective.required_amount = 5
objective.description = "Kill 5 skeletons"

quest.objectives = [objective]
```

### 步骤 2: 注册任务

```gdscript
# 在游戏初始化时
func _ready():
    # 注册任务到任务数据库
    GameState.register_quest(quest)
    
    # 注册任务相关回调
    QuestManager.register_game_event_signal(GameState.game_event_occurred)
    QuestManager.register_quest_database_provider(GameState._check_quest_in_database)
    QuestManager.register_quest_resource_getter(GameState._get_quest_resource)
```

### 步骤 3: 在对话中启动任务

```json
{
  "quest_giver": {
    "character_key": "CHARACTER_QUEST_GIVER",
    "text_key": "DIALOGUE_QUEST_OFFER",
    "options": [
      {
        "text_key": "CHOICE_ACCEPT",
        "next_node_id": "quest_accepted",
        "actions": [
          {
            "type": "start_quest",
            "quest_id": "first_quest"
          }
        ]
      }
    ]
  }
}
```

### 步骤 4: 显示任务日志

```gdscript
# 使用内置任务日志 UI
var quest_log_ui = preload("res://addons/laoli_dialogue_system/ui/quest_log_ui.tscn").instantiate()
get_tree().root.add_child(quest_log_ui)
```

---

## 下一步

- 查看 [API 文档](../API.md) 了解完整 API
- 查看 [README](../README.md) 了解更多功能
- 探索示例项目

---

## 常见问题

### Q: 如何实现多分支对话？

A: 使用 `options` 数组创建多个选项，每个选项指向不同的 `next_node_id`。

### Q: 如何实现随机对话？

A: 使用 `text_keys` 数组和 `text_weights` 数组实现随机文本选择。

### Q: 如何保存对话历史？

A: 使用 `DialogueManager.save_manager.save_dialogue_history()` 保存，使用 `load_dialogue_history()` 加载。

### Q: 如何自定义 UI 样式？

A: 使用 `DialogueTheme` 资源自定义 UI 主题，或直接修改 `DialogueUI` 场景。

---

**祝你使用愉快！** 🎮

