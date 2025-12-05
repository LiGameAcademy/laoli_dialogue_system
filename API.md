# API 文档

本文档提供了 Lao Li's Dialogue System 插件的完整 API 参考。

## 目录

- [核心管理器](#核心管理器)
  - [DialogueManager](#dialoguemanager)
  - [VariableManager](#variablemanager)
  - [DialogueHistoryManager](#dialoguehistorymanager)
  - [QuestManager](#questmanager)
- [资源类](#资源类)
  - [DialogueNode](#dialoguenode)
  - [DialogueOption](#dialogueoption)
  - [Quest](#quest)
  - [QuestObjective](#questobjective)
- [动作系统](#动作系统)
  - [GameAction](#gameaction)
  - [内置动作](#内置动作)
- [条件系统](#条件系统)
  - [GameCondition](#gamecondition)
  - [内置条件](#内置条件)
- [存档系统](#存档系统)
  - [DialogueSaveManager](#dialoguesavemanager)
  - [DialogueSaveStrategy](#dialoguesavestrategy)
- [工具类](#工具类)
  - [PerformanceProfiler](#performanceprofiler)

---

## 核心管理器

### DialogueManager

对话系统的核心管理器，全局单例。

#### 属性

```gdscript
var dialogue_graph: Dictionary[String, DialogueNode]  # 对话图
var current_node: DialogueNode  # 当前对话节点
var is_active: bool  # 对话系统是否正在运行
var save_manager: DialogueSaveManager  # 存档管理器
var performance_profiler: PerformanceProfiler  # 性能分析器
```

#### 信号

```gdscript
signal text_updated(character_name: String, text: String)
signal dialogue_started()
signal dialogue_finished()
signal choices_updated(choices: Array)
```

#### 方法

##### `load_dialogue_file(path: String, merge: bool = true) -> void`

加载并解析对话 JSON 文件。

**参数：**
- `path` - JSON 文件路径
- `merge` - 是否合并到现有对话图（默认 true）

**示例：**
```gdscript
DialogueManager.load_dialogue_file("res://data/dialogues/dialogue.json")
```

##### `start_dialogue(node_id: String) -> void`

开始对话。

**参数：**
- `node_id` - 对话节点 ID

**示例：**
```gdscript
DialogueManager.start_dialogue("village_chief_start")
```

##### `make_choice(choice_data: Dictionary) -> void`

处理玩家选择的选项。

**参数：**
- `choice_data` - 选项数据字典，包含 `text`、`next_node` 或 `option_resource`

**示例：**
```gdscript
DialogueManager.make_choice({
    "text": "接受任务",
    "next_node": "quest_accepted"
})
```

##### `register_action(action_type: String, action: GameAction) -> void`

注册自定义动作。

**参数：**
- `action_type` - 动作类型标识符
- `action` - 动作实例

**示例：**
```gdscript
DialogueManager.register_action("give_item", ActionGiveItem.new())
```

##### `register_condition(condition_type: String, condition: GameCondition) -> void`

注册自定义条件。

**参数：**
- `condition_type` - 条件类型标识符
- `condition` - 条件实例

**示例：**
```gdscript
DialogueManager.register_condition("has_item", ConditionHasItem.new())
```

##### `register_player_getter(getter: Callable) -> void`

注册玩家节点获取函数（用于解耦）。

**参数：**
- `getter` - 返回玩家节点的函数

**示例：**
```gdscript
DialogueManager.register_player_getter(func(): return get_tree().get_first_node_in_group("Player"))
```

##### `load_dialogue_file_async(path: String, merge: bool = true) -> void`

异步加载对话文件。

##### `release_unused_nodes(keep_recent: int = 50) -> void`

释放未使用的对话节点（内存管理）。

---

### VariableManager

变量管理器，全局单例。

#### 方法

##### `set_variable(name: String, value: Variant) -> void`

设置变量值。

**示例：**
```gdscript
VariableManager.set_variable("player_name", "Alice")
VariableManager.set_variable("player_level", 10)
```

##### `get_variable(name: String, default: Variant = null) -> Variant`

获取变量值。

**示例：**
```gdscript
var player_name = VariableManager.get_variable("player_name", "Unknown")
```

##### `get_all_variables() -> Dictionary`

获取所有变量（包括提供者的变量）。

##### `register_variable_provider(provider: Callable) -> void`

注册变量提供者。

**示例：**
```gdscript
VariableManager.register_variable_provider(func():
    return {
        "player_name": player.name,
        "player_level": player.level
    }
)
```

##### `batch_update_variables(updates: Dictionary) -> void`

批量更新变量。

**示例：**
```gdscript
VariableManager.batch_update_variables({
    "player_name": "Bob",
    "player_level": 15
})
```

#### 变量替换

在对话文本中使用 `{variable_name}` 进行变量替换：

```json
{
  "greeting": {
    "text": "Hello, {player_name}! Your level is {player_level}."
  }
}
```

#### 条件变量

支持条件变量解析，格式：`{condition_type:value}`

- `{has_item:sword}` - 检查是否持有物品
- `{quest_status:main_quest:in_progress}` - 检查任务状态

---

### DialogueHistoryManager

对话历史管理器，全局单例。

#### 方法

##### `add_entry(node_id: String, character_name: String, dialogue_text: String, choices: Array[String] = []) -> void`

添加对话历史条目。

##### `record_choice(node_id: String, choice_text: String) -> void`

记录玩家选择的选项。

##### `is_node_read(node_id: String) -> bool`

检查节点是否已读。

##### `get_history() -> Array[DialogueHistoryEntry]`

获取所有对话历史。

##### `get_history_by_character(character_name: String) -> Array[DialogueHistoryEntry]`

按角色获取对话历史。

##### `clear_history() -> void`

清空对话历史。

#### 信号

```gdscript
signal history_updated(entry: DialogueHistoryEntry)
signal node_marked_as_read(node_id: String)
```

---

### QuestManager

任务管理器，全局单例。

#### 枚举

```gdscript
enum QuestStatus {
    CAN_ACCEPT,      # 可以接取
    IN_PROGRESS,     # 进行中
    READY_TO_TURN_IN, # 可交付
    FINISHED,        # 已完成
    UNAVAILABLE      # 不可用
}
```

#### 属性

```gdscript
var active_quests: Array[Quest]  # 活跃任务列表
var completed_quest_ids: Array[String]  # 已完成任务 ID 列表
```

#### 方法

##### `accept_quest_by_id(quest_id: String) -> bool`

接取任务。

##### `get_quest_status(quest_id: String) -> QuestStatus`

获取任务状态。

##### `register_game_event_signal(signal_instance: Signal) -> void`

注册游戏事件信号（用于解耦）。

##### `register_quest_database_provider(provider: Callable) -> void`

注册任务数据库查询函数。

##### `register_quest_resource_getter(getter: Callable) -> void`

注册任务资源获取函数。

#### 信号

```gdscript
signal quest_accepted(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_ready_to_turn_in(quest: Quest)
signal quest_turned_in(quest: Quest)
signal quest_updated(quest: Quest)
signal quests_loaded()
```

---

## 资源类

### DialogueNode

对话节点资源。

#### 属性

```gdscript
@export var node_id: String  # 节点唯一标识
@export var character_key: String  # 角色名称本地化键
@export var text_key: String  # 对话文本本地化键（单个）
@export var text_keys: Array[String]  # 对话文本本地化键数组（随机）
@export var text_weights: Array[float]  # 文本权重（加权随机）
@export var options: Array[DialogueOption]  # 选项列表
@export var actions: Array[GameAction]  # 动作列表
@export var next_node_id: String  # 下一节点 ID（单线对话）
@export var metadata: Dictionary  # 元数据
```

#### 方法

##### `get_character_name() -> String`

获取本地化后的角色名称。

##### `get_text() -> String`

获取本地化后的对话文本（支持变量替换和随机选择）。

##### `has_choices() -> bool`

检查是否有选项。

##### `get_available_options(player: Node) -> Array[DialogueOption]`

获取可用的选项（过滤条件不满足的）。

---

### DialogueOption

对话选项资源。

#### 属性

```gdscript
@export var text_key: String  # 选项文本本地化键
@export var next_node_id: String  # 下一节点 ID
@export var condition: GameCondition  # 显示条件
@export var actions: Array[GameAction]  # 动作列表
```

#### 方法

##### `get_text() -> String`

获取本地化后的选项文本。

##### `get_display_text(player: Node) -> String`

获取显示文本（支持变量替换）。

##### `is_available(player: Node) -> bool`

检查选项是否可用（条件检查）。

---

### Quest

任务资源。

#### 属性

```gdscript
@export var id: String  # 任务 ID
@export var title: String  # 任务标题
@export var description: String  # 任务描述
@export var objectives: Array[QuestObjective]  # 任务目标列表
```

#### 方法

##### `start() -> void`

启动任务。

##### `check_completion() -> bool`

检查任务是否完成。

---

### QuestObjective

任务目标基类（抽象类）。

#### 子类

- `ObjectiveKill` - 击杀目标
- `ObjectiveCollect` - 收集目标

#### 属性

```gdscript
@export var description: String  # 目标描述
var is_completed: bool  # 是否已完成
```

#### 方法

##### `on_game_event(event_type: String, data: Dictionary) -> void`

处理游戏事件（抽象方法）。

##### `get_progress_text() -> String`

获取进度文本（抽象方法）。

---

## 动作系统

### GameAction

游戏动作基类（抽象类）。

#### 方法

##### `execute(initiator: Node, target: Node) -> bool`

执行动作（抽象方法）。

**返回值：** 是否执行成功

#### 内置动作

##### ActionStartDialogue

启动对话。

**属性：**
```gdscript
@export var dialogue_node_id: String  # 对话节点 ID
@export var condition: GameCondition  # 执行条件
```

##### ActionStartQuest

启动任务。

**属性：**
```gdscript
@export var quest_id: String  # 任务 ID
```

##### ActionTurnInQuest

交付任务。

**属性：**
```gdscript
@export var quest_id: String  # 任务 ID
```

##### ActionPlaySound

播放音效。

**属性：**
```gdscript
@export var sound_path: String  # 音效路径
```

##### ActionDebugPrint

调试打印。

**属性：**
```gdscript
@export var message: String  # 打印消息
```

---

## 条件系统

### GameCondition

游戏条件基类（抽象类）。

#### 方法

##### `check(activator: Node) -> bool`

检查条件（抽象方法）。

**返回值：** 条件是否满足

#### 内置条件

##### ConditionQuestStatus

任务状态条件。

**属性：**
```gdscript
@export var quest_id: String  # 任务 ID
@export var required_status: QuestManager.QuestStatus  # 要求的状态
```

---

## 存档系统

### DialogueSaveManager

对话存档管理器。

#### 属性

```gdscript
var save_strategy: DialogueSaveStrategy  # 存档策略
```

#### 方法

##### `set_save_strategy(strategy: DialogueSaveStrategy) -> void`

设置存档策略。

##### `save_dialogue_history() -> bool`

保存对话历史。

##### `load_dialogue_history() -> bool`

加载对话历史。

##### `save_quest_data() -> bool`

保存任务数据。

##### `load_quest_data() -> bool`

加载任务数据。

##### `save_all() -> bool`

保存所有数据。

##### `load_all() -> bool`

加载所有数据。

---

### DialogueSaveStrategy

存档策略接口（抽象类）。

#### 方法

##### `save_dialogue_history(history_data: Dictionary) -> bool`

保存对话历史（抽象方法）。

##### `load_dialogue_history() -> Dictionary`

加载对话历史（抽象方法）。

##### `save_quest_data(quest_data: Dictionary) -> bool`

保存任务数据（抽象方法）。

##### `load_quest_data() -> Dictionary`

加载任务数据（抽象方法）。

#### 默认实现

`DefaultDialogueSaveStrategy` - 使用本地文件保存/加载。

---

## 工具类

### PerformanceProfiler

性能分析器。

#### 方法

##### `start_profiling(label: String) -> void`

开始性能分析。

##### `end_profiling(label: String) -> float`

结束性能分析，返回耗时（毫秒）。

##### `profile_function(label: String, func_to_profile: Callable) -> void`

分析函数执行时间。

##### `get_stats(label: String = "") -> Dictionary`

获取性能统计。

**返回值：**
```gdscript
{
    "count": int,        # 调用次数
    "total_time": float, # 总耗时
    "avg_time": float,   # 平均耗时
    "min_time": float,   # 最小耗时
    "max_time": float    # 最大耗时
}
```

##### `print_report(label: String = "") -> void`

打印性能报告。

##### `clear_stats() -> void`

清空统计数据。

---

## JSON 格式参考

### 对话文件格式

```json
{
  "node_id": {
    "character_key": "CHARACTER_NAME",
    "text_key": "DIALOGUE_TEXT",
    "text_keys": ["TEXT_1", "TEXT_2"],
    "text_weights": [1.0, 0.5],
    "options": [
      {
        "text_key": "CHOICE_TEXT",
        "next_node_id": "next_node",
        "condition": {
          "type": "quest_status",
          "quest_id": "quest_id",
          "required_status": "in_progress"
        },
        "actions": [
          {
            "type": "start_quest",
            "quest_id": "quest_id"
          }
        ]
      }
    ],
    "actions": [
      {
        "type": "play_sound",
        "sound_path": "res://sounds/effect.mp3"
      }
    ],
    "next_node_id": "next_node"
  }
}
```

---

## 扩展指南

### 创建自定义动作

```gdscript
extends GameAction
class_name ActionCustom

@export var custom_param: String

func execute(initiator: Node, target: Node) -> bool:
    # 实现自定义逻辑
    print("执行自定义动作: ", custom_param)
    return true

# 注册
DialogueManager.register_action("custom", ActionCustom.new())
```

### 创建自定义条件

```gdscript
extends GameCondition
class_name ConditionCustom

@export var custom_param: String

func check(activator: Node) -> bool:
    # 实现条件检查逻辑
    return true

# 注册
DialogueManager.register_condition("custom", ConditionCustom.new())
```

### 创建自定义存档策略

```gdscript
extends DialogueSaveStrategy
class_name CustomSaveStrategy

func save_dialogue_history(history_data: Dictionary) -> bool:
    # 实现自定义保存逻辑
    return true

func load_dialogue_history() -> Dictionary:
    # 实现自定义加载逻辑
    return {}

# 使用
DialogueManager.save_manager.set_save_strategy(CustomSaveStrategy.new())
```

---

## 最佳实践

1. **解耦设计**：使用依赖注入，避免插件直接依赖业务层
2. **信号驱动**：使用信号进行系统间通信
3. **资源管理**：及时释放未使用的对话节点
4. **性能优化**：使用缓存和批量更新
5. **错误处理**：检查节点和资源是否存在

---

**最后更新：** 2024

