# dialogue_manager.gd
extends Node

# 用一个变量来存储解析后的对话数据
var dialogue_data: Dictionary = {}

# 游戏启动时，自动加载并解析JSON文件
func _ready():
	load_dialogue_file("res://dialogue.json")

# 加载并解析指定的JSON文件
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

# 对外提供一个开始对话的接口
func start_dialogue(node_id: String):
	# 检查请求的对话ID是否存在于我们的数据中
	if dialogue_data.has(node_id):
		print("Starting dialogue from node: ", node_id)
		var node_data = dialogue_data[node_id]
		var character = node_data.get("character", "旁白") # 使用.get()可以提供一个默认值，更安全
		var text = node_data.get("text", "...")
		
		# 现在，我们只是打印出来，下一课将把它显示在UI上
		print(character, ": ", text)
	else:
		print("Error: Dialogue node not found: ", node_id)
