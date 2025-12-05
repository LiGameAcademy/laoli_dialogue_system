extends RefCounted
class_name DialogueSaveManager

## 对话存档管理器
## 负责对话历史和任务状态的存档和读档，使用策略模式支持自定义存档策略

## 存档策略（默认使用 DefaultDialogueSaveStrategy）
var save_strategy: DialogueSaveStrategy = DefaultDialogueSaveStrategy.new()

## 任务资源获取函数（由业务层注册，用于加载任务）
var quest_resource_getter: Callable

## 设置存档策略
## [param strategy] 存档策略实例
func set_save_strategy(strategy: DialogueSaveStrategy) -> void:
	if not is_instance_valid(strategy):
		push_error("DialogueSaveManager: 存档策略无效")
		return
	save_strategy = strategy
	print("DialogueSaveManager: 已设置存档策略：%s" % strategy.get_class())

## 保存对话历史
## [return] 是否成功
func save_dialogue_history() -> bool:
	if not is_instance_valid(save_strategy):
		push_error("DialogueSaveManager: 存档策略未设置")
		return false
	
	# 准备对话历史数据
	var history_data = {
		"entries": [],
		"read_nodes": DialogueHistoryManager.get_read_nodes()
	}
	
	for entry in DialogueHistoryManager.history:
		history_data["entries"].append(entry.serialize())
	
	# 使用策略保存
	return save_strategy.save_dialogue_history(history_data)

## 加载对话历史
## [return] 是否成功
func load_dialogue_history() -> bool:
	if not is_instance_valid(save_strategy):
		push_error("DialogueSaveManager: 存档策略未设置")
		return false
	
	# 使用策略加载
	var history_data = save_strategy.load_dialogue_history()
	if history_data.is_empty():
		return false
	
	# 恢复对话历史
	DialogueHistoryManager.clear_history()
	
	var entries_data = history_data.get("entries", [])
	for entry_data in entries_data:
		var entry = DialogueHistoryEntry.new()
		entry.deserialize(entry_data)
		DialogueHistoryManager.history.append(entry)
	
	# 恢复已读节点（处理协变数组问题）
	var read_nodes_data = history_data.get("read_nodes", [])
	var read_nodes: Array[String] = []
	if read_nodes_data is Array:
		for item in read_nodes_data:
			if item is String:
				read_nodes.append(item)
	DialogueHistoryManager.set_read_nodes(read_nodes)
	
	print("对话历史已加载：%d 条记录" % DialogueHistoryManager.history.size())
	return true

## 注册任务资源获取函数（由业务层调用）
## [param getter] 获取函数，接收 quest_id: String，返回 Quest 资源
func register_quest_resource_getter(getter: Callable) -> void:
	quest_resource_getter = getter

## 保存任务状态
## [return] 是否成功
func save_quest_data() -> bool:
	if not is_instance_valid(save_strategy):
		push_error("DialogueSaveManager: 存档策略未设置")
		return false
	
	# 准备任务状态数据
	var quest_data = {
		"active_quests": _serialize_quests(QuestManager.active_quests),
		"completed_quest_ids": QuestManager.completed_quest_ids
	}
	
	# 使用策略保存
	return save_strategy.save_quest_data(quest_data)

## 加载任务状态
## [return] 是否成功
func load_quest_data() -> bool:
	if not is_instance_valid(save_strategy):
		push_error("DialogueSaveManager: 存档策略未设置")
		return false
	
	# 使用策略加载
	var quest_data = save_strategy.load_quest_data()
	if quest_data.is_empty():
		return false
	
	# 恢复任务状态
	_deserialize_quest_data(quest_data)
	
	print("任务状态已加载：%d 个活跃任务，%d 个已完成任务" % [QuestManager.active_quests.size(), QuestManager.completed_quest_ids.size()])
	return true

## 序列化任务列表
## [param quests] 任务列表
## [return] 序列化后的数据
func _serialize_quests(quests: Array[Quest]) -> Array:
	var result = []
	for quest in quests:
		result.append({
			"id": quest.id,
			"is_completed": quest.is_completed,
			"objectives": _serialize_objectives(quest.objectives)
		})
	return result

## 序列化目标列表
## [param objectives] 目标列表
## [return] 序列化后的数据
func _serialize_objectives(objectives: Array[QuestObjective]) -> Array:
	var result = []
	for obj in objectives:
		# QuestObjective 基类已经有 serialize() 方法
		result.append(obj.serialize())
	return result

## 反序列化任务数据
## [param data] 任务状态数据字典
func _deserialize_quest_data(data: Dictionary) -> void:
	# 清空现有任务
	QuestManager.active_quests.clear()
	QuestManager.completed_quest_ids.clear()
	
	# 恢复活跃任务
	var active_quests_data = data.get("active_quests", [])
	for quest_data in active_quests_data:
		var quest_id = quest_data.get("id", "")
		if quest_id.is_empty():
			continue
		
		if not quest_resource_getter.is_valid():
			push_warning("DialogueSaveManager: 未注册任务资源获取函数，无法加载任务 '%s'" % quest_id)
			continue
		
		var quest_res = quest_resource_getter.call(quest_id)
		if not is_instance_valid(quest_res):
			push_warning("DialogueSaveManager: 无法获取任务资源 '%s'" % quest_id)
			continue
		
		# 复制任务实例
		var quest_instance = quest_res.duplicate(true)
		
		# 恢复任务状态
		_deserialize_quest(quest_instance, quest_data)
		
		# 重新初始化任务（连接信号）
		quest_instance.start()
		quest_instance.quest_updated.connect(func() -> void: QuestManager.quest_updated.emit(quest_instance))
		quest_instance.quest_completed.connect(func(_id: String) -> void: QuestManager._on_quest_completed(quest_instance))
		
		QuestManager.active_quests.append(quest_instance)
	
	# 恢复已完成任务（处理协变数组问题）
	var completed_quest_ids_data = data.get("completed_quest_ids", [])
	QuestManager.completed_quest_ids.clear()
	if completed_quest_ids_data is Array:
		for item in completed_quest_ids_data:
			if item is String:
				QuestManager.completed_quest_ids.append(item)
	
	# 发出任务加载完成信号（UI层会监听此信号并自动更新）
	QuestManager.quests_loaded.emit()

## 反序列化单个任务
## [param quest] 任务实例
## [param data] 序列化数据
func _deserialize_quest(quest: Quest, data: Dictionary) -> void:
	quest.is_completed = data.get("is_completed", false)
	
	var objectives_data = data.get("objectives", [])
	for i in range(min(quest.objectives.size(), objectives_data.size())):
		var obj = quest.objectives[i]
		var obj_data = objectives_data[i]
		# QuestObjective 基类已经有 deserialize() 方法
		obj.deserialize(obj_data)

## 保存所有数据（对话历史 + 任务状态）
## [return] 是否成功
func save_all() -> bool:
	var success = true
	success = save_dialogue_history() and success
	success = save_quest_data() and success
	return success

## 加载所有数据（对话历史 + 任务状态）
## [return] 是否成功
func load_all() -> bool:
	var success = true
	success = load_dialogue_history() and success
	success = load_quest_data() and success
	return success
