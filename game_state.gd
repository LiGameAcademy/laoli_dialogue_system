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

# 3. has_item和add_item现在都使用ID
func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func add_item(item_id: String):
	if not inventory.has(item_id):
		inventory.append(item_id)

# 4. 用于通过ID获取道具的显示名称
func get_item_name(item_id: String) -> String:
	if item_database.has(item_id):
		# 在这里，我们可以为未来的本地化做准备，直接使用tr()
		return tr(item_database[item_id]["name"])
	return "[物品ID不存在]"

# 未来可以扩展更多接口
# func has_completed_quest(quest_id: String) -> bool: ...
