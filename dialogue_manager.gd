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
		_process_node(node_id)
	else:
		print("Error: Dialogue node not found: ", node_id)
		_end_dialogue()

## 供UI调用，告诉我们玩家做了哪个选择
## [param choice_data] 玩家选择的选项数据
func make_choice(choice_data: Dictionary) -> void:
	if choice_data.has("next_node"):
		# 根据玩家的选择，处理下一个节点
		_process_node(choice_data["next_node"])
	else:
		# 如果选择数据有问题，直接结束对话
		_end_dialogue()

## 处理单个对话节点
## [param node_id] 当前需要处理的节点ID
func _process_node(node_id: String) -> void:
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
		# 如果有，就发出 choices_updated 信号
		choices_updated.emit(node_data["choices"])
	elif node_data.has("next_node"):
		# 如果是单线对话，我们暂时先不自动跳转
		# 等待玩家按键继续，这个逻辑我们放在UI层处理
		pass
	else:
		# 如果既没有选项也没有下一句，就结束对话
		_end_dialogue()

## 处理对话结束
func _end_dialogue() -> void:
	is_active = false # 标记对话结束
	current_node_id = ""
	print("Dialogue Ended.")
	dialogue_finished.emit()
