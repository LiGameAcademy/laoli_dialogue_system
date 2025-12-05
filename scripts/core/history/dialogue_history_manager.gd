extends Node

## 对话历史管理器
## 负责记录和管理玩家看过的对话内容

## 对话历史列表
var history: Array[DialogueHistoryEntry] = []

## 已读节点集合（用于快速查找，使用 Dictionary 代替 HashSet）
var read_nodes: Dictionary[String, bool] = {}

## 对话历史更新信号
signal history_updated(entry: DialogueHistoryEntry)
signal node_marked_as_read(node_id: String)

## 添加对话历史条目
## [param node_id] 对话节点ID
## [param character_name] 角色名称
## [param dialogue_text] 对话文本
## [param choices] 对话选项（可选）
func add_entry(node_id: String, character_name: String, dialogue_text: String, choices: Array[String] = []) -> void:
	# 检查是否已存在（避免重复）
	var existing_entry = _find_entry_by_node_id(node_id)
	if existing_entry:
		# 更新已读状态
		existing_entry.is_read = true
		read_nodes[node_id] = true
		history_updated.emit(existing_entry)
		return
	
	# 创建新条目
	var entry = DialogueHistoryEntry.new()
	entry.node_id = node_id
	entry.character_name = character_name
	entry.dialogue_text = dialogue_text
	entry.timestamp = Time.get_ticks_msec() / 1000.0
	entry.is_read = true
	entry.choices = choices
	entry.selected_choice = ""
	
	# 添加到历史
	history.append(entry)
	read_nodes[node_id] = true
	
	# 发出信号
	history_updated.emit(entry)
	node_marked_as_read.emit(node_id)
	
	print("对话历史已添加：%s - %s" % [character_name, dialogue_text.substr(0, min(20, dialogue_text.length()))])

## 记录玩家选择的选项
## [param node_id] 对话节点ID
## [param choice_text] 选择的选项文本
func record_choice(node_id: String, choice_text: String) -> void:
	var entry = _find_entry_by_node_id(node_id)
	if entry:
		entry.selected_choice = choice_text
		history_updated.emit(entry)

## 检查节点是否已读
## [param node_id] 对话节点ID
## [return] 是否已读
func is_node_read(node_id: String) -> bool:
	return read_nodes.has(node_id)

## 标记节点为已读
## [param node_id] 对话节点ID
func mark_node_as_read(node_id: String) -> void:
	if not read_nodes.has(node_id):
		read_nodes[node_id] = true
		var entry = _find_entry_by_node_id(node_id)
		if entry:
			entry.is_read = true
			history_updated.emit(entry)
		node_marked_as_read.emit(node_id)

## 查找条目
## [param node_id] 对话节点ID
## [return] 对话历史条目，不存在返回null
func _find_entry_by_node_id(node_id: String) -> DialogueHistoryEntry:
	for entry in history:
		if entry.node_id == node_id:
			return entry
	return null

## 获取对话历史（按时间排序）
## [return] 对话历史列表
func get_history() -> Array[DialogueHistoryEntry]:
	return history.duplicate()

## 获取指定角色的对话历史
## [param character_name] 角色名称
## [return] 该角色的对话历史列表
func get_history_by_character(character_name: String) -> Array[DialogueHistoryEntry]:
	var result: Array[DialogueHistoryEntry] = []
	for entry in history:
		if entry.character_name == character_name:
			result.append(entry)
	return result

## 清空对话历史
func clear_history() -> void:
	history.clear()
	read_nodes.clear()
	print("对话历史已清空")

## 获取已读节点列表（用于存档）
## [return] 已读节点ID数组
func get_read_nodes() -> Array[String]:
	return read_nodes.keys()

## 设置已读节点列表（用于读档）
## [param node_ids] 已读节点ID数组
func set_read_nodes(node_ids: Array[String]) -> void:
	read_nodes.clear()
	for node_id in node_ids:
		read_nodes[node_id] = true

