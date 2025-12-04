# 随机对话与多文件管理系统

本文档说明如何使用随机对话和多文件管理功能。

## 📋 功能概述

### 1. 随机文本对话
- 支持单个文本和随机文本数组
- 支持加权随机选择
- 支持非重复随机选择（避免连续相同）

### 2. 多文件管理
- 支持加载多个对话JSON文件
- 支持卸载指定文件
- 支持清空所有对话
- 支持重新加载所有文件
- 支持按需加载（懒加载）

### 3. 闲聊系统
- 自动触发NPC闲聊
- 控制闲聊间隔
- 支持强制触发

---

## 🚀 快速开始

### 1. 基本使用

```gdscript
# 加载对话文件
DialogueManager.load_dialogue_file("res://data/dialogues/main_dialogue.json")
DialogueManager.load_dialogue_file("res://data/dialogues/village_dialogue.json")

# 开始对话
DialogueManager.start_dialogue("village_chief_greeting")
```

### 2. 随机文本格式

**JSON格式：**

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

**加权随机（可选）：**

```json
{
  "village_chief_chatter": {
    "character": "CHARACTER_VILLAGE_CHIEF",
    "text": [
      "VILLAGE_CHIEF_CHATTER_1",
      "VILLAGE_CHIEF_CHATTER_2",
      "VILLAGE_CHIEF_CHATTER_3"
    ],
    "text_weights": [1.0, 2.0, 1.0],
    "next_node": "END"
  }
}
```

### 3. 多文件管理

```gdscript
# 加载多个文件
DialogueManager.load_dialogue_file("res://data/dialogues/main_dialogue.json")
DialogueManager.load_dialogue_file("res://data/dialogues/village_dialogue.json", true)  # merge=true

# 卸载文件
DialogueManager.unload_dialogue_file("res://data/dialogues/village_dialogue.json")

# 清空所有
DialogueManager.clear_all_dialogues()

# 重新加载所有
DialogueManager.reload_all_files()

# 按需加载
DialogueManager.load_dialogue_if_needed("some_node_id")
```

### 4. 闲聊系统

```gdscript
# 尝试触发闲聊（会检查间隔）
ChatterManager.try_trigger_chatter("village_chief")

# 强制触发闲聊（忽略间隔）
ChatterManager.force_trigger_chatter("village_chief")
```

---

## 📝 文章错误修正

### 错误1：ChatterManager 的节点ID格式

**文章中的代码：**
```gdscript
const CHATTER_PREFIX = "_chatter"
var chatter_node_id = npc_id + CHATTER_PREFIX
```

**问题：** 使用 `PREFIX`（前缀）但实际是后缀

**修正：** 改为 `CHATTER_SUFFIX`（后缀），更符合命名规范

### 错误2：DialogueManager.load_dialogue_file 参数

**文章中的代码：**
```gdscript
func load_dialogue_file(path: String, merge: bool = true) -> void:
```

**问题：** 文章中没有说明 `merge` 参数的作用

**修正：** 已在实现中添加详细注释说明

### 错误3：unload_dialogue_file 的实现

**文章中的代码：**
```gdscript
func unload_dialogue_file(path: String) -> void:
	# 重新加载文件以获取节点ID列表
	var temp_dialogues = dialogue_parser.parse_dialogue_file(path)
```

**问题：** 如果文件很大，重新解析可能影响性能

**建议：** 可以在加载时记录节点ID列表，但当前实现已经足够使用

### 错误4：ChatterManager 的单例注册

**文章中的代码：** 没有说明如何注册 ChatterManager

**修正：** ChatterManager 需要手动注册为 AutoLoad 单例，或通过代码创建实例

---

## 🎯 最佳实践

### 1. 文件组织

```
res://data/dialogues/
├── main_dialogue.json          # 主线对话
├── village_dialogue.json       # 村庄对话
├── forest_dialogue.json        # 森林对话
├── random_chatter.json         # 随机闲聊
└── quest_dialogue.json         # 任务对话
```

### 2. 节点ID命名规范

- **闲聊节点**：`{npc_id}_chatter`（如：`village_chief_chatter`）
- **普通对话**：`{npc_id}_{dialogue_type}`（如：`village_chief_greeting`）
- **任务对话**：`quest_{quest_id}_{stage}`（如：`quest_01_start`）

### 3. 性能优化

- 使用 `load_dialogue_if_needed()` 进行懒加载
- 及时卸载不需要的对话文件
- 使用 `merge=false` 替换整个对话图（谨慎使用）

---

## 📚 API 参考

### DialogueManager

#### `load_dialogue_file(path: String, merge: bool = true) -> void`
加载对话文件。

#### `unload_dialogue_file(path: String) -> void`
卸载对话文件。

#### `clear_all_dialogues() -> void`
清空所有对话数据。

#### `reload_all_files() -> void`
重新加载所有已加载的文件。

#### `load_dialogue_if_needed(node_id: String, search_paths: Array[String] = []) -> bool`
按需加载对话文件。

### DialogueNode

#### `get_text() -> String`
获取本地化后的文本（支持随机选择）。

### ChatterManager

#### `try_trigger_chatter(npc_id: String) -> bool`
尝试触发NPC的闲聊。

#### `force_trigger_chatter(npc_id: String) -> void`
强制触发闲聊（忽略间隔）。

---

## 🔧 集成示例

### NPC 集成闲聊

```gdscript
# npc.gd
extends CharacterBody3D

@export var npc_id: String = ""
@export var enable_chatter: bool = true

var chatter_timer: Timer

func _ready() -> void:
	if enable_chatter:
		_setup_chatter_timer()

func _setup_chatter_timer() -> void:
	chatter_timer = Timer.new()
	chatter_timer.wait_time = 60.0  # 每60秒尝试一次
	chatter_timer.timeout.connect(_on_chatter_timer_timeout)
	chatter_timer.autostart = true
	add_child(chatter_timer)

func _on_chatter_timer_timeout() -> void:
	if not DialogueManager.is_active:
		ChatterManager.try_trigger_chatter(npc_id)
```

### 区域切换时加载对话

```gdscript
# room_manager.gd
extends Node

func transition_to_room(room_name: String) -> void:
	# 加载该区域的对话文件
	var dialogue_file = "res://data/dialogues/%s_dialogue.json" % room_name.to_lower()
	if ResourceLoader.exists(dialogue_file):
		DialogueManager.load_dialogue_file(dialogue_file)
```

---

## ⚠️ 注意事项

1. **节点ID冲突**：合并文件时，如果节点ID重复，后加载的会覆盖先加载的
2. **内存管理**：及时卸载不需要的对话文件，避免内存占用过大
3. **闲聊间隔**：默认30秒，可以根据需要调整 `MIN_CHATTER_INTERVAL`
4. **ChatterManager 单例**：需要手动注册为 AutoLoad 单例，或创建全局实例

---

## 🐛 已知问题

无

---

## 📖 相关文档

- [对话系统核心文档](../README.md)
- [DialogueNode API](../scripts/core/dialogue/dialogue_node.gd)
- [DialogueManager API](../scripts/core/dialogue/dialogue_manager.gd)

