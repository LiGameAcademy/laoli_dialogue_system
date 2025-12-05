extends Node

# 【重构】从Dictionary改为Resource图
var dialogue_graph: Dictionary[String, DialogueNode] = {}
var loaded_files: Array[String] = []  # 已加载的文件列表（避免重复加载）
var current_node: DialogueNode = null  # 当前对话节点
var is_active: bool = false 			## 标记对话系统是否正在运行

var action_factory: ActionFactory = ActionFactory.new()
var condition_factory: ConditionFactory = ConditionFactory.new()
var dialogue_parser: DialogueParser = DialogueParser.new(action_factory, condition_factory)

## 玩家节点获取函数（由业务层注册，用于解耦）
var player_getter: Callable

## 对话存档管理器（属性单例）
var save_manager: DialogueSaveManager = DialogueSaveManager.new()

signal text_updated(character_name: String, text: String)		## 文本更新信号
signal dialogue_started											## 对话开始信号
signal dialogue_finished										## 对话结束信号
signal choices_updated(choices: Array)							## 选项更新信号

## 注册玩家节点获取函数（由业务层调用）
## [param getter] 获取函数，返回 Node 或 null
func register_player_getter(getter: Callable) -> void:
	player_getter = getter

## 注册任务资源获取函数（由业务层调用，用于存档系统）
## [param getter] 获取函数，接收 quest_id: String，返回 Quest 资源
func register_quest_resource_getter_for_save(getter: Callable) -> void:
	save_manager.register_quest_resource_getter(getter)

## 加载并解析指定的JSON文件
## [param path] JSON文件的路径
## [param merge] 是否合并到现有对话图（默认true，false会替换）
func load_dialogue_file(path: String, merge: bool = true) -> void:
	# 检查是否已加载
	if loaded_files.has(path):
		push_warning("DialogueManager: 文件已加载 '%s'，跳过" % path)
		return
	
	var dialogues: Dictionary = dialogue_parser.parse_dialogue_file(path)
	
	if dialogues.is_empty():
		push_error("DialogueManager: 对话文件加载失败 '%s'" % path)
		return
	
	if merge:
		# 合并到现有对话图（如果节点ID重复，会覆盖）
		dialogue_graph.merge(dialogues, true)
	else:
		# 替换现有对话图
		dialogue_graph = dialogues
		loaded_files.clear()
	
	loaded_files.append(path)
	print("DialogueManager: 对话文件加载成功 '%s'，共 %d 个节点（总计 %d 个节点）" % [path, dialogues.size(), dialogue_graph.size()])

## 卸载指定的对话文件
## [param path] JSON文件的路径
func unload_dialogue_file(path: String) -> void:
	if not loaded_files.has(path):
		push_warning("DialogueManager: 文件未加载 '%s'" % path)
		return
	
	# 重新加载文件以获取节点ID列表
	var temp_dialogues = dialogue_parser.parse_dialogue_file(path)
	
	# 从对话图中移除这些节点
	for node_id in temp_dialogues:
		if dialogue_graph.has(node_id):
			dialogue_graph.erase(node_id)
	
	loaded_files.erase(path)
	print("DialogueManager: 对话文件已卸载 '%s'，剩余 %d 个节点" % [path, dialogue_graph.size()])

## 清空所有对话数据
func clear_all_dialogues() -> void:
	dialogue_graph.clear()
	loaded_files.clear()
	print("DialogueManager: 所有对话数据已清空")

## 重新加载所有文件
func reload_all_files() -> void:
	var files_to_reload = loaded_files.duplicate()
	clear_all_dialogues()
	
	for file_path in files_to_reload:
		load_dialogue_file(file_path, true)

## 按需加载对话文件（如果节点不存在）
## [param node_id] 对话节点ID
## [param search_paths] 要搜索的文件路径列表（可选）
## [return] 是否成功加载
func load_dialogue_if_needed(node_id: String, search_paths: Array[String] = []) -> bool:
	# 如果节点已存在，不需要加载
	if dialogue_graph.has(node_id):
		return true
	
	# 如果没有提供搜索路径，使用默认路径
	if search_paths.is_empty():
		search_paths = [
			"res://data/dialogues/main_dialogue.json",
			"res://data/dialogues/village_dialogue.json",
			"res://data/dialogues/forest_dialogue.json",
		]
	
	# 尝试从文件加载
	for file_path in search_paths:
		if ResourceLoader.exists(file_path):
			load_dialogue_file(file_path, true)
			if dialogue_graph.has(node_id):
				return true
	
	return false

## 提供公开的注册函数（“插座”），让外部系统可以把“检查器”“插”进来
func register_condition(condition_type: String, condition: GameCondition) -> void:
	condition_factory.register_condition(condition_type, condition)

## 提供公开的注册函数（“插座”），让外部系统可以把“动作处理器”“插”进来
func register_action(action_type: String, action: GameAction) -> void:
	action_factory.register_action(action_type, action)

## 对外提供一个开始对话的接口
## [param node_id] 当前需要处理的节点ID
func start_dialogue(node_id: String) -> void:
	if is_active:
		return

	if not dialogue_graph.has(node_id):
		push_error("DialogueManager: 对话节点不存在 '%s'" % node_id)
		_end_dialogue()
		return

	is_active = true # 标记对话开始
	dialogue_started.emit()
	process_node(node_id)

## 处理单个对话节点
## [param node_id] 当前需要处理的节点ID
func process_node(node_id: String) -> void:
	if node_id == "END":
		_end_dialogue()
		return

	if not dialogue_graph.has(node_id):
		push_error("DialogueManager: 节点不存在 '%s'" % node_id)
		_end_dialogue()
		return

	current_node = dialogue_graph[node_id]

	# 获取本地化文本
	var character_name = current_node.get_character_name()
	var text = current_node.get_text()
	
	# 记录对话历史
	DialogueHistoryManager.add_entry(
		node_id,
		character_name,
		text,
		_get_choices_texts(current_node)
	)
	
	# 发出文本更新信号
	text_updated.emit(character_name, text)
	
	# 执行节点动作
	# 使用注册的玩家获取函数，避免硬编码节点查找
	var player = _get_player_node()
	_execute_actions(current_node.actions, player)
	
	# 处理选项或下一节点
	if current_node.has_choices():
		# 获取可用的选项（过滤条件不满足的）
		var available_options = current_node.get_available_options(player)
		
		# 格式化选项数据（保持与UI的兼容性）
		var formatted_choices = []
		for option in available_options:
			var choice_data = {
				"text": option.get_display_text(null),
				"next_node": option.next_node_id,
				"option_resource": option  # 保存Resource引用，方便后续使用
			}
			formatted_choices.append(choice_data)
		
		choices_updated.emit(formatted_choices)
	elif not current_node.next_node_id.is_empty():
		# 单线对话，等待UI继续（不自动跳转）
		pass
	else:
		_end_dialogue()

## 供UI调用，告诉我们玩家做了哪个选择
## [param choice_data] 玩家选择的选项数据
func make_choice(choice_data: Dictionary) -> void:
	# 记录选择的选项
	if current_node:
		var choice_text = choice_data.get("text", "")
		DialogueHistoryManager.record_choice(current_node.node_id, choice_text)
	
	# 如果choice_data包含option_resource，使用它
	if choice_data.has("option_resource"):
		var option: DialogueOption = choice_data["option_resource"]
		
		# 执行选项动作
		_execute_actions(option.actions, null)
		
		# 跳转到下一节点
		if not option.next_node_id.is_empty():
			process_node(option.next_node_id)
		else:
			_end_dialogue()
	else:
		# 兼容旧格式
		if choice_data.has("next_node"):
			process_node(choice_data["next_node"])
		else:
			_end_dialogue()

# 【新增】执行动作列表的辅助方法
func _execute_actions(actions: Array[GameAction], activator: Node) -> void:
	for action in actions:
		if action:
			# GameAction的execute需要initiator和target
			# 对话系统中，initiator通常是Player，target是null
			action.execute(activator, null)
			
			# 为了兼容旧系统，仍然发出action_triggered信号
			# 但我们可以从Resource中提取信息（如果需要）
			# 这里暂时跳过，因为新系统直接执行GameAction

## 获取玩家节点（使用注册的获取函数，避免硬编码）
## [return] 玩家节点或 null
func _get_player_node() -> Node:
	if player_getter.is_valid():
		return player_getter.call()
	else:
		# 如果没有注册获取函数，回退到默认方式（向后兼容）
		push_warning("DialogueManager: 未注册玩家获取函数，使用默认方式查找")
		return get_tree().get_first_node_in_group("Player")

## 获取选项文本列表
## [param node] 对话节点
## [return] 选项文本数组
func _get_choices_texts(node: DialogueNode) -> Array[String]:
	var texts: Array[String] = []
	if node.has_choices():
		var player = _get_player_node()
		var available_options = node.get_available_options(player)
		for option in available_options:
			texts.append(option.get_text())
	return texts

## 处理对话结束
func _end_dialogue() -> void:
	is_active = false # 标记对话结束
	current_node = null
	print("Dialogue Ended.")
	dialogue_finished.emit()
