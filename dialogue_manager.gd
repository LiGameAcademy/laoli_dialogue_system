# dialogue_manager.gd
extends Node

## 用一个变量来存储解析后的对话数据
var dialogue_data: Dictionary = {}

## 当有新的对话内容需要显示时，发出此信号
signal text_updated(character_name, text)
## 当对话流程结束时，发出此信号
signal dialogue_finished

## 游戏启动时，自动加载并解析JSON文件
func _ready():
	load_dialogue_file("res://dialogue.json")

## 加载并解析指定的JSON文件
func load_dialogue_file(path: String):
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
func start_dialogue(node_id: String):
	if dialogue_data.has(node_id):
		# 为了后续扩展，我们用一个变量来追踪当前节点
		_process_node(node_id)
	else:
		print("Error: Dialogue node not found: ", node_id)
		_end_dialogue() # 如果ID无效，也应该结束对话流程
		
## 处理单个对话节点
func _process_node(node_id: String):
	if node_id == "END":
		_end_dialogue()
		return

	var node_data = dialogue_data[node_id]
	var character = node_data.get("character", "旁白")
	var text = node_data.get("text", "...")
	
	# 这就是关键！不再是print，而是发出信号！
	emit_signal("text_updated", character, text)
	
	# 暂时先处理单线对话的情况
	if node_data.has("next_node"):
		# 这里我们先不处理，下一课会让它变得更完善
		pass
	# else:
		# 如果没有choices也没有next_node，对话就卡在这里了，等待UI的下一步指令
		# pass

## 处理对话结束
func _end_dialogue():
	print("Dialogue Ended.")
	emit_signal("dialogue_finished")
