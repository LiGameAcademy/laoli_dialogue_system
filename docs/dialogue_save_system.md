# 对话存档系统使用指南

## 概述

对话存档系统使用**策略模式**设计，允许插件用户扩展自己的存档策略。系统默认提供基于本地文件的存档策略，同时支持自定义存档策略（如云存档、数据库存储等）。

## 架构设计

### 核心组件

1. **DialogueSaveStrategy**（接口）
   - 存档策略接口，定义 `save_dialogue_history()` 和 `load_dialogue_history()` 方法

2. **DefaultDialogueSaveStrategy**（默认实现）
   - 使用本地文件存储对话历史
   - 文件路径：`user://dialogue_history.dat`

3. **DialogueSaveManager**（管理器）
   - 对话存档管理器，作为 `DialogueManager` 的属性单例
   - 负责调用存档策略进行保存和加载

## 基本使用

### 1. 保存对话历史

```gdscript
# 使用默认策略保存
DialogueManager.save_manager.save_dialogue_history()
```

### 2. 加载对话历史

```gdscript
# 使用默认策略加载
DialogueManager.save_manager.load_dialogue_history()
```

### 3. 保存任务状态

```gdscript
# 使用默认策略保存任务状态
DialogueManager.save_manager.save_quest_data()
```

### 4. 加载任务状态

```gdscript
# 使用默认策略加载任务状态
DialogueManager.save_manager.load_quest_data()
```

### 5. 保存/加载所有数据（推荐）

```gdscript
# 保存对话历史和任务状态
DialogueManager.save_manager.save_all()

# 加载对话历史和任务状态
DialogueManager.save_manager.load_all()
```

**注意**：使用任务状态存档功能前，需要在业务层注册任务资源获取函数：

```gdscript
# 在 GameState._ready() 中
DialogueManager.register_quest_resource_getter_for_save(_get_quest_resource)
```

## 自定义存档策略

### 示例：创建云存档策略

```gdscript
extends DialogueSaveStrategy
class_name CloudDialogueSaveStrategy

## 云存档策略示例
## 将对话历史和任务状态保存到云端服务器

var api_url: String = "https://api.example.com/save"

func _init(p_api_url: String) -> void:
	api_url = p_api_url

func save_dialogue_history(history_data: Dictionary) -> bool:
	# 实现云存档逻辑
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 将数据转换为 JSON
	var json_string = JSON.stringify(history_data)
	
	# 发送 HTTP POST 请求
	http_request.request(api_url + "/dialogue", [], HTTPClient.METHOD_POST, json_string)
	
	# 等待响应（实际实现中需要处理异步）
	# ...
	
	return true

func load_dialogue_history() -> Dictionary:
	# 实现云读档逻辑
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 发送 HTTP GET 请求
	http_request.request(api_url + "/dialogue")
	
	# 等待响应并解析（实际实现中需要处理异步）
	# ...
	
	return {}

func save_quest_data(quest_data: Dictionary) -> bool:
	# 实现任务状态云存档逻辑
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var json_string = JSON.stringify(quest_data)
	http_request.request(api_url + "/quests", [], HTTPClient.METHOD_POST, json_string)
	
	# 等待响应（实际实现中需要处理异步）
	# ...
	
	return true

func load_quest_data() -> Dictionary:
	# 实现任务状态云读档逻辑
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request(api_url + "/quests")
	
	# 等待响应并解析（实际实现中需要处理异步）
	# ...
	
	return {}
```

### 使用自定义策略

```gdscript
# 创建自定义策略实例
var cloud_strategy = CloudDialogueSaveStrategy.new("https://api.example.com/save")

# 设置策略
DialogueManager.save_manager.set_save_strategy(cloud_strategy)

# 现在保存和加载都会使用云存档策略
DialogueManager.save_manager.save_dialogue_history()
DialogueManager.save_manager.load_dialogue_history()
```

### 示例：创建数据库存档策略

```gdscript
extends DialogueSaveStrategy
class_name DatabaseDialogueSaveStrategy

## 数据库存档策略示例
## 将对话历史保存到数据库

var db_connection: Object  # 数据库连接对象

func _init(p_db_connection: Object) -> void:
	db_connection = p_db_connection

func save_dialogue_history(history_data: Dictionary) -> bool:
	# 实现数据库保存逻辑
	# 例如：使用 SQLite 或其他数据库
	# ...
	return true

func load_dialogue_history() -> Dictionary:
	# 实现数据库读取逻辑
	# ...
	return {}
```

## 与游戏存档系统集成

如果游戏有专门的存档模块，可以将对话历史集成到游戏存档中：

```gdscript
extends DialogueSaveStrategy
class_name GameSaveDialogueStrategy

## 游戏存档策略
## 将对话历史集成到游戏存档系统中

var game_save_system: Object  # 游戏存档系统引用

func _init(p_game_save_system: Object) -> void:
	game_save_system = p_game_save_system

func save_dialogue_history(history_data: Dictionary) -> bool:
	# 将对话历史数据添加到游戏存档数据中
	var game_save_data = game_save_system.get_save_data()
	game_save_data["dialogue_history"] = history_data
	game_save_system.set_save_data(game_save_data)
	return true

func load_dialogue_history() -> Dictionary:
	# 从游戏存档数据中读取对话历史
	var game_save_data = game_save_system.get_save_data()
	return game_save_data.get("dialogue_history", {})
```

使用方式：

```gdscript
# 假设游戏有 GameSaveSystem 单例
var game_save_strategy = GameSaveDialogueStrategy.new(GameSaveSystem)
DialogueManager.save_manager.set_save_strategy(game_save_strategy)
```

## 默认策略配置

默认策略使用 `user://dialogue_history.dat` 作为存档文件路径。如果需要自定义路径：

```gdscript
# 创建自定义路径的默认策略
var custom_strategy = DefaultDialogueSaveStrategy.new("user://my_custom_path.dat")
DialogueManager.save_manager.set_save_strategy(custom_strategy)
```

## 注意事项

1. **策略切换**：可以在运行时切换存档策略，但建议在游戏初始化时设置。

2. **数据格式**：
   - **对话历史数据格式**：
     ```gdscript
     {
         "entries": [...],  # DialogueHistoryEntry 序列化后的数组
         "read_nodes": [...]  # 已读节点ID数组
     }
     ```
   - **任务状态数据格式**：
     ```gdscript
     {
         "active_quests": [...],  # 活跃任务序列化后的数组
         "completed_quest_ids": [...]  # 已完成任务ID数组
     }
     ```

3. **异步操作**：如果存档策略涉及异步操作（如网络请求），需要在策略内部处理，`save_dialogue_history()` 和 `load_dialogue_history()` 方法可以返回 `false` 表示失败，或使用信号通知完成。

4. **错误处理**：策略应该妥善处理错误情况，并返回适当的返回值。

## 与旧版本的区别

- **旧版本**：`SaveSystem` 是全局 Autoload 单例，负责整个游戏的存档
- **新版本**：`DialogueSaveManager` 是 `DialogueManager` 的属性单例，负责对话历史和任务状态的存档，使用策略模式支持扩展

这样的设计更加符合单一职责原则，对话系统只负责对话和任务相关的存档，游戏的其他存档由专门的存档模块处理。

## 任务状态存档说明

任务状态存档会保存：
- **活跃任务**：所有正在进行中的任务实例及其进度（包括任务目标的完成状态）
- **已完成任务**：已完成并已交付的任务ID列表

加载任务状态时，系统会：
1. 从任务数据库获取任务资源
2. 复制任务实例并恢复其状态（包括目标进度）
3. 重新初始化任务（连接信号）
4. 恢复到 `QuestManager.active_quests` 和 `completed_quest_ids`

**重要**：使用任务状态存档前，必须注册任务资源获取函数，否则无法加载任务。

