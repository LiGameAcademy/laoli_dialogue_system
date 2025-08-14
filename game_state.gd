extends Node

# 1. 创建一个道具“数据库”，用ID作为Key
var item_database = {
	"sword_rust": { "name": "生锈的剑" },
	"bread": { "name": "面包" },
	"badge_of_courage": { "name": "勇气徽章" }
}

# 2. 玩家的背包现在存储的是道具ID，而不是名称
#var inventory = ["sword_rust", "bread"]
var inventory = ["sword_rust", "bread", "badge_of_courage"]
var completed_quests = ["新手村报道"]

func _ready() -> void:
	# 连接信号的代码保持不变
	# DialogueManager.action_triggered.connect(_on_action_triggered)
	pass

# 3. has_item和add_item现在都使用ID
func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func add_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)

# 4. 用于通过ID获取道具的显示名称
func get_item_name(item_id: String) -> String:
	if item_database.has(item_id):
		# 在这里，我们可以为未来的本地化做准备，直接使用tr()
		return tr(item_database[item_id]["name"])
	return "[物品ID不存在]"

## 处理给于道具动作
func handle_give_item_action(action_data: Dictionary) -> void:
	var item_id = action_data.get("id", "")
	if not item_id.is_empty():
		add_item(item_id)
		var item_name = get_item_name(item_id)
		print("[GameState] Player received item: %s (ID: %s)" % [item_name, item_id])

## 处理奖励动作
func handle_give_reward_action(action_data: Dictionary) -> void:
	var reward_id = action_data.get("id", "")
	if reward_id == "QUEST_1_REWARD":
		add_item("gold_coin_pouch")
		add_item("letter_of_recommendation")
		print("[GameState] Player received rewards for: ", reward_id)

# 未来可以扩展更多接口
# func has_completed_quest(quest_id: String) -> bool: ...

## 处理接收到的结构化动作事件
# func _on_action_triggered(action_data: Dictionary) -> void:
# 	# 检查传入的是否是字典，保证代码健壮性
# 	if not action_data is Dictionary or not action_data.has("type"):
# 		return

# 	print("[GameState] Received action: ", action_data) # 打印日志，方便调试
	
# 	# 使用match语句，根据动作类型来分发逻辑
# 	match action_data["type"]:
# 		"give_item":
# 			var item_id = action_data.get("id", "")
# 			var amount = action_data.get("amount", 1) # 获取数量，默认为1
# 			if not item_id.is_empty():
# 				add_item(item_id) # add_item现在也只接收ID
# 				var item_name = get_item_name(item_id)
# 				print("[GameState] Player received %d x %s (ID: %s)" % [amount, item_name, item_id])
		
# 		"give_reward":
# 			var reward_id = action_data.get("id", "")
# 			if reward_id == "QUEST_1_REWARD":
# 				add_item("gold_coin_pouch") # 给予ID为gold_coin_pouch的物品
# 				add_item("letter_of_recommendation")
# 				print("[GameState] Player received rewards for: ", reward_id)
		
# 		"play_sound":
# 			# 未来可以轻松扩展，比如让AudioManager来处理
# 			var sound_id = action_data.get("id", "")
# 			print("[GameState] Action 'play_sound' triggered for sound: ", sound_id)
