# dialogue_manager.gd
extends Node

## 用一个变量来存储解析后的对话数据
var dialogue_data: Dictionary = {}
var current_node_id: String = "" 	## 追踪当前对话节点的ID
var is_active: bool = false 		## 标记对话系统是否正在运行

## 当有新的对话内容需要显示时，发出此信号
## [param character_name] 对话角色名称
## [param text] 对话文本
signal text_updated(character_name: String, text: String)
## 当对话流程结束时，发出此信号
signal dialogue_finished
## 当需要向玩家展示选项时，发出此信号
## [param choices] 选项数组
signal choices_updated(choices: Array)

## 游戏启动时，自动加载并解析JSON文件
func _ready() -> void:
	load_dialogue_file("res://dialogue.json")

## 加载并解析指定的JSON文件
## [param path] JSON文件的路径
func load_dialogue_file(path: String) -> void:
	# 使用FileAccess安全地打开文件
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Error: Failed to open dialogue file at path: ", path)
		return

	# 读取文件全部内容
	var content = file.get_as_text()
	# 使用JSON类来解析文本内容
	var parse_result = JSON.parse_string(content)
	
	# 解析失败会返回null，需要检查
	if parse_result:
		dialogue_data = parse_result
		print("Dialogue file loaded and parsed successfully!")
		# 打印出来看看，确认数据正确
		# print(dialogue_data)
	else:
		print("Error: Failed to parse JSON file. Check for syntax errors in: ", path)

## 对外提供一个开始对话的接口
## [param node_id] 当前需要处理的节点ID
func start_dialogue(node_id: String) -> void:
	if is_active:
		return
	is_active = true # 标记对话开始
	if dialogue_data.has(node_id):
		process_node(node_id)
	else:
		print("Error: Dialogue node not found: ", node_id)
		_end_dialogue()

## 供UI调用，告诉我们玩家做了哪个选择
## [param choice_data] 玩家选择的选项数据
func make_choice(choice_data: Dictionary) -> void:
	if choice_data.has("next_node"):
		# 根据玩家的选择，处理下一个节点
		process_node(choice_data["next_node"])
	else:
		# 如果选择数据有问题，直接结束对话
		_end_dialogue()

## 处理单个对话节点
## [param node_id] 当前需要处理的节点ID
func process_node(node_id: String) -> void:
	current_node_id = node_id # 更新当前节点ID

	if node_id == "END":
		_end_dialogue()
		return

	var node_data = dialogue_data[node_id]
	var character = node_data.get("character", "旁白")
	var text = node_data.get("text", "...")
	
	text_updated.emit(character, text)
	
	# 核心改动：检查是否存在选项
	if node_data.has("choices"):
		var available_choices = [] # 创建一个空数组来存放可用选项
		for choice in node_data["choices"]:
			# 检查每个选项的条件
			if _check_condition(choice.get("condition", {})):
				available_choices.append(choice) # 条件满足，才加入可用列表
		
		# 在发出信号前，处理文本的动态生成
		var localized_choices = []
		for choice in available_choices:
			var localized_choice = choice.duplicate() # 复制一份，避免修改原始数据
			var final_text = tr(choice["text"]) # 先获取基础文本

			# 新增逻辑：检查是否需要添加条件前缀
			if choice.get("display_condition_prefix", false) and choice.has("condition"):
				var condition = choice["condition"]
				# 目前只处理has_item, 未来可扩展
				if condition.has("has_item"):
					var item_id = condition["has_item"]
					# 通过ID从GameState获取道具显示名称
					var item_name = GameState.get_item_name(item_id)
					# 格式化字符串，动态生成最终的显示文本
					final_text = "(需要【%s】) %s" % [item_name, final_text]
					
			localized_choice["text"] = final_text
			localized_choices.append(localized_choice)
		emit_signal("choices_updated", localized_choices)
	elif node_data.has("next_node"):
		# 如果是单线对话，我们暂时先不自动跳转
		# 等待玩家按键继续，这个逻辑我们放在UI层处理
		pass
	else:
		# 如果既没有选项也没有下一句，就结束对话
		_end_dialogue()

## 检查条件是否满足
func _check_condition(condition_data: Dictionary) -> bool:
	if condition_data.is_empty():
		# 没有condition字段，默认显示
		return true
	
	# 检查 "has_item" 条件
	if condition_data.has("has_item"):
		# 去询问GameState，现在传递的是ID
		if not GameState.has_item(condition_data["has_item"]):
			return false # 如果GameState说没有，条件不满足
	
	# 检查 "has_completed_quest" 条件 (未来扩展)
	# if condition_data.has("quest_completed"):
	#	  if not GameState.has_completed_quest(condition_data["quest_completed"]):
	#		  return false

	# 所有条件都检查通过了，才返回true
	return true

## 处理对话结束
func _end_dialogue() -> void:
	is_active = false # 标记对话结束
	current_node_id = ""
	print("Dialogue Ended.")
	dialogue_finished.emit()
