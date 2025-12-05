extends ConditionalVariableResolver
class_name ItemResolver

## 解析物品相关的条件变量（如 {has_item:sword}）
func resolve(condition_type: String, value: String) -> Variant:
	if condition_type != "has_item":
		return null
	
	# 检查是否拥有物品
	var player = Engine.get_main_loop().get_first_node_in_group("Player")
	if not player:
		push_warning("ItemResolver: 未找到 Player 节点（不在 'Player' 组中）")
		return "否"
	
	if not player.has_method("get_inventory"):
		push_warning("ItemResolver: Player 节点没有 get_inventory() 方法")
		return "否"
	
	var inventory = player.get_inventory()
	if not inventory:
		push_warning("ItemResolver: Player.get_inventory() 返回 null")
		return "否"
	
	if not inventory.has_method("get_item_count_by_name"):
		push_warning("ItemResolver: Inventory 没有 get_item_count_by_name() 方法")
		return "否"
	
	var count = inventory.get_item_count_by_name(value)
	return "是" if count > 0 else "否"
