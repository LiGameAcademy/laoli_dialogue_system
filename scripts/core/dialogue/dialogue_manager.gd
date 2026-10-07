extends Node

enum DialogueEndReason { COMPLETED, CANCELED, FAILED }
signal dialogue_session_started(session_id: int)
signal dialogue_session_finished(session_id: int, reason: DialogueEndReason)
var _session_id: int = -1
var _next_session_id: int = 0
var _initiator: Node


const CLEANUP_INTERVAL = 60.0  # 每60秒清理一次

# 【重构】从Dictionary改为Resource图
var dialogue_graph: Dictionary[String, DialogueNode] = {}
var loaded_files: Array[String] = []  # 已加载的文件列表（避免重复加载）
var dialogue_file_cache: Dictionary[String, Dictionary] = {}  # 对话文件缓存（Key: 文件路径, Value: 节点字典）
var current_node: DialogueNode = null  # 当前对话节点
var is_active: bool = false 			## 标记对话系统是否正在运行

## 内存管理相关
var cleanup_timer: float = 0.0

var action_factory: ActionFactory = ActionFactory.new()
var condition_factory: ConditionFactory = ConditionFactory.new()
var dialogue_parser: DialogueParser = DialogueParser.new(action_factory, condition_factory)

## 玩家节点获取函数（由业务层注册，用于解耦）
var player_getter: Callable

## 对话存档管理器（属性单例）
var save_manager: DialogueSaveManager = DialogueSaveManager.new()

## 性能分析器（属性，不污染全局命名空间）
var performance_profiler: PerformanceProfiler = PerformanceProfiler.new()

signal text_updated(character_name: String, text: String)		## 文本更新信号
signal dialogue_started											## 对话开始信号
signal dialogue_finished										## 对话结束信号
signal choices_updated(choices: Array)							## 选项更新信号

func _ready() -> void:
	add_child(performance_profiler)

## 定期清理未使用的节点（内存管理）
func _process(delta: float) -> void:
	if is_active:
		return
	cleanup_timer += delta
	if cleanup_timer >= CLEANUP_INTERVAL:
		release_unused_nodes()
		cleanup_timer = 0.0

## 注册玩家节点获取函数（由业务层调用）
## [param getter] 获取函数，返回 Node 或 null
func register_player_getter(getter: Callable) -> void:
	player_getter = getter

## 注册任务资源获取函数（由业务层调用，用于存档系统）
## [param getter] 获取函数，接收 quest_id: String，返回 Quest 资源
func register_quest_resource_getter_for_save(getter: Callable) -> void:
	save_manager.register_quest_resource_getter(getter)

## 加载并解析指定的JSON文件（带缓存）
## [param path] JSON文件的路径
## [param merge] 是否合并到现有对话图（默认true，false会替换）
func load_dialogue_file(path: String, merge: bool = true) -> void:
	# 性能分析
	performance_profiler.start_profiling("load_dialogue_file")
	
	# 检查缓存
	if dialogue_file_cache.has(path):
		var cached_dialogues: Dictionary = dialogue_file_cache[path]
		if merge:
			dialogue_graph.merge(cached_dialogues, true)
		else:
			dialogue_graph.assign(cached_dialogues)
			loaded_files.clear()
		
		if not loaded_files.has(path):
			loaded_files.append(path)
		
		print("DialogueManager: 从缓存加载对话文件 '%s'，共 %d 个节点" % [path, cached_dialogues.size()])
		
		# 结束性能分析
		performance_profiler.end_profiling("load_dialogue_file")
		return
	
	# 检查是否已加载（但不在缓存中，可能是之前加载过但缓存被清空）
	if loaded_files.has(path):
		push_warning("DialogueManager: 文件已加载 '%s'，但缓存不存在，重新加载" % path)
	
	# 解析文件
	var dialogues: Dictionary = dialogue_parser.parse_dialogue_file(path)
	
	if dialogues.is_empty():
		push_error("DialogueManager: 对话文件加载失败 '%s'" % path)
		return
	
	# 添加到缓存
	dialogue_file_cache[path] = dialogues
	
	if merge:
		# 合并到现有对话图（如果节点ID重复，会覆盖）
		dialogue_graph.merge(dialogues, true)
	else:
		# 替换现有对话图
		dialogue_graph.assign(dialogues)
		loaded_files.clear()
	
	if not loaded_files.has(path):
		loaded_files.append(path)
	
	print("DialogueManager: 对话文件加载成功 '%s'，共 %d 个节点（总计 %d 个节点）" % [path, dialogues.size(), dialogue_graph.size()])
	
	# 结束性能分析
	performance_profiler.end_profiling("load_dialogue_file")

## 卸载指定的对话文件
## [param path] JSON文件的路径
func unload_dialogue_file(path: String) -> void:
	if not loaded_files.has(path):
		push_warning("DialogueManager: 文件未加载 '%s'" % path)
		return
	
	# 从缓存中获取节点ID列表（如果缓存存在）
	var node_ids_to_remove: Array[String] = []
	if dialogue_file_cache.has(path):
		for node_id: String in dialogue_file_cache[path]:
			node_ids_to_remove.append(node_id)
	else:
		# 如果缓存不存在，重新加载文件以获取节点ID列表
		var temp_dialogues: Dictionary = dialogue_parser.parse_dialogue_file(path)
		for node_id: String in temp_dialogues:
			node_ids_to_remove.append(node_id)
	
	# 从对话图中移除这些节点
	for node_id: String in node_ids_to_remove:
		if dialogue_graph.has(node_id):
			dialogue_graph.erase(node_id)
	
	# 从缓存中移除
	dialogue_file_cache.erase(path)
	loaded_files.erase(path)
	print("DialogueManager: 对话文件已卸载 '%s'，剩余 %d 个节点" % [path, dialogue_graph.size()])

## 清空所有对话数据
func clear_all_dialogues() -> void:
	_end_dialogue(DialogueEndReason.CANCELED)
	dialogue_graph.clear()
	loaded_files.clear()
	dialogue_file_cache.clear()
	print("DialogueManager: 所有对话数据已清空")

## 重新加载所有文件
func reload_all_files() -> void:
	var files_to_reload: Array[String] = loaded_files.duplicate()
	clear_all_dialogues()
	
	for file_path: String in files_to_reload:
		load_dialogue_file(file_path, true)

## 按需加载对话文件（如果节点不存在）
## [param node_id] 对话节点ID
## [param search_paths] 要搜索的文件路径列表（可选）
## [return] 是否成功加载
func load_dialogue_if_needed(node_id: String, search_paths: Array[String] = []) -> bool:
	# 如果节点已存在，不需要加载
	if dialogue_graph.has(node_id):
		return true
	
	# 先尝试从缓存中查找
	for file_path: String in dialogue_file_cache:
		var cached_dialogues: Dictionary = dialogue_file_cache[file_path]
		if cached_dialogues.has(node_id):
			# 从缓存中恢复节点
			dialogue_graph[node_id] = cached_dialogues[node_id]
			if not loaded_files.has(file_path):
				loaded_files.append(file_path)
			return true
	
	# 如果没有提供搜索路径，使用默认路径
	if search_paths.is_empty():
		search_paths = [
			"res://data/dialogues/main_dialogue.json",
			"res://data/dialogues/village_dialogue.json",
			"res://data/dialogues/forest_dialogue.json",
		]
	
	# 尝试从文件加载
	for file_path: String in search_paths:
		if ResourceLoader.exists(file_path):
			load_dialogue_file(file_path, true)
			if dialogue_graph.has(node_id):
				return true
	
	return false

## 异步加载对话文件（延迟到下一帧执行）
## [param path] 文件路径
## [param merge] 是否合并
func load_dialogue_file_async(path: String, merge: bool = true) -> void:
	call_deferred("load_dialogue_file", path, merge)

## 后台预加载对话文件
## [param paths] 文件路径数组
func preload_dialogue_files_async(paths: Array[String]) -> void:
	for path: String in paths:
		call_deferred("load_dialogue_file", path, true)

## 释放未使用的对话节点（内存管理）
## [param keep_recent] 保留最近使用的节点数量（默认50）
func release_unused_nodes(keep_recent: int = 50) -> void:
	if dialogue_graph.size() <= keep_recent:
		return
	
	# 收集要保留的节点ID
	var nodes_to_keep: Array[String] = []
	
	# 保留当前节点及其相关节点
	if current_node:
		nodes_to_keep.append(current_node.node_id)
		# 保留选项指向的节点
		for option: DialogueOption in current_node.options:
			if not option.next_node_id.is_empty() and option.next_node_id != "END":
				nodes_to_keep.append(option.next_node_id)
	
	# 如果保留的节点数量不足，从缓存中随机选择一些
	if nodes_to_keep.size() < keep_recent:
		var all_node_ids: Array[String] = []
		all_node_ids.assign(dialogue_graph.keys())
		var remaining: int = keep_recent - nodes_to_keep.size()
		for i: int in range(min(remaining, all_node_ids.size())):
			var random_id: String = all_node_ids[randi() % all_node_ids.size()]
			if not nodes_to_keep.has(random_id):
				nodes_to_keep.append(random_id)
	
	# 移除未使用的节点
	var nodes_to_remove: Array[String] = []
	for node_id: String in dialogue_graph:
		if not nodes_to_keep.has(node_id):
			nodes_to_remove.append(node_id)
	
	for node_id: String in nodes_to_remove:
		dialogue_graph.erase(node_id)
	
	if nodes_to_remove.size() > 0:
		print("DialogueManager: 已释放 %d 个未使用的对话节点，保留 %d 个节点" % [nodes_to_remove.size(), dialogue_graph.size()])

## 提供公开的注册函数（“插座”），让外部系统可以把“检查器”“插”进来
func register_condition(condition_type: String, condition: GameCondition) -> void:
	condition_factory.register_condition(condition_type, condition)

## 提供公开的注册函数（“插座”），让外部系统可以把“动作处理器”“插”进来
func register_action(action_type: String, action: GameAction) -> void:
	action_factory.register_action(action_type, action)

func set_initiator(initiator: Node) -> bool:
	if is_active and _initiator != initiator:
		return false
	_initiator = initiator
	return true

func clear_initiator(initiator: Node) -> void:
	if _initiator != initiator:
		return
	if is_active:
		_end_dialogue(DialogueEndReason.CANCELED)
	if _initiator == initiator:
		_initiator = null

## 对外提供一个开始对话的接口
## [param node_id] 当前需要处理的节点ID
func start_dialogue(node_id: String) -> void:
	if not dialogue_graph.has(node_id):
		push_error("DialogueManager: 对话节点不存在 '%s'" % node_id)
		return
	start_dialogue_session(node_id)

## 处理单个对话节点
## [param node_id] 当前需要处理的节点ID
func process_node(node_id: String) -> void:
	if not is_active:
		return
	if node_id == "END":
		_end_dialogue()
		return

	if not dialogue_graph.has(node_id):
		push_error("DialogueManager: 节点不存在 '%s'" % node_id)
		_end_dialogue(DialogueEndReason.FAILED)
		return

	current_node = dialogue_graph[node_id]
	var session_id: int = _session_id
	var character_name: String = current_node.get_character_name()
	var text: String = current_node.get_text()
	DialogueHistoryManager.add_entry(node_id, character_name, text, _get_choices_texts(current_node))
	if not is_active or session_id != _session_id:
		return

	# 发出文本更新信号
	text_updated.emit(character_name, text)
	if not is_active or session_id != _session_id:
		return
	
	# 执行节点动作
	var player: Node = _get_player_node()
	_execute_actions(current_node.actions, player)
	if not is_active or session_id != _session_id:
		return
	
	# 处理选项或下一节点
	if current_node.has_choices():
		# 获取可用的选项（过滤条件不满足的）
		var available_options: Array[DialogueOption] = current_node.get_available_options(player)
		
		# 格式化选项数据（保持与UI的兼容性）
		var formatted_choices: Array[Dictionary] = []
		for option: DialogueOption in available_options:
			var choice_data: Dictionary = {
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
	if not is_active:
		return
	var session_id: int = _session_id
	# 如果choice_data包含option_resource，使用它
	if choice_data.has("option_resource"):
		var candidate: Variant = choice_data["option_resource"]
		if not candidate is DialogueOption or current_node == null:
			return
		var option: DialogueOption = candidate as DialogueOption
		if not current_node.get_available_options(_get_player_node()).has(option):
			return
		
		DialogueHistoryManager.record_choice(current_node.node_id, String(choice_data.get("text", "")))
		if not is_active or session_id != _session_id:
			return
		# 执行选项动作
		_execute_actions(option.actions, _get_player_node())
		if not is_active or session_id != _session_id:
			return
		
		# 跳转到下一节点
		if not option.next_node_id.is_empty():
			process_node(option.next_node_id)
		else:
			_end_dialogue()
	else:
		# 兼容旧格式
		if current_node != null:
			DialogueHistoryManager.record_choice(current_node.node_id, String(choice_data.get("text", "")))
		if not is_active or session_id != _session_id:
			return
		if choice_data.has("next_node"):
			process_node(choice_data["next_node"])
		else:
			_end_dialogue()

# 【新增】执行动作列表的辅助方法
func _execute_actions(actions: Array[GameAction], activator: Node) -> void:
	var session_id: int = _session_id
	for action: GameAction in actions:
		if not is_active or session_id != _session_id:
			return
		if action:
			# GameAction的execute需要initiator和target
			# 对话系统中，initiator通常是Player，target是null
			action.execute(activator, null)
			
			# 为了兼容旧系统，仍然发出action_triggered信号
			# 但我们可以从Resource中提取信息（如果需要）
			# 这里暂时跳过，因为新系统直接执行GameAction

## 处理对话结束
func _end_dialogue(reason: DialogueEndReason = DialogueEndReason.COMPLETED) -> void:
	if not is_active:
		return
	var ended_id: int = _session_id
	_session_id = -1
	is_active = false # 标记对话结束
	current_node = null
	print("Dialogue Ended.")
	dialogue_finished.emit()
	dialogue_session_finished.emit(ended_id, reason)

#region ========== 可关联对话会话 ==========

func start_dialogue_session(node_id: String) -> int:
	if is_active or not dialogue_graph.has(node_id):
		return -1
	_next_session_id += 1
	_session_id = _next_session_id
	is_active = true
	call_deferred("_begin_session", _session_id, node_id)
	return _session_id

func is_session_current(session_id: int) -> bool:
	return is_active and session_id == _session_id

func is_dialogue_active() -> bool:
	return is_active

func advance_dialogue_session(session_id: int) -> void:
	if session_id != _session_id or not is_active or current_node == null or current_node.has_choices():
		return
	process_node(current_node.next_node_id if not current_node.next_node_id.is_empty() else "END")

func cancel_dialogue_session(session_id: int) -> void:
	if session_id == _session_id and is_active:
		_end_dialogue(DialogueEndReason.CANCELED)

func make_session_choice(session_id: int, choice_data: Dictionary) -> void:
	if is_active and session_id == _session_id:
		make_choice(choice_data)

func _begin_session(session_id: int, node_id: String) -> void:
	if session_id != _session_id or not is_active:
		return
	dialogue_session_started.emit(session_id)
	if session_id != _session_id or not is_active:
		return
	dialogue_started.emit()
	if session_id == _session_id and is_active:
		process_node(node_id)
#endregion

func _get_player_node() -> Node:
	if is_instance_valid(_initiator):
		return _initiator
	if player_getter.is_valid():
		var candidate: Variant = player_getter.call()
		if candidate is Node and is_instance_valid(candidate):
			return candidate as Node
	return null

func _get_choices_texts(node: DialogueNode) -> Array[String]:
	var texts: Array[String] = []
	for option: DialogueOption in node.get_available_options(_get_player_node()):
		texts.append(option.get_text())
	return texts

func has_registered_action(action_type: String) -> bool:
	return action_factory.action_type_map.has(action_type)

func has_registered_condition(condition_type: String) -> bool:
	return condition_factory.condition_type_map.has(condition_type)

func _exit_tree() -> void:
	_end_dialogue(DialogueEndReason.CANCELED)
