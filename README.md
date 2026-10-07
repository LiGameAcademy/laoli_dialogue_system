# Lao Li's Dialogue System

[![Godot Engine](https://img.shields.io/badge/Godot-4.5+-478CBF?logo=godot-engine)](https://godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.0.1-green.svg)](plugin.cfg)

一个功能强大、数据驱动、可本地化、可扩展的对话系统插件，专为 Godot 4.5+ 设计。

## ✨ 特性

### 核心功能

- 📝 **数据驱动**：使用 JSON 文件定义对话，无需编写代码
- 🌍 **多语言支持**：完整的本地化系统，支持多语言切换
- 🎯 **条件系统**：支持条件分支，根据游戏状态显示不同对话
- ⚡ **动作系统**：可扩展的动作系统，支持自定义游戏逻辑
- 📚 **对话历史**：自动记录对话历史，支持查看已读标记
- 💾 **存档系统**：支持对话历史和任务状态的保存/加载
- 🎮 **任务系统**：内置任务管理，支持任务目标追踪
- 🔤 **变量系统**：支持变量替换和条件变量解析
- 🎨 **主题系统**：可自定义对话 UI 主题
- 🚀 **性能优化**：内置缓存、批量更新、内存管理等优化

### 高级特性

- 🔄 **随机对话**：支持随机文本选择和加权随机
- 📦 **多文件管理**：支持加载、卸载、合并多个对话文件
- 🎭 **条件对话**：根据任务状态、物品持有等条件显示对话
- 🔍 **调试工具**：内置调试面板（F3），实时查看系统状态
- 📊 **性能分析**：内置性能分析器，帮助定位性能瓶颈
- 🏗️ **可扩展架构**：基于工厂模式和策略模式，易于扩展

## 剧情演出（开发版）

新增局部 CutscenePlayer、带编号的对话会话、步骤校验和终结日志。宿主负责表现与规则提交。详见 [接入契约与验证方法](docs/cutscenes.md)。此能力尚未发布新版本；跨读档的叙事检查点仍待实现。

## 📦 安装

### 方法 1: 直接复制（推荐）

1. 将 `addons/laoli_dialogue_system` 文件夹复制到你的项目 `addons/` 目录
2. 在 Godot 编辑器中，打开 `项目 > 项目设置 > 插件`
3. 启用 "Lao Li's Dialogue System" 插件

### 方法 2: Git Submodule

```bash
cd your_project
git submodule add <repository_url> addons/laoli_dialogue_system
```

## 🚀 快速开始

### 1. 创建对话文件

创建 `res://data/dialogues/dialogue.json`：

```json
{
  "village_chief_start": {
    "character_key": "CHARACTER_VILLAGE_CHIEF",
    "text_key": "DIALOGUE_WELCOME",
    "options": [
      {
        "text_key": "CHOICE_ACCEPT_QUEST",
        "next_node_id": "quest_accepted",
        "actions": [
          {
            "type": "start_quest",
            "quest_id": "chief_forest_quest"
          }
        ]
      },
      {
        "text_key": "CHOICE_DECLINE",
        "next_node_id": "quest_declined"
      }
    ]
  },
  "quest_accepted": {
    "character_key": "CHARACTER_VILLAGE_CHIEF",
    "text_key": "DIALOGUE_QUEST_ACCEPTED",
    "next_node_id": "END"
  }
}
```

### 2. 创建本地化文件

创建 `res://localization/translations.csv`：

```csv
keys,en,zh_CN
CHARACTER_VILLAGE_CHIEF,Village Chief,村长
DIALOGUE_WELCOME,Welcome, traveler!,欢迎，旅行者！
CHOICE_ACCEPT_QUEST,Accept Quest,接受任务
CHOICE_DECLINE,Maybe later...,稍后再说...
DIALOGUE_QUEST_ACCEPTED,Good luck!,祝你好运！
```

### 3. 加载对话文件

```gdscript
# 在游戏初始化时
func _ready():
    DialogueManager.load_dialogue_file("res://data/dialogues/dialogue.json")
```

### 4. 启动对话

```gdscript
# 当玩家与 NPC 交互时
func _on_npc_interacted():
    DialogueManager.start_dialogue("village_chief_start")
```

### 5. 连接 UI

```gdscript
# 连接信号到 UI
DialogueManager.text_updated.connect(_on_text_updated)
DialogueManager.choices_updated.connect(_on_choices_updated)
DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func _on_text_updated(character_name: String, text: String):
    character_label.text = character_name
    dialogue_label.text = text

func _on_choices_updated(choices: Array):
    # 显示选项
    for choice in choices:
        var button = Button.new()
        button.text = choice.text
        button.pressed.connect(func(): DialogueManager.make_choice(choice))
        choices_container.add_child(button)
```

## 📖 文档

- [API 文档](API.md) - 完整的 API 参考
- [快速开始指南](docs/QUICK_START.md) - 详细的使用教程
- [示例项目](https://github.com/your-repo/example) - 完整示例项目

## 🎯 核心概念

### 对话节点 (DialogueNode)

对话的基本单位，包含：
- 角色名称（本地化键）
- 对话文本（支持随机选择）
- 选项列表
- 动作列表
- 下一节点 ID

### 选项 (DialogueOption)

对话选项，包含：
- 显示文本
- 条件检查
- 动作列表
- 下一节点 ID

### 动作 (GameAction)

在对话中执行的操作，例如：
- 启动任务
- 给予物品
- 播放音效
- 启动新对话

### 条件 (GameCondition)

控制选项和对话的显示条件，例如：
- 任务状态检查
- 物品持有检查
- 变量值检查

## 🔧 配置

### 注册自定义动作

```gdscript
# 创建自定义动作
extends GameAction
class_name ActionGiveItem

@export var item_id: String
@export var amount: int = 1

func execute(initiator: Node, target: Node) -> bool:
    # 实现给予物品逻辑
    return true

# 注册动作
DialogueManager.register_action("give_item", ActionGiveItem.new())
```

### 注册自定义条件

```gdscript
# 创建自定义条件
extends GameCondition
class_name ConditionHasItem

@export var item_id: String
@export var required_amount: int = 1

func check(activator: Node) -> bool:
    # 实现物品检查逻辑
    return false

# 注册条件
DialogueManager.register_condition("has_item", ConditionHasItem.new())
```

### 注册变量提供者

```gdscript
# 提供游戏变量
func _provide_game_variables() -> Dictionary:
    return {
        "player_name": player.name,
        "player_level": player.level,
        "gold": inventory.gold
    }

VariableManager.register_variable_provider(_provide_game_variables)
```

## 🎨 UI 组件

插件提供了以下 UI 组件：

- `DialogueUI` - 对话显示 UI
- `QuestLogUI` - 任务日志 UI
- `DebugPanel` - 调试面板（按 F3 切换）

## 🔍 调试

### 调试面板

按 `F3` 键打开调试面板，可以查看：
- 对话系统状态
- 任务系统信息
- 变量系统信息
- 性能统计

### 性能分析

```gdscript
# 测量代码执行时间
DialogueManager.performance_profiler.start_profiling("my_function")
# ... 执行代码 ...
DialogueManager.performance_profiler.end_profiling("my_function")

# 查看统计
var stats = DialogueManager.performance_profiler.get_stats("my_function")
print("平均耗时: %.2f ms" % stats.avg_time)
```

## 📝 示例

### 条件对话

```json
{
  "npc_dialogue": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_GREETING",
    "options": [
      {
        "text_key": "CHOICE_ASK_QUEST",
        "next_node_id": "quest_info",
        "condition": {
          "type": "quest_status",
          "quest_id": "main_quest",
          "status": "can_accept"
        }
      }
    ]
  }
}
```

### 变量替换

```json
{
  "player_greeting": {
    "character_key": "CHARACTER_NPC",
    "text_key": "DIALOGUE_GREETING_PLAYER",
    "text": "Hello, {player_name}! Your level is {player_level}."
  }
}
```

### 随机对话

```json
{
  "random_chatter": {
    "character_key": "CHARACTER_NPC",
    "text_keys": [
      "CHATTER_1",
      "CHATTER_2",
      "CHATTER_3"
    ],
    "text_weights": [1.0, 1.0, 0.5]
  }
}
```

## 🏗️ 架构设计

### 核心组件

- **DialogueManager** - 对话管理器（全局单例）
- **VariableManager** - 变量管理器（全局单例）
- **DialogueHistoryManager** - 对话历史管理器（全局单例）
- **QuestManager** - 任务管理器（全局单例）

### 设计模式

- **工厂模式** - ActionFactory, ConditionFactory
- **策略模式** - DialogueSaveStrategy
- **观察者模式** - 信号系统
- **组合模式** - 组件化设计

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 👤 作者

**玩物不丧志的老李**

- GitHub: [老李游戏学院](https://github.com/LiGameAcademy)
- 项目主页: [项目链接](https://github.com/LiGameAcademy/laoli_dialogue_system.git)

## 🙏 致谢

感谢所有贡献者和使用者的支持！

---

**Made with ❤️ for the Godot community**

